// lib/screens/amostras_screen.dart — amostras pedidas e recebidas, com o fluxo
// solicitada → enviada → recebida → avaliada, e o formulário para pedir amostra.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/cafe_model.dart';
import '../services/api_service.dart';
import '../utils/erros.dart';
import '../utils/theme.dart';

const _rotuloStatus = {
  'solicitada': 'Solicitada',
  'enviada': 'Enviada',
  'recebida': 'Recebida',
  'avaliada': 'Avaliada',
  'recusada': 'Recusada',
  'cancelada': 'Cancelada',
};

Color _corStatus(String s) => switch (s) {
      'avaliada' => CafeColors.greenOk,
      'recusada' || 'cancelada' => CafeColors.redAlert,
      'enviada' || 'recebida' => CafeColors.caramel,
      _ => CafeColors.lightRoast,
    };

/// Abre o formulário para pedir amostra de um lote. Devolve true se o pedido foi feito.
Future<bool> pedirAmostra(BuildContext context, CafeModel cafe) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FormPedido(cafe: cafe),
  );
  if (ok == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Amostra pedida. O vendedor recebe um aviso e você acompanha em Amostras.')));
  }
  return ok == true;
}

class _FormPedido extends StatefulWidget {
  final CafeModel cafe;
  const _FormPedido({required this.cafe});
  @override
  State<_FormPedido> createState() => _FormPedidoState();
}

class _FormPedidoState extends State<_FormPedido> {
  final _endereco = TextEditingController();
  final _obs = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _endereco.dispose();
    _obs.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_endereco.text.trim().isEmpty) {
      mostrarErro(context, 'Informe o endereço para receber a amostra');
      return;
    }
    setState(() => _enviando = true);
    try {
      await ApiService.pedirAmostra(widget.cafe.id!, _endereco.text.trim(), _obs.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cafe;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Pedir amostra',
            style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
        const SizedBox(height: 4),
        Text('${c.tipo} ${c.classificacao}${c.fazenda != null ? ' · ${c.fazenda}' : ''}',
            style: GoogleFonts.dmSans(color: CafeColors.lightRoast)),
        const SizedBox(height: 16),
        TextField(
          controller: _endereco,
          maxLines: 3,
          minLines: 2,
          decoration: const InputDecoration(
              labelText: 'Endereço de entrega', hintText: 'Rua, número, cidade, CEP e quem recebe'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _obs,
          maxLines: 2,
          decoration: const InputDecoration(
              labelText: 'Observações (opcional)', hintText: 'ex.: 300 g, enviar pelos Correios'),
        ),
        const SizedBox(height: 8),
        Text('O endereço só é mostrado ao vendedor deste lote.',
            style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _enviando ? null : _enviar,
          icon: const Icon(Icons.inventory_outlined),
          label: Text(_enviando ? 'Enviando…' : 'Pedir amostra'),
        ),
      ]),
    );
  }
}

class AmostrasScreen extends StatefulWidget {
  const AmostrasScreen({super.key});
  @override
  State<AmostrasScreen> createState() => _AmostrasScreenState();
}

class _AmostrasScreenState extends State<AmostrasScreen> {
  List<Map<String, dynamic>>? _lista;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final l = await ApiService.getAmostras();
      if (mounted) setState(() { _lista = l; _erro = null; });
    } catch (e) {
      if (mounted) setState(() { _lista = []; _erro = mensagemDeErro(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final todas = _lista;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Amostras'),
          bottom: const TabBar(
            labelColor: CafeColors.gold,
            unselectedLabelColor: CafeColors.cream,
            indicatorColor: CafeColors.gold,
            tabs: [Tab(text: 'Que pedi'), Tab(text: 'Para enviar')],
          ),
        ),
        body: todas == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [
                _aba(todas.where((a) => a['souVendedor'] != true).toList(),
                    'Você ainda não pediu amostras. Peça na página de um lote do catálogo.'),
                _aba(todas.where((a) => a['souVendedor'] == true).toList(),
                    'Nenhum pedido de amostra dos seus lotes.'),
              ]),
      ),
    );
  }

  Widget _aba(List<Map<String, dynamic>> itens, String vazio) {
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(padding: const EdgeInsets.all(12), children: [
        if (_erro != null)
          Padding(padding: const EdgeInsets.all(24), child: Text(_erro!, textAlign: TextAlign.center))
        else if (itens.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(vazio,
                textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: CafeColors.lightRoast)),
          )
        else
          for (final a in itens)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _CartaoAmostra(amostra: a, onMudou: _carregar),
              ),
            ),
      ]),
    );
  }
}

class _CartaoAmostra extends StatelessWidget {
  final Map<String, dynamic> amostra;
  final Future<void> Function() onMudou;
  const _CartaoAmostra({required this.amostra, required this.onMudou});

  @override
  Widget build(BuildContext context) {
    final a = amostra;
    final souVendedor = a['souVendedor'] == true;
    final status = a['status'] as String? ?? 'solicitada';
    final cafe = (a['cafe'] as Map?) ?? {};
    final outro = (souVendedor ? a['solicitante'] : a['vendedor']) as Map? ?? {};
    final data = DateTime.tryParse(a['criado_em'] ?? '');
    final nota = a['nota'] as num?;

    Future<void> mudar(String novo, [Map<String, dynamic> extra = const {}]) async {
      try {
        await ApiService.atualizarAmostra(a['id'], {'status': novo, ...extra});
        await onMudou();
      } catch (e) {
        if (context.mounted) mostrarErro(context, e);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('${cafe['tipo'] ?? ''} ${cafe['classificacao'] ?? ''}'
                  '${cafe['fazenda'] != null ? ' · ${cafe['fazenda']}' : ''}',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _corStatus(status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_rotuloStatus[status] ?? status,
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: _corStatus(status))),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            '${souVendedor ? 'Pedido por' : 'Vendedor'}: ${outro['nome'] ?? '—'}'
            '${outro['cidade'] != null ? ' · ${outro['cidade']}/${outro['estado'] ?? ''}' : ''}'
            '${data != null ? ' · ${DateFormat('dd/MM/yyyy').format(data.toLocal())}' : ''}',
            style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast),
          ),
          if (souVendedor && a['endereco'] != null) ...[
            const SizedBox(height: 8),
            SelectableText('Enviar para: ${a['endereco']}', style: GoogleFonts.dmSans(fontSize: 13)),
          ],
          if (a['observacoes'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Obs.: ${a['observacoes']}', style: GoogleFonts.dmSans(fontSize: 13)),
            ),
          if (a['codigo_rastreio'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                const Icon(Icons.local_shipping_outlined, size: 16, color: CafeColors.caramel),
                const SizedBox(width: 6),
                Expanded(child: SelectableText('Rastreio: ${a['codigo_rastreio']}', style: GoogleFonts.dmSans(fontSize: 13))),
                IconButton(
                  tooltip: 'Copiar',
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () => Clipboard.setData(ClipboardData(text: '${a['codigo_rastreio']}')),
                ),
              ]),
            ),
          if (status == 'avaliada') ...[
            const Divider(height: 20),
            Text('Resultado da prova', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text([
              if (nota != null) 'Nota ${nota.toStringAsFixed(1).replaceAll('.', ',')}',
              if (a['bebida_resultado'] != null) 'Bebida ${a['bebida_resultado']}',
              if (a['defeitos'] != null) '${a['defeitos']} defeitos',
            ].join(' · '), style: GoogleFonts.dmSans(fontSize: 13)),
            if (a['comentario'] != null)
              Text(a['comentario'], style: GoogleFonts.dmSans(fontSize: 13, color: CafeColors.lightRoast)),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: [
            if (souVendedor && status == 'solicitada') ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.local_shipping_outlined, size: 18),
                label: const Text('Marcar como enviada'),
                onPressed: () async {
                  final codigo = await _perguntarRastreio(context);
                  if (codigo != null) await mudar('enviada', {'codigo_rastreio': codigo});
                },
              ),
              TextButton(onPressed: () => mudar('recusada'), child: const Text('Recusar')),
            ],
            if (!souVendedor && status == 'solicitada')
              TextButton(onPressed: () => mudar('cancelada'), child: const Text('Cancelar pedido')),
            if (!souVendedor && status == 'enviada')
              OutlinedButton(onPressed: () => mudar('recebida'), child: const Text('Recebi a amostra')),
            if (!souVendedor && (status == 'enviada' || status == 'recebida'))
              ElevatedButton.icon(
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('Registrar prova'),
                onPressed: () async {
                  final r = await showModalBottomSheet<Map<String, dynamic>>(
                      context: context, isScrollControlled: true, builder: (_) => const _FormProva());
                  if (r != null) await mudar('avaliada', r);
                },
              ),
          ]),
        ]),
      ),
    );
  }

  Future<String?> _perguntarRastreio(BuildContext context) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Amostra enviada'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(labelText: 'Código de rastreio (opcional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Voltar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Confirmar')),
        ],
      ),
    );
  }
}

class _FormProva extends StatefulWidget {
  const _FormProva();
  @override
  State<_FormProva> createState() => _FormProvaState();
}

class _FormProvaState extends State<_FormProva> {
  final _nota = TextEditingController();
  final _defeitos = TextEditingController();
  final _comentario = TextEditingController();
  String? _bebida;

  @override
  void dispose() {
    _nota.dispose();
    _defeitos.dispose();
    _comentario.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Resultado da prova',
            style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
        const SizedBox(height: 4),
        Text('O resultado aparece para o vendedor e, sem seu nome, na página do lote.',
            style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _nota,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(labelText: 'Nota SCA (0–100)'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _defeitos,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Defeitos'),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _bebida,
          decoration: const InputDecoration(labelText: 'Bebida'),
          items: const ['Estritamente mole', 'Mole', 'Apenas mole', 'Dura', 'Riada', 'Rio', 'Rio zona']
              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
              .toList(),
          onChanged: (v) => setState(() => _bebida = v),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _comentario,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Comentários (aroma, corpo, acidez…)'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            final n = double.tryParse(_nota.text.trim().replaceAll(',', '.'));
            if (n != null && (n < 0 || n > 100)) {
              mostrarErro(context, 'Nota deve ficar entre 0 e 100');
              return;
            }
            Navigator.pop(context, {
              'nota': n,
              'defeitos': int.tryParse(_defeitos.text.trim()),
              'bebida_resultado': _bebida,
              'comentario': _comentario.text.trim(),
            });
          },
          child: const Text('Salvar resultado'),
        ),
      ]),
    );
  }
}
