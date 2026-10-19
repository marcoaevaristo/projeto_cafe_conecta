// lib/screens/cotacoes_screen.dart
// Dólar oficial (PTAX do Banco Central) dentro do app e atalhos para as fontes
// de preço do café ao vivo. Os preços do café abrem no site de cada fonte:
// republicar cotações de bolsa dentro do app exigiria licença dos dados.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/cotacoes_service.dart';
import '../utils/theme.dart';

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

  final _reais = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 4);
  final _dataHora = DateFormat('dd/MM/yyyy HH:mm');

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
          _cardDolar(),
          _titulo('Café na bolsa — ao vivo'),
          for (final f in _bolsa) _cardFonte(f),
          _titulo('Mercado físico no Brasil'),
          for (final f in _mercadoFisico) _cardFonte(f),
          const SizedBox(height: 12),
          Text(
            'Os preços do café abrem direto no site de cada fonte, sempre atualizados. '
            'O dólar é a cotação oficial PTAX do Banco Central.',
            style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast, height: 1.4),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

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
