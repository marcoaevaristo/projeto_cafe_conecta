// lib/screens/alertas_screen.dart — Melhoria 4
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/cafe_model.dart';
import '../services/app_state.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../widgets/cafe_card.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});
  @override State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  List<AlertaModel> _alertas = [];

  @override void didChangeDependencies() { super.didChangeDependencies(); _carregar(); }

  Future<void> _carregar() async {
    final u = context.read<AppState>().usuario;
    if (u == null) return;
    final list = await DatabaseService.getAlertas(u.id!);
    setState(() => _alertas = list);
  }

  @override
  Widget build(BuildContext context) {
    final logado = context.watch<AppState>().logado;
    return Scaffold(
      appBar: AppBar(title: const Text('Alertas de Preço'),
        actions: [if (logado) IconButton(icon: const Icon(Icons.add), onPressed: _novoAlerta)]),
      body: !logado
        ? const EmptyState(icon: Icons.notifications_off_outlined, titulo: 'Faça login para usar alertas')
        : _alertas.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_outlined,
              titulo: 'Nenhum alerta configurado',
              subtitulo: 'Crie alertas para ser notificado quando surgirem lotes no seu perfil.',
              action: ElevatedButton.icon(onPressed: _novoAlerta, icon: const Icon(Icons.add), label: const Text('Criar Alerta')))
          : Column(children: [
              Container(color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text('Você será notificado quando as condições forem atendidas.',
                  style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast))),
              Expanded(child: RefreshIndicator(onRefresh: _carregar, child: ListView(children: [
                ..._alertas.map((a) => _AlertaTile(alerta: a,
                  onToggle: (val) async { await DatabaseService.toggleAlerta(a.id!, val); _carregar(); },
                  onDelete: () async { await DatabaseService.excluirAlerta(a.id!); _carregar(); })),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: OutlinedButton.icon(
                    onPressed: _novoAlerta,
                    icon: const Icon(Icons.add),
                    label: const Text('Criar novo alerta'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CafeColors.caramel,
                      side: const BorderSide(color: CafeColors.caramel, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14))),
                ),
              ]))),
            ]),
    );
  }

  void _novoAlerta() {
    final u = context.read<AppState>().usuario;
    if (u == null) return;
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _NovoAlertaSheet(usuarioId: u.id!, onSaved: _carregar));
  }
}

class _AlertaTile extends StatelessWidget {
  final AlertaModel alerta;
  final void Function(bool) onToggle;
  final VoidCallback onDelete;
  const _AlertaTile({required this.alerta, required this.onToggle, required this.onDelete});

  String get _icon {
    if (alerta.tipoCafe == 'Arábica' && alerta.classificacao == 'Especial') return '🌿';
    if (alerta.tipoCafe == 'Conilon') return '🌾';
    if (alerta.tipoCafe == 'Robusta') return '🫘';
    return '☕';
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(
        color: CafeColors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9),
        border: Border.all(color: CafeColors.gold.withValues(alpha: 0.2))),
        child: Center(child: Text(_icon, style: const TextStyle(fontSize: 16)))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_titulo, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: CafeColors.darkRoast)),
        Text(_subtitulo, style: GoogleFonts.dmSans(fontSize: 11, color: CafeColors.lightRoast)),
        Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: alerta.ativo ? CafeColors.greenOk.withValues(alpha: 0.1) : CafeColors.lightRoast.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: alerta.ativo ? CafeColors.greenOk.withValues(alpha: 0.3) : CafeColors.lightRoast.withValues(alpha: 0.2))),
          child: Text(alerta.ativo ? '● Ativo' : '● Pausado',
            style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600,
              color: alerta.ativo ? CafeColors.greenOk : CafeColors.lightRoast))),
      ])),
      Column(children: [
        Switch(value: alerta.ativo, onChanged: onToggle, activeColor: CafeColors.greenOk),
        GestureDetector(onTap: onDelete, child: Icon(Icons.delete_outline, size: 18, color: CafeColors.redAlert.withValues(alpha: 0.6))),
      ])),
    ])),
  );

  String get _titulo {
    final p = [if (alerta.tipoCafe != null) alerta.tipoCafe!, if (alerta.classificacao != null) alerta.classificacao!];
    return p.isEmpty ? 'Qualquer café' : p.join(' · ');
  }

  String get _subtitulo {
    final p = <String>[];
    if (alerta.regiao != null) p.add(alerta.regiao!);
    if (alerta.precoMaximo != null) p.add('Preço < R\$ ${alerta.precoMaximo!.toStringAsFixed(0)}');
    if (alerta.scoreMinimo != null) p.add('Score ≥ ${alerta.scoreMinimo}');
    return p.isEmpty ? 'Qualquer condição' : p.join(' · ');
  }
}

class _NovoAlertaSheet extends StatefulWidget {
  final int usuarioId;
  final VoidCallback onSaved;
  const _NovoAlertaSheet({required this.usuarioId, required this.onSaved});
  @override State<_NovoAlertaSheet> createState() => _NovoAlertaSheetState();
}

class _NovoAlertaSheetState extends State<_NovoAlertaSheet> {
  String? _tipo, _classif, _regiao;
  final _precoCtrl = TextEditingController();
  final _scoreCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: CafeColors.lightRoast.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text('🔔 Novo Alerta', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _drop('Tipo', tiposCafe, _tipo, (v) => setState(() => _tipo = v))),
          const SizedBox(width: 10),
          Expanded(child: _drop('Classificação', classificacoesCafe, _classif, (v) => setState(() => _classif = v))),
        ]),
        const SizedBox(height: 10),
        _drop('Região', regioesCafe, _regiao, (v) => setState(() => _regiao = v)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _precoCtrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Preço máximo (R\$)', isDense: true))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _scoreCtrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Score mínimo', isDense: true))),
        ]),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _salvar, child: const Text('🔔 Criar Alerta'))),
        const SizedBox(height: 8),
      ])),
    );
  }

  Widget _drop(String label, List<String> items, String? val, void Function(String?) onChange) =>
    DropdownButtonFormField<String>(value: val,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: GoogleFonts.dmSans(fontSize: 13)))).toList(),
      onChanged: onChange);

  Future<void> _salvar() async {
    final alerta = AlertaModel(
      usuarioId: widget.usuarioId, tipoCafe: _tipo, classificacao: _classif, regiao: _regiao,
      precoMaximo: double.tryParse(_precoCtrl.text.replaceAll(',', '.')),
      scoreMinimo: int.tryParse(_scoreCtrl.text));
    await DatabaseService.inserirAlerta(alerta);
    if (mounted) { Navigator.pop(context); widget.onSaved(); }
  }
}
