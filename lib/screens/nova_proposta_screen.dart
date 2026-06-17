// lib/screens/nova_proposta_screen.dart — Melhoria 5
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/cafe_model.dart';
import '../services/app_state.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';

class NovaPropostaScreen extends StatefulWidget {
  final CafeModel cafe;
  const NovaPropostaScreen({super.key, required this.cafe});
  @override State<NovaPropostaScreen> createState() => _NovaPropostaScreenState();
}

class _NovaPropostaScreenState extends State<NovaPropostaScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  bool _enviada = false;
  String? _numProposta;

  final _qtdCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  String _negociacao = 'Compra direta';
  String _pagamento = '30/60 dias';
  String _prazo = '15 dias';
  String _local = 'FOB Fazenda';
  final _obsCtrl = TextEditingController();

  final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  double get _total {
    final qtd = int.tryParse(_qtdCtrl.text) ?? 0;
    final preco = double.tryParse(_precoCtrl.text.replaceAll(',', '.')) ?? 0;
    return qtd * preco;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar Proposta'),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_step + 1) / 4,
            backgroundColor: Colors.white.withValues(alpha: 0.2), color: CafeColors.gold)),
      ),
      body: Column(children: [
        _buildStepIndicator(),
        Expanded(child: PageView(
          controller: _pageCtrl, physics: const NeverScrollableScrollPhysics(),
          children: [_step1(), _step2(), _step3(), _step4()],
        )),
        if (!_enviada) _buildFooter(),
      ]),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Básico', 'Condições', 'Revisão', 'Enviar'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.white,
      child: Row(children: steps.asMap().entries.map((e) {
        final done = e.key < _step;
        final cur = e.key == _step;
        return Expanded(child: Row(children: [
          if (e.key > 0) Expanded(child: Container(height: 1.5,
            color: done ? CafeColors.greenOk : CafeColors.lightRoast.withValues(alpha: 0.2))),
          Column(children: [
            AnimatedContainer(duration: const Duration(milliseconds: 250),
              width: 26, height: 26, decoration: BoxDecoration(shape: BoxShape.circle,
                color: done ? CafeColors.greenOk : cur ? CafeColors.caramel : Colors.white,
                border: Border.all(color: done ? CafeColors.greenOk : cur ? CafeColors.caramel : CafeColors.lightRoast.withValues(alpha: 0.3), width: 1.5)),
              child: Center(child: done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text('${e.key + 1}', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700,
                    color: cur ? CafeColors.espresso : CafeColors.lightRoast)))),
            const SizedBox(height: 4),
            Text(e.value, style: GoogleFonts.dmSans(fontSize: 9, fontWeight: cur ? FontWeight.w700 : FontWeight.w400,
              color: cur ? CafeColors.caramel : CafeColors.lightRoast)),
          ]),
          if (e.key == steps.length - 1) const SizedBox(width: 0),
        ]));
      }).toList()),
    );
  }

  Widget _step1() => _StepWrap(title: 'Informações da Proposta', hint: 'Passo 1 de 4', children: [
    _InfoBox(cafe: widget.cafe),
    const SizedBox(height: 16),
    Row(children: [
      Expanded(child: _field(_qtdCtrl, 'Quantidade (sacas)', TextInputType.number)),
      const SizedBox(width: 12),
      Expanded(child: _field(_precoCtrl, 'Preço/saca (R\$)', const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}))),
    ]),
    if (_total > 0) ...[
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: CafeColors.greenOk.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CafeColors.greenOk.withValues(alpha: 0.2))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Valor total estimado', style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
          Text(_brl.format(_total), style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700, color: CafeColors.greenOk)),
        ])),
    ],
    const SizedBox(height: 12),
    _dropField('Tipo de negociação', ['Compra direta','Contrato futuro','Consignação'], _negociacao, (v) => setState(() => _negociacao = v!)),
  ]);

  Widget _step2() => _StepWrap(title: 'Condições Comerciais', hint: 'Passo 2 de 4', children: [
    _dropField('Condição de pagamento', condicoesPagamento, _pagamento, (v) => setState(() => _pagamento = v!)),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: _dropField('Prazo de entrega', prazosEntrega, _prazo, (v) => setState(() => _prazo = v!))),
      const SizedBox(width: 12),
      Expanded(child: _dropField('Local de entrega', locaisEntrega, _local, (v) => setState(() => _local = v!))),
    ]),
    const SizedBox(height: 12),
    TextField(controller: _obsCtrl, maxLines: 3,
      decoration: const InputDecoration(labelText: 'Observações (opcional)', alignLabelWithHint: true)),
  ]);

  Widget _step3() => _StepWrap(title: 'Revise sua Proposta', hint: 'Passo 3 de 4 — Confirme antes de enviar', children: [
    Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: CafeColors.milk,
      borderRadius: BorderRadius.circular(10), border: Border.all(color: CafeColors.lightRoast.withValues(alpha: 0.15))),
      child: Column(children: [
        _sumRow('Lote', '${widget.cafe.tipo} ${widget.cafe.classificacao}'),
        _sumRow('Fazenda', widget.cafe.fazenda ?? '—'),
        _sumRow('Quantidade', '${_qtdCtrl.text} sacas'),
        _sumRow('Preço/saca', 'R\$ ${_precoCtrl.text}'),
        _sumRow('Negociação', _negociacao),
        _sumRow('Pagamento', _pagamento),
        _sumRow('Prazo', _prazo),
        _sumRow('Entrega', _local),
        if (_obsCtrl.text.isNotEmpty) _sumRow('Obs.', _obsCtrl.text),
        const Divider(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('VALOR TOTAL', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
          Text(_brl.format(_total), style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: CafeColors.greenOk)),
        ]),
      ])),
    const SizedBox(height: 12),
    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
      color: CafeColors.greenOk.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8),
      border: Border.all(color: CafeColors.greenOk.withValues(alpha: 0.2))),
      child: Row(children: [
        const Icon(Icons.verified_outlined, color: CafeColors.greenOk, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text('Esta proposta será registrada oficialmente. Ambas as partes receberão cópia por e-mail.',
          style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.greenOk))),
      ])),
  ]);

  Widget _step4() => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text('🎉', style: TextStyle(fontSize: 60)),
    const SizedBox(height: 16),
    Text('Proposta Enviada!', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w900, color: CafeColors.darkRoast)),
    const SizedBox(height: 8),
    Text('Sua proposta foi registrada e enviada para ${widget.cafe.corretorNome ?? 'o corretor'}.\nVocê receberá uma notificação quando houver resposta.',
      textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 14, color: CafeColors.lightRoast, height: 1.5)),
    const SizedBox(height: 20),
    if (_numProposta != null) Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: CafeColors.milk, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CafeColors.lightRoast.withValues(alpha: 0.15))),
      child: Column(children: [
        _sumRow('Número', _numProposta!),
        _sumRow('Status', '✅ Aguardando resposta'),
        _sumRow('Total', _brl.format(_total)),
      ])),
    const SizedBox(height: 24),
    SizedBox(width: double.infinity, child: ElevatedButton(
      onPressed: () => Navigator.pop(context), child: const Text('Fechar'))),
  ])));

  Widget _buildFooter() => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
    decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))]),
    child: Row(children: [
      if (_step > 0) ...[
        OutlinedButton(onPressed: _prev,
          style: OutlinedButton.styleFrom(foregroundColor: CafeColors.darkRoast, side: const BorderSide(color: CafeColors.lightRoast),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20)),
          child: Text('← Voltar', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600))),
        const SizedBox(width: 12),
      ],
      Expanded(child: ElevatedButton(
        onPressed: _step == 3 ? _enviar : _next,
        style: ElevatedButton.styleFrom(
          backgroundColor: _step == 2 ? CafeColors.greenOk : CafeColors.caramel,
          foregroundColor: _step == 2 ? Colors.white : CafeColors.espresso),
        child: Text(_step == 2 ? '📤 Enviar Proposta' : 'Próximo →', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15)))),
    ]),
  );

  void _next() { if (_step < 3) { setState(() => _step++); _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); } }
  void _prev() { if (_step > 0) { setState(() => _step--); _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); } }

  Future<void> _enviar() async {
    final u = context.read<AppState>().usuario;
    if (u == null) return;
    final proposta = PropostaModel(
      deUsuarioId: u.id!, paraUsuarioId: widget.cafe.usuarioId, cafeId: widget.cafe.id!,
      quantidadeSacas: int.tryParse(_qtdCtrl.text) ?? 0,
      precoOfertado: double.tryParse(_precoCtrl.text.replaceAll(',', '.')) ?? 0,
      condicaoPagamento: _pagamento, prazoEntrega: _prazo, localEntrega: _local,
      observacoes: _obsCtrl.text.isEmpty ? null : _obsCtrl.text,
    );
    final id = await DatabaseService.inserirProposta(proposta);
    setState(() { _enviada = true; _numProposta = '#PROP-2025-${id.toString().padLeft(3, '0')}'; _step = 3; });
    _pageCtrl.animateToPage(3, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Widget _field(TextEditingController ctrl, String label, TextInputType tipo, {void Function(String)? onChanged}) =>
    TextField(controller: ctrl, keyboardType: tipo, onChanged: onChanged,
      decoration: InputDecoration(labelText: label, isDense: true));

  Widget _dropField(String label, List<String> items, String value, void Function(String?) onChanged) =>
    DropdownButtonFormField<String>(value: value,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: GoogleFonts.dmSans(fontSize: 13)))).toList(),
      onChanged: onChanged);

  Widget _sumRow(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
      Flexible(child: Text(v, textAlign: TextAlign.right, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: CafeColors.darkRoast))),
    ]));
}

class _InfoBox extends StatelessWidget {
  final CafeModel cafe;
  const _InfoBox({required this.cafe});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [CafeColors.darkRoast, CafeColors.mediumRoast]),
      borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      const Text('☕', style: TextStyle(fontSize: 28)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(cafe.nomeCurto, style: GoogleFonts.playfairDisplay(color: CafeColors.gold, fontSize: 14, fontWeight: FontWeight.w700)),
        Text('${cafe.fazenda ?? ''} · ${cafe.cidade}', style: GoogleFonts.dmSans(color: CafeColors.cream.withValues(alpha: 0.7), fontSize: 11)),
      ])),
    ]),
  );
}

class _StepWrap extends StatelessWidget {
  final String title, hint;
  final List<Widget> children;
  const _StepWrap({required this.title, required this.hint, required this.children});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(hint, style: GoogleFonts.dmSans(fontSize: 11, color: CafeColors.lightRoast)),
      Text(title, style: GoogleFonts.playfairDisplay(fontSize: 17, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
      const SizedBox(height: 16),
      ...children,
    ]),
  );
}
