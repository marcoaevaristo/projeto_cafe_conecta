// lib/screens/safra_screen.dart — previsão de safra. Produtor informa quanto espera colher;
// todos veem a oferta futura somada por safra, tipo, região e mês (sem nomes).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/app_state.dart';
import '../utils/erros.dart';
import '../utils/theme.dart';

const _meses = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
final _int = NumberFormat.decimalPattern('pt_BR');

List<String> _safrasFuturas() {
  final a = DateTime.now().year;
  return [for (var i = -1; i < 3; i++) '${a + i}/${a + i + 1}'];
}

class SafraScreen extends StatefulWidget {
  const SafraScreen({super.key});
  @override
  State<SafraScreen> createState() => _SafraScreenState();
}

class _SafraScreenState extends State<SafraScreen> {
  List<Map<String, dynamic>>? _minhas;
  List<Map<String, dynamic>>? _oferta;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final r = await Future.wait([ApiService.getMinhasPrevisoes(), ApiService.getOfertaFutura()]);
      if (mounted) setState(() { _minhas = r[0]; _oferta = r[1]; _erro = null; });
    } catch (e) {
      if (mounted) setState(() { _minhas = []; _oferta = []; _erro = mensagemDeErro(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final produtor = context.watch<AppState>().usuario?.tipo != 'comprador';
    return DefaultTabController(
      length: produtor ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Previsão de safra'),
          bottom: TabBar(
            labelColor: CafeColors.gold,
            unselectedLabelColor: CafeColors.cream,
            indicatorColor: CafeColors.gold,
            tabs: [const Tab(text: 'Oferta futura'), if (produtor) const Tab(text: 'Minhas previsões')],
          ),
        ),
        floatingActionButton: produtor
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final ok = await showModalBottomSheet<bool>(
                      context: context, isScrollControlled: true, builder: (_) => const _FormPrevisao());
                  if (ok == true) _carregar();
                },
                icon: const Icon(Icons.add),
                label: const Text('Nova previsão'),
              )
            : null,
        body: _minhas == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [_abaOferta(), if (produtor) _abaMinhas()]),
      ),
    );
  }

  Widget _centro(Widget filho) =>
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: filho));

  Widget _abaOferta() {
    final itens = _oferta ?? [];
    final porSafra = <String, List<Map<String, dynamic>>>{};
    for (final g in itens) {
      porSafra.putIfAbsent('${g['safra']}', () => []).add(g);
    }
    return RefreshIndicator(
      onRefresh: _carregar,
      child: _centro(ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), children: [
        Text(
          'Quanto os produtores do app esperam colher, somado por região e mês. '
          'Grupos com um só produtor não aparecem, para ninguém ser identificado.',
          style: GoogleFonts.dmSans(fontSize: 13, color: CafeColors.lightRoast, height: 1.4),
        ),
        const SizedBox(height: 12),
        if (_erro != null)
          Text(_erro!, textAlign: TextAlign.center)
        else if (itens.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Ainda não há previsões suficientes para mostrar.',
                textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: CafeColors.lightRoast)),
          )
        else
          for (final e in porSafra.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 12, 2, 6),
              child: Text('Safra ${e.key} · ${_int.format(e.value.fold<num>(0, (s, g) => s + (g['sacas'] as num)))} sacas',
                  style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
            ),
            for (final g in e.value)
              Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.agriculture_outlined, color: CafeColors.caramel),
                  title: Text('${g['tipo']} · ${g['regiao']}', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                  subtitle: Text('${g['mes_colheita'] != null ? 'Colheita em ${_meses[(g['mes_colheita'] as int) - 1]}' : 'Mês não informado'}'
                      ' · ${g['produtores']} produtores'),
                  trailing: Text('${_int.format(g['sacas'])} sc', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                ),
              ),
          ],
      ])),
    );
  }

  Widget _abaMinhas() {
    final itens = _minhas ?? [];
    return RefreshIndicator(
      onRefresh: _carregar,
      child: _centro(ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), children: [
        if (itens.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Informe quanto espera colher. Compradores passam a enxergar a oferta da sua região '
                'antes da colheita, e você recebe procura mais cedo.',
                textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: CafeColors.lightRoast)),
          ),
        for (final p in itens)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              title: Text('${p['tipo']} · safra ${p['safra']}', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
              subtitle: Text([
                '${_int.format(p['sacas_previstas'])} sacas',
                if (p['regiao'] != null) p['regiao'],
                if (p['mes_colheita'] != null) 'colheita em ${_meses[(p['mes_colheita'] as int) - 1]}',
              ].join(' · ')),
              trailing: IconButton(
                tooltip: 'Apagar',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  try {
                    await ApiService.apagarPrevisao(p['id']);
                    _carregar();
                  } catch (e) {
                    if (mounted) mostrarErro(context, e);
                  }
                },
              ),
            ),
          ),
      ])),
    );
  }
}

class _FormPrevisao extends StatefulWidget {
  const _FormPrevisao();
  @override
  State<_FormPrevisao> createState() => _FormPrevisaoState();
}

class _FormPrevisaoState extends State<_FormPrevisao> {
  String _tipo = 'Arábica';
  String? _regiao;
  late String _safra = _safrasFuturas()[1];
  int? _mes;
  final _sacas = TextEditingController();
  final _obs = TextEditingController();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().usuario;
    if (u?.regiao != null && regioesCafe.contains(u!.regiao)) _regiao = u.regiao;
  }

  @override
  void dispose() {
    _sacas.dispose();
    _obs.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final n = int.tryParse(_sacas.text.trim());
    if (n == null || n <= 0) {
      mostrarErro(context, 'Informe quantas sacas espera colher');
      return;
    }
    setState(() => _enviando = true);
    try {
      await ApiService.criarPrevisao({
        'tipo': _tipo, 'regiao': _regiao, 'safra': _safra, 'sacas_previstas': n,
        'mes_colheita': _mes, 'observacoes': _obs.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Nova previsão de safra',
              style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: tiposCafe.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _tipo = v ?? _tipo),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _safra,
                decoration: const InputDecoration(labelText: 'Safra'),
                items: _safrasFuturas().map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _safra = v ?? _safra),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _regiao,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Região'),
            items: regioesCafe.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setState(() => _regiao = v),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _sacas,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Sacas previstas'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _mes,
                decoration: const InputDecoration(labelText: 'Mês da colheita'),
                items: [for (var i = 1; i <= 12; i++) DropdownMenuItem(value: i, child: Text(_meses[i - 1]))],
                onChanged: (v) => setState(() => _mes = v),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          TextField(controller: _obs, decoration: const InputDecoration(labelText: 'Observações (opcional)')),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _enviando ? null : _salvar, child: Text(_enviando ? 'Salvando…' : 'Salvar previsão')),
        ]),
      ),
    );
  }
}
