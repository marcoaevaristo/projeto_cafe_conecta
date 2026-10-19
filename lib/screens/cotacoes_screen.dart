// lib/screens/cotacoes_screen.dart
// Índice Café Conecta (preços reais dos lotes do app), café na bolsa e dólar ao
// vivo pelos widgets gratuitos do TradingView, dólar PTAX oficial do Banco
// Central e atalhos para as fontes oficiais.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/cotacoes_service.dart';
import '../utils/theme.dart';
import '../widgets/tradingview/tradingview_widget.dart';

// Configuração comum dos widgets do TradingView
Map<String, dynamic> _overview(List<List<String>> simbolos) => {
      'symbols': simbolos,
      'chartOnly': false,
      'width': '100%',
      'height': '100%',
      'locale': 'br',
      'colorTheme': 'light',
      'autosize': true,
      'isTransparent': true,
      'showVolume': false,
      'hideSymbolLogo': true,
      'scalePosition': 'right',
      'scaleMode': 'Normal',
      'fontSize': '10',
      'valuesTracking': '1',
      'changeMode': 'price-and-percent',
      'chartType': 'area',
      'lineColor': 'rgba(196, 134, 58, 1)',
      'topColor': 'rgba(196, 134, 58, 0.30)',
      'bottomColor': 'rgba(196, 134, 58, 0)',
      'lineWidth': 2,
      'dateRanges': ['1d|1', '1m|30', '3m|60', '12m|1D', '60m|1W'],
    };

class _Fonte {
  final String titulo, descricao, site, url;
  final IconData icone;
  const _Fonte(this.titulo, this.descricao, this.site, this.url, this.icone);
}

const _bolsa = [
  _Fonte('Café Arábica — Contrato C (Nova York)',
      'Bolsa ICE, em centavos de dólar por libra-peso. Referência mundial do arábica.',
      'br.investing.com', 'https://br.investing.com/commodities/us-coffee-c', Icons.trending_up),
  _Fonte('Café Robusta (Londres)',
      'Bolsa ICE Europa, em dólares por tonelada. Referência do conilon/robusta.',
      'br.investing.com', 'https://br.investing.com/commodities/london-coffee', Icons.trending_up),
];

const _mercadoFisico = [
  _Fonte('Indicador CEPEA/ESALQ',
      'Preço da saca de 60 kg no mercado físico brasileiro, arábica e robusta.',
      'cepea.org.br', 'https://www.cepea.org.br/br/indicador/cafe.aspx', Icons.agriculture_outlined),
  _Fonte('Notícias Agrícolas — cotações do café',
      'Preços por praça (Sul de Minas, Cerrado, Mogiana…) e bolsas, atualizados ao longo do dia.',
      'noticiasagricolas.com.br', 'https://www.noticiasagricolas.com.br/cotacoes/cafe',
      Icons.place_outlined),
];

class CotacoesScreen extends StatefulWidget {
  const CotacoesScreen({super.key});

  @override
  State<CotacoesScreen> createState() => _CotacoesScreenState();
}

class _CotacoesScreenState extends State<CotacoesScreen> {
  DolarItem? _dolar;
  bool _carregando = true;
  bool _falhou = false;
  Map<String, dynamic>? _indice;
  bool _indiceFalhou = false;

  final _reais = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 4);
  final _dataHora = DateFormat('dd/MM/yyyy HH:mm');
  final _saca = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 2);
  final _int = NumberFormat.decimalPattern('pt_BR');

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _falhou = false;
    });
    _carregarIndice();
    try {
      final atual = await CotacoesService.fetchAtual();
      if (!mounted) return;
      setState(() {
        _dolar = atual.dolar;
        _falhou = atual.dolar == null;
        _carregando = false;
      });
    } catch (_) {
      if (mounted) setState(() { _falhou = true; _carregando = false; });
    }
  }

  Future<void> _carregarIndice() async {
    try {
      final i = await CotacoesService.fetchIndice();
      if (mounted) setState(() { _indice = i; _indiceFalhou = false; });
    } catch (_) {
      if (mounted) setState(() => _indiceFalhou = true);
    }
  }

  Future<void> _abrir(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cotações'), actions: [
        IconButton(onPressed: _carregar, icon: const Icon(Icons.refresh), tooltip: 'Atualizar'),
      ]),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _titulo('Índice Café Conecta — ao vivo'),
          _secaoIndice(),
          _titulo('Café na bolsa'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: TradingViewWidget(
                script: 'embed-widget-symbol-overview.js',
                altura: 380,
                linkUrl: 'https://br.tradingview.com/symbols/BMFBOVESPA-ICF1!/',
                config: _overview(const [
                  ['Arábica B3', 'BMFBOVESPA:ICF1!|1M'],
                  ['Arábica NY (ref.)', 'PEPPERSTONE:COFFEE|1M'],
                ]),
              ),
            ),
          ),
          _nota('Arábica B3: contrato futuro em US\$ por saca de 60 kg, com atraso de cerca de 15 min. '
              'Arábica NY (ref.): contrato à vista da corretora Pepperstone, que acompanha o Contrato C '
              'de Nova York, em centavos de dólar por libra-peso. O contrato oficial da bolsa ICE, o '
              'robusta de Londres e os preços por região abrem nos links abaixo.'),
          _titulo('Dólar'),
          _cardDolar(),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: TradingViewWidget(
                script: 'embed-widget-symbol-overview.js',
                altura: 300,
                linkUrl: 'https://br.tradingview.com/symbols/USDBRL/',
                config: _overview(const [
                  ['Dólar ao vivo', 'FX_IDC:USDBRL|1D'],
                ]),
              ),
            ),
          ),
          _nota('O PTAX é a taxa oficial do Banco Central, usada em contratos. O gráfico mostra o '
              'dólar comercial negociado agora, em tempo real.'),
          _titulo('Fontes oficiais'),
          for (final f in _bolsa) _cardFonte(f),
          for (final f in _mercadoFisico) _cardFonte(f),
          const SizedBox(height: 12),
          Text(
            'O Índice Café Conecta usa só os lotes anunciados e os negócios fechados aqui no app. '
            'Os outros preços vêm das fontes indicadas em cada quadro.',
            style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast, height: 1.4),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _nota(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
        child: Text(t,
            style: GoogleFonts.dmSans(
                fontSize: 11, color: CafeColors.lightRoast, height: 1.4)),
      );

  // ── Índice Café Conecta ─────────────────────────────────────────────
  Widget _secaoIndice() {
    final i = _indice;
    if (i == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _indiceFalhou
              ? Text('Não foi possível carregar o índice agora. Puxe para baixo para tentar de novo.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: CafeColors.lightRoast))
              : const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final porTipo = (i['por_tipo'] as List? ?? []).cast<Map<String, dynamic>>();
    final ofertas = (i['ofertas'] as List? ?? []).cast<Map<String, dynamic>>();
    final negocios = (i['negocios'] as List? ?? []).cast<Map<String, dynamic>>();
    final atualizado = DateTime.tryParse(i['atualizado_em'] ?? '')?.toLocal();

    if (porTipo.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
              'Ainda não há lotes ativos anunciados. Assim que houver, o preço médio aparece aqui na hora.',
              style: GoogleFonts.dmSans(fontSize: 13, color: CafeColors.lightRoast)),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final t in porTipo) _cardTipo(t),
      ]),
      if (ofertas.isNotEmpty) ...[
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Preço pedido por região',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
              const SizedBox(height: 4),
              for (final o in ofertas.take(10))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${o['regiao']} · ${o['tipo']}',
                            style: GoogleFonts.dmSans(fontSize: 13, color: CafeColors.darkRoast)),
                        Text('${o['quantidade']} ${o['quantidade'] == 1 ? 'lote' : 'lotes'} · '
                            '${_int.format(o['sacas'] ?? 0)} sacas',
                            style: GoogleFonts.dmSans(fontSize: 11, color: CafeColors.lightRoast)),
                      ]),
                    ),
                    Text(_saca.format(o['preco_medio']),
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: CafeColors.mediumRoast)),
                  ]),
                ),
            ]),
          ),
        ),
      ],
      if (negocios.isNotEmpty) ...[
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Negócios fechados (últimos ${i['dias_negocios']} dias)',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
              for (final n in negocios)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Expanded(
                      child: Text('${n['tipo']} · ${n['quantidade']} negócios',
                          style: GoogleFonts.dmSans(fontSize: 13)),
                    ),
                    Text(_saca.format(n['preco_medio']),
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: CafeColors.greenOk)),
                  ]),
                ),
            ]),
          ),
        ),
      ],
      _nota('Média por saca de 60 kg, ponderada pelo volume, dos ${i['total_lotes']} lotes ativos'
          '${atualizado != null ? ' · atualizado às ${DateFormat('HH:mm').format(atualizado)}' : ''}. '
          'Negócios fechados só aparecem com pelo menos ${i['min_negocios']} por tipo.'),
    ]);
  }

  Widget _cardTipo(Map<String, dynamic> t) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 150, maxWidth: 260),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${t['tipo']}'.toUpperCase(),
                  style: GoogleFonts.dmSans(
                      fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w700, color: CafeColors.caramel)),
              const SizedBox(height: 4),
              Text(_saca.format(t['preco_medio']),
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 22, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
              Text('média por saca',
                  style: GoogleFonts.dmSans(fontSize: 11, color: CafeColors.lightRoast)),
              const SizedBox(height: 6),
              Text('${_saca.format(t['preco_min'])} – ${_saca.format(t['preco_max'])}',
                  style: GoogleFonts.dmSans(fontSize: 11, color: CafeColors.mediumRoast)),
              Text('${t['quantidade']} ${t['quantidade'] == 1 ? 'lote' : 'lotes'} · ${_int.format(t['sacas'] ?? 0)} sacas',
                  style: GoogleFonts.dmSans(fontSize: 11, color: CafeColors.lightRoast)),
            ]),
          ),
        ),
      );

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 22, 2, 8),
        child: Text(t,
            style: GoogleFonts.playfairDisplay(
                fontSize: 17, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
      );

  Widget _cardDolar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [CafeColors.espresso, CafeColors.mediumRoast],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: _carregando
          ? const SizedBox(
              height: 70, child: Center(child: CircularProgressIndicator(color: CafeColors.gold)))
          : _falhou || _dolar == null
              ? Text('Dólar indisponível no momento. Puxe para baixo para tentar de novo.',
                  style: GoogleFonts.dmSans(color: CafeColors.cream))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('DÓLAR COMERCIAL (PTAX)',
                      style: GoogleFonts.dmSans(
                          color: CafeColors.caramel,
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(child: _valorDolar('Venda', _dolar!.cotacaoVenda, destaque: true)),
                    Expanded(child: _valorDolar('Compra', _dolar!.cotacaoCompra)),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                      '${_dolar!.fonte} · ${_dataHora.format(_dolar!.dataReferencia.toLocal())}',
                      style: GoogleFonts.dmSans(
                          color: CafeColors.cream.withValues(alpha: 0.7), fontSize: 11)),
                ]),
    );
  }

  Widget _valorDolar(String rotulo, double valor, {bool destaque = false}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo,
              style: GoogleFonts.dmSans(
                  color: CafeColors.cream.withValues(alpha: 0.7), fontSize: 11)),
          Text(_reais.format(valor),
              style: GoogleFonts.playfairDisplay(
                  color: destaque ? CafeColors.gold : CafeColors.cream,
                  fontSize: destaque ? 26 : 18,
                  fontWeight: FontWeight.w700)),
        ],
      );

  Widget _cardFonte(_Fonte f) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _abrir(f.url),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: CafeColors.caramel.withValues(alpha: 0.15),
                child: Icon(f.icone, color: CafeColors.caramel),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f.titulo,
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700, fontSize: 14, color: CafeColors.darkRoast)),
                  const SizedBox(height: 3),
                  Text(f.descricao,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: CafeColors.lightRoast, height: 1.35)),
                  const SizedBox(height: 4),
                  Text(f.site,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: CafeColors.caramel, fontWeight: FontWeight.w600)),
                ]),
              ),
              const Icon(Icons.open_in_new, size: 18, color: CafeColors.lightRoast),
            ]),
          ),
        ),
      );
}
