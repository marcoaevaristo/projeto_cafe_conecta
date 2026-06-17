// lib/screens/novo_anuncio_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/cafe_model.dart';
import '../services/app_state.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import 'classificacao_ia_screen.dart';

class NovoAnuncioScreen extends StatefulWidget {
  const NovoAnuncioScreen({super.key});
  @override
  State<NovoAnuncioScreen> createState() => _NovoAnuncioScreenState();
}

class _NovoAnuncioScreenState extends State<NovoAnuncioScreen> {
  String? _tipo;
  String? _classificacao;
  String? _bebida;
  String? _peneira;
  String? _regiao;
  String? _safra;
  final _qtdCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _fazendaCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  bool _loading = false;
  String? _erro;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Anúncio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _secao('Dados do Café'),
            _drop('Tipo de Café', tiposCafe, _tipo,
                (v) => setState(() => _tipo = v)),
            _drop('Classificação', classificacoesCafe, _classificacao,
                (v) => setState(() => _classificacao = v)),
            _drop('Bebida', bebidasCafe, _bebida,
                (v) => setState(() => _bebida = v)),
            _drop('Peneira', peneirasDisponiveis, _peneira,
                (v) => setState(() => _peneira = v)),
            _campo(_qtdCtrl, 'Quantidade (sacas)', TextInputType.number),
            _campo(_precoCtrl, 'Preço por saca (R\$)',
                const TextInputType.numberWithOptions(decimal: true)),
            _secao('Localização'),
            _drop('Região', regioesCafe, _regiao,
                (v) => setState(() => _regiao = v)),
            _campo(_cidadeCtrl, 'Cidade', TextInputType.text),
            _campo(_fazendaCtrl, 'Fazenda / Propriedade', TextInputType.text),
            _secao('Safra'),
            _drop('Safra', ['2024/2025', '2023/2024', '2022/2023'], _safra,
                (v) => setState(() => _safra = v)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassificacaoIAScreen()));
                if (res != null && mounted) setState(() => _classificacao = res as String?);
              },
              icon: const Icon(Icons.smart_toy),
              label: const Text('Analisar com IA'),
            ),
            const SizedBox(height: 16),
            if (_erro != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CafeColors.redAlert.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: CafeColors.redAlert.withValues(alpha: 0.3)),
                ),
                child: Text(_erro!,
                    style: GoogleFonts.dmSans(color: CafeColors.redAlert)),
              ),
            ElevatedButton(
              onPressed: _loading ? null : _publicar,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Publicar Anúncio'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _secao(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 10),
        child: Text(t,
            style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CafeColors.darkRoast)),
      );

  Widget _drop(String label, List<String> items, String? value,
      void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(i)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label, TextInputType tipo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: tipo,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Future<void> _publicar() async {
    if (_tipo == null ||
        _classificacao == null ||
        _qtdCtrl.text.isEmpty ||
        _regiao == null ||
        _cidadeCtrl.text.isEmpty) {
      setState(() =>
          _erro = 'Preencha tipo, classificação, quantidade, região e cidade.');
      return;
    }
    setState(() {
      _loading = true;
      _erro = null;
    });

    final u = context.read<AppState>().usuario!;
    final cafe = CafeModel(
      usuarioId: u.id!,
      tipo: _tipo!,
      classificacao: _classificacao!,
      quantidade: int.tryParse(_qtdCtrl.text) ?? 0,
      bebida: _bebida,
      peneira: _peneira,
      safra: _safra,
      regiao: _regiao!,
      cidade: _cidadeCtrl.text.trim(),
      fazenda:
          _fazendaCtrl.text.trim().isEmpty ? null : _fazendaCtrl.text.trim(),
      precoSaca: double.tryParse(_precoCtrl.text.replaceAll(',', '.')),
    );

    await DatabaseService.inserirCafe(cafe);
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Anúncio publicado com sucesso!')),
    );
    Navigator.pop(context);
  }
}
