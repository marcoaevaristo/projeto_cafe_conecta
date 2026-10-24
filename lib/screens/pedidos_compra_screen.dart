// lib/screens/pedidos_compra_screen.dart — Pedidos de compra: quem compra diz o que procura
// e quem vende manda oferta. Abas: Procurando · Meus pedidos · Minhas ofertas.
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
import '../widgets/cafe_card.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
final _int = NumberFormat.decimalPattern('pt_BR');
final _dataCurta = DateFormat('dd/MM/yyyy');

double? _numero(String t) {
  final v = t.trim();
  if (v.isEmpty) return null;
  return double.tryParse(v.contains(',') ? v.replaceAll('.', '').replaceAll(',', '.') : v);
}

String _resumoPedido(Map p) => [
      p['tipo'],
      p['classificacao'],
      if (p['bebida'] != null) 'bebida ${p['bebida']}',
    ].where((e) => e != null && '$e'.isNotEmpty).join(' · ');

class PedidosCompraScreen extends StatefulWidget {
  const PedidosCompraScreen({super.key});
  @override
  State<PedidosCompraScreen> createState() => _PedidosCompraScreenState();
}

class _PedidosCompraScreenState extends State<PedidosCompraScreen> {
  int _versao = 0;
  void _recarregar() => setState(() => _versao++);

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppState>().usuario;
    final podeComprar = u != null && u.tipo != 'produtor';
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pedidos de compra'),
          bottom: TabBar(
            labelColor: CafeColors.gold,
            unselectedLabelColor: CafeColors.cream,
            indicatorColor: CafeColors.caramel,
            labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            tabs: const [Tab(text: 'Procurando'), Tab(text: 'Meus pedidos'), Tab(text: 'Minhas ofertas')],
          ),
        ),
        floatingActionButton: podeComprar
            ? FloatingActionButton.extended(
                backgroundColor: CafeColors.caramel,
                foregroundColor: CafeColors.espresso,
                icon: const Icon(Icons.add),
                label: Text('Novo pedido', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                onPressed: () async {
                  final ok = await Navigator.push<bool>(
                      context, MaterialPageRoute(builder: (_) => const _NovoPedidoScreen()));
                  if (ok == true) _recarregar();
                },
              )
            : null,
        body: TabBarView(children: [
          _AbaProcurando(key: ValueKey('a$_versao'), onMudou: _recarregar),
          _AbaMeusPedidos(key: ValueKey('b$_versao'), onMudou: _recarregar),
          _AbaMinhasOfertas(key: ValueKey('c$_versao')),
        ]),
      ),
    );
  }
}

/// Carrega uma lista e mostra carregando / erro / vazio.
class _Lista extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function() buscar;
  final Widget Function(Map<String, dynamic>) item;
  final String vazio;
  const _Lista({required this.buscar, required this.item, required this.vazio});
  @override
  State<_Lista> createState() => _ListaState();
}

class _ListaState extends State<_Lista> {
  List<Map<String, dynamic>>? _itens;
  Object? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final l = await widget.buscar();
      if (mounted) setState(() { _itens = l; _erro = null; });
    } catch (e) {
      if (mounted) setState(() => _erro = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_erro != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(mensagemDeErro(_erro!), textAlign: TextAlign.center)));
    }
    if (_itens == null) return const Center(child: CircularProgressIndicator());
    if (_itens!.isEmpty) return EmptyState(icon: Icons.shopping_basket_outlined, titulo: widget.vazio);
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        children: [for (final i in _itens!) widget.item(i)],
      ),
    );
  }
}

Widget _linha(String r, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(r, style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast))),
        Expanded(child: Text(v, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
    );

Widget _cartaoPedido(Map<String, dynamic> p, {List<Widget> rodape = const []}) {
  final u = (p['usuario'] as Map?) ?? {};
  final prazo = DateTime.tryParse('${p['prazo'] ?? ''}');
  return Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('${_int.format(p['quantidade_sacas'] ?? 0)} sacas · ${_resumoPedido(p)}',
                style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
          ),
          if (p['status'] != null && p['status'] != 'aberto')
            Chip(label: Text(p['status'] == 'atendido' ? 'Atendido' : 'Encerrado'), visualDensity: VisualDensity.compact),
        ]),
        const SizedBox(height: 6),
        if (u['nome'] != null) _linha('Comprador', '${u['nome']}${u['cidade'] != null ? ' · ${u['cidade']}/${u['estado'] ?? ''}' : ''}'),
        if (p['regiao'] != null) _linha('Região', '${p['regiao']}'),
        _linha('Paga até', p['preco_maximo'] != null ? '${_brl.format(p['preco_maximo'])} por saca' : 'a combinar'),
        if (prazo != null) _linha('Prazo', _dataCurta.format(prazo)),
        if (p['observacoes'] != null) _linha('Observações', '${p['observacoes']}'),
        if (p['total_ofertas'] != null) _linha('Ofertas', '${p['total_ofertas']}'),
        ...rodape,
      ]),
    ),
  );
}

// ── Aba: pedidos de outras pessoas ─────────────────────────────────────
class _AbaProcurando extends StatelessWidget {
  final VoidCallback onMudou;
  const _AbaProcurando({super.key, required this.onMudou});

  @override
  Widget build(BuildContext context) {
    return _Lista(
      buscar: ApiService.getPedidos,
      vazio: 'Nenhum pedido de compra aberto agora',
      item: (p) => _cartaoPedido(p, rodape: [
        if (p['meu'] != true) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.local_offer_outlined, size: 18),
              label: const Text('Fazer oferta'),
              style: ElevatedButton.styleFrom(backgroundColor: CafeColors.caramel, foregroundColor: CafeColors.espresso),
              onPressed: () async {
                final ok = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => _FormOferta(pedido: p),
                );
                if (ok == true) onMudou();
              },
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Este pedido é seu.', style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
          ),
      ]),
    );
  }
}

class _FormOferta extends StatefulWidget {
  final Map<String, dynamic> pedido;
  const _FormOferta({required this.pedido});
  @override
  State<_FormOferta> createState() => _FormOfertaState();
}

class _FormOfertaState extends State<_FormOferta> {
  final _preco = TextEditingController();
  final _qtd = TextEditingController();
  final _msg = TextEditingController();
  List<CafeModel> _lotes = [];
  String? _loteId;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _qtd.text = '${widget.pedido['quantidade_sacas'] ?? ''}';
    final u = context.read<AppState>().usuario;
    if (u != null) {
      ApiService.getCafes(usuarioId: u.id, status: 'ativo').then((l) {
        if (mounted) setState(() => _lotes = l);
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _preco.dispose();
    _qtd.dispose();
    _msg.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final preco = _numero(_preco.text);
    final qtd = int.tryParse(_qtd.text.trim());
    if (preco == null || qtd == null || qtd <= 0) {
      mostrarErro(context, 'Informe o preço por saca e a quantidade.');
      return;
    }
    setState(() => _enviando = true);
    try {
      await ApiService.ofertarPedido(widget.pedido['id'], {
        'preco_saca': preco,
        'quantidade_sacas': qtd,
        if (_loteId != null) 'cafe_id': _loteId,
        if (_msg.text.trim().isNotEmpty) 'mensagem': _msg.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oferta enviada ao comprador')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        mostrarErro(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entrada = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Oferta para: ${widget.pedido['quantidade_sacas']} sacas · ${_resumoPedido(widget.pedido)}',
            style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (_lotes.isNotEmpty) ...[
          DropdownButtonFormField<String?>(
            initialValue: _loteId,
            decoration: const InputDecoration(labelText: 'Qual lote seu? (opcional)'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Não vincular a um lote')),
              for (final l in _lotes)
                DropdownMenuItem<String?>(
                  value: l.id,
                  child: Text('${l.tipo} ${l.classificacao} · ${l.quantidade} sc${l.fazenda != null ? ' · ${l.fazenda}' : ''}',
                      overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) {
              setState(() => _loteId = v);
              final l = _lotes.where((x) => x.id == v).firstOrNull;
              if (l?.precoSaca != null && _preco.text.isEmpty) {
                _preco.text = l!.precoSaca!.toStringAsFixed(2).replaceAll('.', ',');
              }
            },
          ),
          const SizedBox(height: 10),
        ],
        Row(children: [
          Expanded(
            child: TextField(
              controller: _preco,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: entrada,
              decoration: const InputDecoration(labelText: 'Preço por saca', prefixText: r'R$ '),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: TextField(
              controller: _qtd,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Sacas'),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        TextField(
          controller: _msg,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Mensagem (opcional)', hintText: 'Ex.: retirada na fazenda, amostra disponível'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _enviando ? null : _enviar,
          child: _enviando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Enviar oferta'),
        ),
      ]),
    );
  }
}

// ── Aba: meus pedidos e as ofertas recebidas ───────────────────────────
class _AbaMeusPedidos extends StatelessWidget {
  final VoidCallback onMudou;
  const _AbaMeusPedidos({super.key, required this.onMudou});

  Future<void> _acao(BuildContext context, Future<void> Function() f, String ok) async {
    try {
      await f();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
      onMudou();
    } catch (e) {
      if (context.mounted) mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Lista(
      buscar: ApiService.getMeusPedidos,
      vazio: 'Você ainda não publicou pedidos de compra',
      item: (p) {
        final ofertas = ((p['ofertas'] as List?) ?? []).cast<Map<String, dynamic>>();
        return _cartaoPedido(p, rodape: [
          const Divider(height: 18),
          Text(ofertas.isEmpty ? 'Nenhuma oferta ainda' : '${ofertas.length} oferta(s)',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
          for (final o in ofertas) _ofertaRecebida(context, o),
          if (p['status'] == 'aberto')
            Wrap(spacing: 8, children: [
              TextButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Marcar atendido'),
                onPressed: () => _acao(context, () => ApiService.atualizarPedido(p['id'], 'atendido'), 'Pedido marcado como atendido'),
              ),
              TextButton.icon(
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Encerrar'),
                style: TextButton.styleFrom(foregroundColor: CafeColors.redAlert),
                onPressed: () => _acao(context, () => ApiService.atualizarPedido(p['id'], 'encerrado'), 'Pedido encerrado'),
              ),
            ]),
        ]);
      },
    );
  }

  Widget _ofertaRecebida(BuildContext context, Map<String, dynamic> o) {
    final v = (o['vendedor'] as Map?) ?? {};
    final cafe = o['cafe'] as Map?;
    final status = o['status'];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: CafeColors.milk, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${v['nome'] ?? 'Vendedor'}${v['cidade'] != null ? ' · ${v['cidade']}' : ''}',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        Text('${o['quantidade_sacas']} sacas a ${_brl.format(o['preco_saca'])} por saca',
            style: GoogleFonts.dmSans(fontSize: 13)),
        if (cafe != null)
          Text('Lote: ${cafe['tipo']} ${cafe['classificacao']}${cafe['fazenda'] != null ? ' · ${cafe['fazenda']}' : ''}',
              style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
        if (o['mensagem'] != null)
          Text('"${o['mensagem']}"', style: GoogleFonts.dmSans(fontSize: 12, fontStyle: FontStyle.italic)),
        if (status == 'enviada')
          Row(children: [
            TextButton(
              onPressed: () => _acao(context, () => ApiService.responderOferta(o['id'], 'aceita'), 'Oferta aceita. Combine os detalhes pelo chat.'),
              child: const Text('Aceitar'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: CafeColors.redAlert),
              onPressed: () => _acao(context, () => ApiService.responderOferta(o['id'], 'recusada'), 'Oferta recusada'),
              child: const Text('Recusar'),
            ),
          ])
        else
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(status == 'aceita' ? '✓ Aceita' : '✕ Recusada',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700,
                    color: status == 'aceita' ? CafeColors.greenOk : CafeColors.redAlert)),
          ),
      ]),
    );
  }
}

// ── Aba: ofertas que eu fiz ────────────────────────────────────────────
class _AbaMinhasOfertas extends StatelessWidget {
  const _AbaMinhasOfertas({super.key});

  @override
  Widget build(BuildContext context) {
    return _Lista(
      buscar: ApiService.getMinhasOfertas,
      vazio: 'Você ainda não fez ofertas',
      item: (o) {
        final p = (o['pedido'] as Map?)?.cast<String, dynamic>() ?? {};
        final status = o['status'];
        final cor = status == 'aceita' ? CafeColors.greenOk : status == 'recusada' ? CafeColors.redAlert : CafeColors.gold;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text('${o['quantidade_sacas']} sacas a ${_brl.format(o['preco_saca'])}'),
            subtitle: Text('Pedido: ${p['quantidade_sacas'] ?? '?'} sacas · ${_resumoPedido(p)}'
                '${(p['usuario'] as Map?)?['nome'] != null ? '\nComprador: ${(p['usuario'] as Map)['nome']}' : ''}'),
            isThreeLine: true,
            trailing: Text(status == 'aceita' ? 'Aceita' : status == 'recusada' ? 'Recusada' : 'Aguardando',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: cor)),
          ),
        );
      },
    );
  }
}

// ── Novo pedido ────────────────────────────────────────────────────────
class _NovoPedidoScreen extends StatefulWidget {
  const _NovoPedidoScreen();
  @override
  State<_NovoPedidoScreen> createState() => _NovoPedidoScreenState();
}

class _NovoPedidoScreenState extends State<_NovoPedidoScreen> {
  String _tipo = tiposCafe.first;
  String? _classificacao, _bebida, _regiao;
  final _qtd = TextEditingController();
  final _preco = TextEditingController();
  final _obs = TextEditingController();
  DateTime? _prazo;
  bool _enviando = false;

  @override
  void dispose() {
    _qtd.dispose();
    _preco.dispose();
    _obs.dispose();
    super.dispose();
  }

  Widget _drop(String rotulo, List<String> itens, String? valor, void Function(String?) f, {bool opcional = true}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String?>(
          initialValue: valor,
          decoration: InputDecoration(labelText: rotulo),
          items: [
            if (opcional) const DropdownMenuItem<String?>(value: null, child: Text('Qualquer')),
            for (final i in itens) DropdownMenuItem<String?>(value: i, child: Text(i)),
          ],
          onChanged: f,
        ),
      );

  Future<void> _publicar() async {
    final qtd = int.tryParse(_qtd.text.trim());
    if (qtd == null || qtd <= 0) {
      mostrarErro(context, 'Informe quantas sacas você procura.');
      return;
    }
    setState(() => _enviando = true);
    try {
      await ApiService.criarPedido({
        'tipo': _tipo,
        if (_classificacao != null) 'classificacao': _classificacao,
        if (_bebida != null) 'bebida': _bebida,
        if (_regiao != null) 'regiao': _regiao,
        'quantidade_sacas': qtd,
        if (_numero(_preco.text) != null) 'preco_maximo': _numero(_preco.text),
        if (_prazo != null) 'prazo': DateFormat('yyyy-MM-dd').format(_prazo!),
        if (_obs.text.trim().isNotEmpty) 'observacoes': _obs.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pedido publicado. Quem tem café parecido vai ser avisado.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        mostrarErro(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo pedido de compra')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Text('Diga o que você procura. Vendedores com café parecido recebem um aviso e mandam ofertas.',
                style: GoogleFonts.dmSans(fontSize: 13, color: CafeColors.lightRoast, height: 1.4)),
            const SizedBox(height: 16),
            _drop('Tipo de café', tiposCafe, _tipo, (v) => setState(() => _tipo = v ?? _tipo), opcional: false),
            _drop('Classificação', classificacoesCafe, _classificacao, (v) => setState(() => _classificacao = v)),
            _drop('Bebida', bebidasCafe, _bebida, (v) => setState(() => _bebida = v)),
            _drop('Região', regioesCafe, _regiao, (v) => setState(() => _regiao = v)),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _qtd,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Quantidade (sacas)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _preco,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  decoration: const InputDecoration(labelText: 'Pago até (por saca)', prefixText: r'R$ '),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.event_outlined),
              label: Text(_prazo == null ? 'Prazo (opcional)' : 'Prazo: ${_dataCurta.format(_prazo!)}'),
              onPressed: () async {
                final hoje = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  initialDate: _prazo ?? hoje.add(const Duration(days: 30)),
                  firstDate: hoje,
                  lastDate: DateTime(hoje.year + 2),
                );
                if (d != null) setState(() => _prazo = d);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _obs,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Observações (opcional)', hintText: 'Ex.: peneira 16 acima, retirada no Sul de Minas'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _enviando ? null : _publicar,
              child: _enviando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Publicar pedido'),
            ),
          ]),
        ),
      ),
    );
  }
}
