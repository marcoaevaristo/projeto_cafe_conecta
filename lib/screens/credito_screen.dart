// lib/screens/credito_screen.dart — interesse em crédito rural / CPR. O produtor registra
// o que precisa e autoriza o contato; o administrador vê a lista para levar a parceiros.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cafe_model.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../utils/erros.dart';
import '../utils/theme.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
const _modalidades = ['CPR', 'CPR Financeira', 'Custeio', 'Investimento', 'Comercialização', 'Outro'];

class CreditoScreen extends StatefulWidget {
  const CreditoScreen({super.key});
  @override
  State<CreditoScreen> createState() => _CreditoScreenState();
}

class _CreditoScreenState extends State<CreditoScreen> {
  List<Map<String, dynamic>>? _meus;
  List<Map<String, dynamic>>? _todos;
  String? _erro;

  bool get _admin => context.read<AppState>().usuario?.isAdmin == true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final meus = await ApiService.getMeusCreditos();
      final todos = _admin ? await ApiService.getTodosCreditos() : null;
      if (mounted) setState(() { _meus = meus; _todos = todos; _erro = null; });
    } catch (e) {
      if (mounted) setState(() { _meus = []; _erro = mensagemDeErro(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = _admin;
    return DefaultTabController(
      length: admin ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Crédito e CPR'),
          bottom: admin
              ? const TabBar(
                  labelColor: CafeColors.gold,
                  unselectedLabelColor: CafeColors.cream,
                  indicatorColor: CafeColors.gold,
                  tabs: [Tab(text: 'Meus pedidos'), Tab(text: 'Todos (admin)')],
                )
              : null,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final ok = await showModalBottomSheet<bool>(
                context: context, isScrollControlled: true, builder: (_) => const _FormCredito());
            if (ok == true) _carregar();
          },
          icon: const Icon(Icons.add),
          label: const Text('Registrar interesse'),
        ),
        body: _meus == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [_abaMeus(), if (admin) _abaTodos()]),
      ),
    );
  }

  Widget _centro(List<Widget> filhos) => RefreshIndicator(
        onRefresh: _carregar,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), children: filhos),
          ),
        ),
      );

  Widget _abaMeus() => _centro([
        Card(
          color: CafeColors.cream,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'A CPR (Cédula de Produto Rural) permite antecipar recursos dando parte da safra como garantia. '
              'Registre aqui o que você precisa: o Café Conecta encaminha o pedido a cooperativas e bancos parceiros, '
              'que entram em contato. O app não concede crédito nem cobra por isso.',
              style: GoogleFonts.dmSans(fontSize: 13, height: 1.45, color: CafeColors.darkRoast),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_erro != null) Padding(padding: const EdgeInsets.all(16), child: Text(_erro!, textAlign: TextAlign.center)),
        if (_erro == null && _meus!.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Nenhum interesse registrado.',
                textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: CafeColors.lightRoast)),
          ),
        for (final c in _meus!)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              title: Text('${c['modalidade']}${c['valor_desejado'] != null ? ' · ${_brl.format(c['valor_desejado'] as num)}' : ''}',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
              subtitle: Text([
                if (c['cafe'] != null) 'Lote: ${c['cafe']['tipo']} ${c['cafe']['classificacao'] ?? ''}',
                'Registrado em ${DateFormat('dd/MM/yyyy').format(DateTime.parse(c['criado_em']).toLocal())}',
                if (c['observacoes'] != null) c['observacoes'],
              ].join('\n')),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: 'Retirar',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  try {
                    await ApiService.retirarCredito(c['id']);
                    _carregar();
                  } catch (e) {
                    if (mounted) mostrarErro(context, e);
                  }
                },
              ),
            ),
          ),
      ]);

  Widget _abaTodos() => _centro([
        if ((_todos ?? []).isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Nenhum interesse registrado ainda.',
                textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: CafeColors.lightRoast)),
          ),
        for (final c in _todos ?? [])
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${c['usuario']?['nome'] ?? '—'} · ${c['modalidade']}'
                    '${c['valor_desejado'] != null ? ' · ${_brl.format(c['valor_desejado'] as num)}' : ''}',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                SelectableText([
                  [c['usuario']?['cidade'], c['usuario']?['estado']].where((e) => e != null).join('/'),
                  c['usuario']?['email'],
                  c['usuario']?['telefone'],
                ].where((e) => e != null && '$e'.isNotEmpty).join(' · ')),
                if (c['cafe'] != null)
                  Text('Lote: ${c['cafe']['tipo']} ${c['cafe']['classificacao'] ?? ''} · ${c['cafe']['quantidade_sacas'] ?? '?'} sacas'),
                if (c['observacoes'] != null) Text('${c['observacoes']}'),
                Text('Em ${DateFormat('dd/MM/yyyy').format(DateTime.parse(c['criado_em']).toLocal())} · contato autorizado',
                    style: GoogleFonts.dmSans(fontSize: 11, color: CafeColors.lightRoast)),
              ]),
            ),
          ),
      ]);
}

class _FormCredito extends StatefulWidget {
  const _FormCredito();
  @override
  State<_FormCredito> createState() => _FormCreditoState();
}

class _FormCreditoState extends State<_FormCredito> {
  String _modalidade = 'CPR';
  String? _cafeId;
  List<CafeModel> _lotes = [];
  final _valor = TextEditingController();
  final _obs = TextEditingController();
  bool _autoriza = false;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _carregarLotes();
  }

  Future<void> _carregarLotes() async {
    final u = context.read<AppState>().usuario;
    if (u?.id == null) return;
    try {
      final l = await ApiService.getCafes(usuarioId: u!.id, status: 'ativo');
      if (mounted) setState(() => _lotes = l);
    } catch (_) {}
  }

  @override
  void dispose() {
    _valor.dispose();
    _obs.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_autoriza) {
      mostrarErro(context, 'Marque a autorização de contato para registrar o interesse');
      return;
    }
    final t = _valor.text.trim();
    final v = t.isEmpty ? null : double.tryParse(t.contains(',') ? t.replaceAll('.', '').replaceAll(',', '.') : t);
    setState(() => _enviando = true);
    try {
      await ApiService.registrarCredito({
        'modalidade': _modalidade, 'cafe_id': _cafeId, 'valor_desejado': v,
        'observacoes': _obs.text.trim(), 'autoriza_contato': true,
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
          Text('Interesse em crédito',
              style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _modalidade,
            decoration: const InputDecoration(labelText: 'Modalidade'),
            items: _modalidades.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _modalidade = v ?? _modalidade),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _valor,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: const InputDecoration(labelText: 'Valor desejado (opcional)', prefixText: r'R$ '),
          ),
          if (_lotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<String?>(
              value: _cafeId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Lote como referência (opcional)'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Nenhum')),
                for (final l in _lotes)
                  DropdownMenuItem<String?>(value: l.id, child: Text('${l.tipo} ${l.classificacao} · ${l.quantidade} sacas')),
              ],
              onChanged: (v) => setState(() => _cafeId = v),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _obs,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Para que precisa e prazo (opcional)'),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _autoriza,
            onChanged: (v) => setState(() => _autoriza = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text('Autorizo o Café Conecta a compartilhar meu nome, contato e este pedido com '
                'cooperativas e instituições financeiras parceiras, para que me façam propostas.',
                style: GoogleFonts.dmSans(fontSize: 12)),
          ),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _enviando ? null : _enviar, child: Text(_enviando ? 'Enviando…' : 'Registrar interesse')),
        ]),
      ),
    );
  }
}
