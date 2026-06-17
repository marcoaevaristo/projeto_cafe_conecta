// lib/screens/propostas_screen.dart — v3: Com contraproposta
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/cafe_model.dart';
import '../services/app_state.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../widgets/cafe_card.dart';
import 'avaliacoes_screen.dart';

class PropostasScreen extends StatefulWidget {
  const PropostasScreen({super.key});
  @override
  State<PropostasScreen> createState() => _PropostasScreenState();
}

class _PropostasScreenState extends State<PropostasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<PropostaModel> _propostas = [];
  final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _carregar();
  }

  Future<void> _carregar() async {
    final u = context.read<AppState>().usuario;
    if (u == null) return;
    final list = await DatabaseService.getPropostas(u.id!);
    setState(() => _propostas = list);
  }

  List<PropostaModel> _por(String status) {
    if (status == 'aguardando')
      return _propostas.where((p) => p.status == 'aguardando').toList();
    if (status == 'ativas')
      return _propostas.where((p) => p.status == 'aceita').toList();
    return _propostas
        .where((p) => p.status == 'recusada' || p.status == 'contraproposta')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final logado = context.watch<AppState>().logado;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Propostas'),
        bottom: TabBar(
            controller: _tabs,
            labelColor: CafeColors.gold,
            unselectedLabelColor: CafeColors.cream,
            indicatorColor: CafeColors.caramel,
            labelStyle:
                GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 12),
            tabs: [
              Tab(text: 'Aguardando (${_por('aguardando').length})'),
              Tab(text: 'Aceitas (${_por('ativas').length})'),
              Tab(text: 'Outras (${_por('outras').length})'),
            ]),
      ),
      body: !logado
          ? const EmptyState(
              icon: Icons.assignment_outlined,
              titulo: 'Faça login para ver propostas')
          : TabBarView(controller: _tabs, children: [
              _Lista(
                  propostas: _por('aguardando'),
                  brl: _brl,
                  onRefresh: _carregar,
                  tipo: 'aguardando'),
              _Lista(
                  propostas: _por('ativas'),
                  brl: _brl,
                  onRefresh: _carregar,
                  tipo: 'aceita'),
              _Lista(
                  propostas: _por('outras'),
                  brl: _brl,
                  onRefresh: _carregar,
                  tipo: 'outras'),
            ]),
    );
  }
}

class _Lista extends StatelessWidget {
  final List<PropostaModel> propostas;
  final NumberFormat brl;
  final Future<void> Function() onRefresh;
  final String tipo;
  const _Lista(
      {required this.propostas,
      required this.brl,
      required this.onRefresh,
      required this.tipo});

  @override
  Widget build(BuildContext context) {
    if (propostas.isEmpty)
      return const EmptyState(
          icon: Icons.assignment_outlined, titulo: 'Nenhuma proposta aqui');
    return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: propostas.length,
          itemBuilder: (_, i) => _PropostaCard(
              proposta: propostas[i], brl: brl, onRefresh: onRefresh),
        ));
  }
}

class _PropostaCard extends StatelessWidget {
  final PropostaModel proposta;
  final NumberFormat brl;
  final Future<void> Function() onRefresh;
  const _PropostaCard(
      {required this.proposta, required this.brl, required this.onRefresh});

  Color get _statusColor {
    switch (proposta.status) {
      case 'aceita':
        return CafeColors.greenOk;
      case 'recusada':
        return CafeColors.redAlert;
      case 'contraproposta':
        return CafeColors.blue;
      default:
        return CafeColors.gold;
    }
  }

  String get _statusLabel {
    switch (proposta.status) {
      case 'aceita':
        return '✓ Aceita';
      case 'recusada':
        return '✕ Recusada';
      case 'contraproposta':
        return '↩ Contraproposta';
      default:
        return '⏳ Aguardando';
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = context.read<AppState>().usuario;
    final recebida = proposta.paraUsuarioId == u?.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        recebida
                            ? (proposta.remetenteEmpresa ??
                                proposta.remetenteNome ??
                                'Comprador')
                            : 'Proposta enviada',
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: CafeColors.darkRoast)),
                    Text(_formatarData(proposta.criadoEm),
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: CafeColors.lightRoast)),
                  ])),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _statusColor.withValues(alpha: 0.3))),
                  child: Text(_statusLabel,
                      style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor))),
            ]),
            const SizedBox(height: 10),
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: CafeColors.milk,
                    borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  _row('Lote',
                      '${proposta.cafeTipo ?? ''} ${proposta.cafeClassificacao ?? ''}'),
                  _row('Fazenda', proposta.cafeFazenda ?? '—'),
                  _row('Quantidade', '${proposta.quantidadeSacas} sacas'),
                  _row('Preço/saca', brl.format(proposta.precoOfertado)),
                  _row('Pagamento', proposta.condicaoPagamento),
                  _row('Prazo', proposta.prazoEntrega),
                  const Divider(height: 12),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w600,
                                color: CafeColors.darkRoast,
                                fontSize: 13)),
                        Text(brl.format(proposta.valorTotal),
                            style: GoogleFonts.playfairDisplay(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: CafeColors.greenOk)),
                      ]),
                ])),
            if (proposta.observacoes != null &&
                proposta.observacoes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('"${proposta.observacoes}"',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: CafeColors.lightRoast,
                      fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 10),

            // Ações
            if (proposta.status == 'aguardando' && recebida)
              Row(children: [
                Expanded(
                    child: ElevatedButton(
                        onPressed: () => _aceitar(context),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: CafeColors.greenOk,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10)),
                        child: Text('✓ Aceitar',
                            style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700, fontSize: 12)))),
                const SizedBox(width: 6),
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => _contraproposta(context),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: CafeColors.blue,
                            side: const BorderSide(color: CafeColors.blue),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10)),
                        child: Text('↩ Contra',
                            style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700, fontSize: 12)))),
                const SizedBox(width: 6),
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => _recusar(context),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: CafeColors.redAlert,
                            side: const BorderSide(color: CafeColors.redAlert),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10)),
                        child: Text('✕ Recusar',
                            style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700, fontSize: 12)))),
              ]),

            if (proposta.status == 'aceita') ...[
              const SizedBox(height: 4),
              SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _avaliar(context),
                    icon: const Icon(Icons.star_outline, size: 16),
                    label: const Text('Avaliar negociação'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: CafeColors.gold,
                        side: const BorderSide(color: CafeColors.gold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                  )),
            ],
          ])),
    );
  }

  Widget _row(String l, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l,
            style:
                GoogleFonts.dmSans(fontSize: 11, color: CafeColors.lightRoast)),
        Text(v,
            style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CafeColors.darkRoast)),
      ]));

  Future<void> _aceitar(BuildContext context) async {
    await DatabaseService.atualizarStatusProposta(proposta.id!, 'aceita');
    await onRefresh();
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Proposta aceita! O comprador foi notificado.')));
  }

  Future<void> _recusar(BuildContext context) async {
    await DatabaseService.atualizarStatusProposta(proposta.id!, 'recusada');
    await onRefresh();
  }

  void _contraproposta(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) =>
            _ContrapropostaSheet(proposta: proposta, onSaved: onRefresh));
  }

  void _avaliar(BuildContext context) async {
    final u = context.read<AppState>().usuario;
    if (u == null) return;
    final jaAvaliou = await DatabaseService.jaAvaliou(u.id!, proposta.id!);
    if (jaAvaliou) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Você já avaliou esta negociação.')));
      return;
    }
    if (context.mounted) {
      showDialog(
          context: context,
          builder: (_) => AvaliarDialog(
                deUsuarioId: u.id!,
                paraUsuarioId: proposta.deUsuarioId == u.id
                    ? proposta.paraUsuarioId
                    : proposta.deUsuarioId,
                propostaId: proposta.id!,
                nomeAvaliado: proposta.remetenteEmpresa ??
                    proposta.remetenteNome ??
                    'Usuário',
              ));
    }
  }

  String _formatarData(String? dt) {
    if (dt == null) return '';
    try {
      final d = DateTime.parse(dt);
      return 'há ${DateTime.now().difference(d).inDays == 0 ? 'hoje' : '${DateTime.now().difference(d).inDays}d'}';
    } catch (_) {
      return '';
    }
  }
}

// Contraproposta
class _ContrapropostaSheet extends StatefulWidget {
  final PropostaModel proposta;
  final Future<void> Function() onSaved;
  const _ContrapropostaSheet({required this.proposta, required this.onSaved});
  @override
  State<_ContrapropostaSheet> createState() => _ContrapropostaSheetState();
}

class _ContrapropostaSheetState extends State<_ContrapropostaSheet> {
  late TextEditingController _precoCtrl;
  late TextEditingController _obsCtrl;
  String _pagamento = '30/60 dias';
  bool _enviando = false;
  final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _precoCtrl =
        TextEditingController(text: widget.proposta.precoOfertado.toString());
    _obsCtrl = TextEditingController();
  }

  double get _novoTotal {
    final qtd = widget.proposta.quantidadeSacas;
    final preco = double.tryParse(_precoCtrl.text.replaceAll(',', '.')) ?? 0;
    return qtd * preco;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: CafeColors.lightRoast.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Text('↩ Contraproposta',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: CafeColors.darkRoast)),
            const SizedBox(height: 4),
            Text(
                'Proposta original: ${_brl.format(widget.proposta.precoOfertado)}/saca',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: CafeColors.lightRoast)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _precoCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Novo preço/saca (R\$)', isDense: true),
                      onChanged: (_) => setState(() {}))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Novo total',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: CafeColors.lightRoast)),
                    Text(_brl.format(_novoTotal),
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: CafeColors.greenOk)),
                  ])),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                value: _pagamento,
                decoration: const InputDecoration(
                    labelText: 'Condição de pagamento', isDense: true),
                items: condicoesPagamento
                    .map((p) => DropdownMenuItem(
                        value: p,
                        child:
                            Text(p, style: GoogleFonts.dmSans(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setState(() => _pagamento = v!)),
            const SizedBox(height: 12),
            TextField(
                controller: _obsCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Justificativa', isDense: true)),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _enviar,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: CafeColors.blue,
                      foregroundColor: Colors.white),
                  child: _enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Enviar Contraproposta'),
                )),
            const SizedBox(height: 8),
          ])),
    );
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    final u = context.read<AppState>().usuario!;
    final novaProposta = PropostaModel(
      deUsuarioId: u.id!,
      paraUsuarioId: widget.proposta.deUsuarioId,
      cafeId: widget.proposta.cafeId,
      quantidadeSacas: widget.proposta.quantidadeSacas,
      precoOfertado: double.tryParse(_precoCtrl.text.replaceAll(',', '.')) ??
          widget.proposta.precoOfertado,
      condicaoPagamento: _pagamento,
      prazoEntrega: widget.proposta.prazoEntrega,
      localEntrega: widget.proposta.localEntrega,
      observacoes: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      status: 'contraproposta',
    );
    await DatabaseService.inserirProposta(novaProposta);
    await DatabaseService.atualizarStatusProposta(
        widget.proposta.id!, 'contraproposta');
    await widget.onSaved();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('↩ Contraproposta enviada!')));
    }
  }
}
