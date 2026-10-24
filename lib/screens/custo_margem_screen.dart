// lib/screens/custo_margem_screen.dart — custo de produção por saca e margem
// comparada com o preço dos seus lotes e a média do Índice Café Conecta.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cafe_model.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../services/cotacoes_service.dart';
import '../utils/erros.dart';
import '../utils/theme.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

double? _lerNumero(String t) {
  final v = t.trim();
  if (v.isEmpty) return null;
  return double.tryParse(v.contains(',') ? v.replaceAll('.', '').replaceAll(',', '.') : v);
}

class CustoMargemScreen extends StatefulWidget {
  const CustoMargemScreen({super.key});
  @override
  State<CustoMargemScreen> createState() => _CustoMargemScreenState();
}

class _CustoMargemScreenState extends State<CustoMargemScreen> {
  final _custo = TextEditingController();
  final _precoRef = TextEditingController();
  List<CafeModel> _meusLotes = [];
  List<Map<String, dynamic>> _indice = [];
  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _custo.dispose();
    _precoRef.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final u = context.read<AppState>().usuario;
    try {
      final custo = await ApiService.getCusto();
      if (custo != null) _custo.text = custo.toStringAsFixed(2).replaceAll('.', ',');
    } catch (_) {}
    try {
      if (u != null) _meusLotes = await ApiService.getCafes(usuarioId: u.id, status: 'ativo');
    } catch (_) {}
    try {
      final i = await CotacoesService.fetchIndice();
      _indice = (i['por_tipo'] as List? ?? []).cast<Map<String, dynamic>>();
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _salvar() async {
    final v = _lerNumero(_custo.text);
    setState(() => _salvando = true);
    try {
      await ApiService.setCusto(v);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(v == null ? 'Custo apagado' : 'Custo salvo: ${_brl.format(v)} por saca')));
      }
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final custo = _lerNumero(_custo.text);
    final entrada = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    return Scaffold(
      appBar: AppBar(title: const Text('Custo e margem')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  Text(
                    'Informe quanto custa produzir uma saca de 60 kg (insumos, mão de obra, colheita, '
                    'secagem, arrendamento, financiamento…). Só você vê esse número.',
                    style: GoogleFonts.dmSans(fontSize: 13, color: CafeColors.lightRoast, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _custo,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: entrada,
                        decoration: const InputDecoration(
                            labelText: 'Custo por saca', prefixText: r'R$ ', hintText: 'ex.: 1.250,00'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _salvando ? null : _salvar,
                      child: _salvando
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Salvar'),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  if (custo == null)
                    Text('Digite o custo para ver as margens.',
                        style: GoogleFonts.dmSans(color: CafeColors.lightRoast))
                  else ...[
                    _titulo('Pela média do mercado no app'),
                    if (_indice.isEmpty)
                      _vazio('Ainda não há lotes ativos suficientes para a média.')
                    else
                      for (final t in _indice)
                        _CartaoMargem(
                          titulo: '${t['tipo']} · média do Índice Café Conecta',
                          preco: (t['preco_medio'] as num).toDouble(),
                          custo: custo,
                        ),
                    _titulo('Pelos preços dos seus lotes'),
                    if (_meusLotes.isEmpty)
                      _vazio('Você não tem lotes ativos.')
                    else
                      for (final l in _meusLotes.where((l) => l.precoSaca != null))
                        _CartaoMargem(
                          titulo: '${l.tipo} ${l.classificacao}${l.fazenda != null ? ' · ${l.fazenda}' : ''}',
                          preco: l.precoSaca!,
                          custo: custo,
                          sacas: l.quantidade,
                        ),
                    _titulo('Simular outro preço'),
                    TextField(
                      controller: _precoRef,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: entrada,
                      decoration: const InputDecoration(
                          labelText: 'Preço por saca', prefixText: r'R$ ',
                          hintText: 'ex.: o valor convertido da bolsa em Cotações'),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_lerNumero(_precoRef.text) != null)
                      _CartaoMargem(titulo: 'Preço simulado', preco: _lerNumero(_precoRef.text)!, custo: custo),
                    const SizedBox(height: 8),
                    Text(
                      'Ponto de equilíbrio: ${_brl.format(custo)} por saca. Abaixo disso a venda não cobre o custo.',
                      style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast),
                    ),
                  ],
                ]),
              ),
            ),
    );
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
        child: Text(t,
            style: GoogleFonts.playfairDisplay(
                fontSize: 16, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
      );

  Widget _vazio(String t) =>
      Text(t, style: GoogleFonts.dmSans(fontSize: 13, color: CafeColors.lightRoast));
}

class _CartaoMargem extends StatelessWidget {
  final String titulo;
  final double preco, custo;
  final int? sacas;
  const _CartaoMargem({required this.titulo, required this.preco, required this.custo, this.sacas});

  @override
  Widget build(BuildContext context) {
    final margem = preco - custo;
    final pct = preco > 0 ? margem / preco * 100 : 0;
    final positiva = margem >= 0;
    final cor = positiva ? CafeColors.greenOk : CafeColors.redAlert;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('Preço ${_brl.format(preco)} · custo ${_brl.format(custo)}',
                  style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
              if (sacas != null && sacas! > 0)
                Text('${positiva ? 'Lucro' : 'Prejuízo'} no lote (${sacas} sacas): ${_brl.format(margem * sacas!)}',
                    style: GoogleFonts.dmSans(fontSize: 12, color: cor)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${positiva ? '+' : ''}${_brl.format(margem)}',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: cor)),
            Text('${pct.toStringAsFixed(1).replaceAll('.', ',')}% da venda',
                style: GoogleFonts.dmSans(fontSize: 11, color: cor)),
          ]),
        ]),
      ),
    );
  }
}
