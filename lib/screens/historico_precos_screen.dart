// lib/screens/historico_precos_screen.dart — Melhoria 2
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cafe_model.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/theme.dart';

class HistoricoPrecosScreen extends StatefulWidget {
  const HistoricoPrecosScreen({super.key});
  @override
  State<HistoricoPrecosScreen> createState() => _HistoricoPrecosScreenState();
}

class _HistoricoPrecosScreenState extends State<HistoricoPrecosScreen> {
  List<HistoricoPrecoModel> _dados = [];
  bool _carregado = false;
  String _periodo = '6m';

  static const regioes = ['Sul de Minas', 'Cerrado Mineiro', 'Zona da Mata'];
  static const cores = [
    CafeColors.caramel,
    CafeColors.greenOk,
    CafeColors.blue
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    List<HistoricoPrecoModel> d = [];
    try {
      d = await ApiService.getHistoricoPrecos();
    } catch (_) {}
    if (!mounted) return;
    // As regiões do gráfico são de arábica: não mistura com conilon/robusta.
    setState(() {
      _dados = d.where((h) => h.tipoCafe == 'Arábica').toList();
      _carregado = true;
    });
  }

  // Períodos liberados por plano (tier 1=Básico, 2=Profissional, 3=Premium)
  List<String> _periodosDoPlano(int tier) => tier >= 3
      ? const ['1m', '3m', '6m', '12m']
      : tier == 2
          ? const ['1m', '3m', '6m']
          : const ['1m', '3m'];

  List<HistoricoPrecoModel> get _filtrados {
    final permitidos =
        _periodosDoPlano(context.read<AppState>().planoTier);
    if (!permitidos.contains(_periodo)) _periodo = permitidos.last;
    final limit = int.parse(_periodo.replaceAll('m', ''));
    final meses = _dados.map((d) => d.mes).toSet().toList()..sort();
    final mesesFiltro =
        meses.length > limit ? meses.sublist(meses.length - limit) : meses;
    return _dados.where((d) => mesesFiltro.contains(d.mes)).toList();
  }

  List<FlSpot> _spots(String regiao) {
    final meses = _filtrados.map((d) => d.mes).toSet().toList()..sort();
    return meses.asMap().entries.map((e) {
      final item = _filtrados
          .where((d) => d.mes == e.value && d.regiao == regiao)
          .firstOrNull;
      // mês sem lote nessa região: deixa um buraco em vez de cair para zero
      return item == null
          ? FlSpot.nullSpot
          : FlSpot(e.key.toDouble(), item.precoMedio);
    }).toList();
  }

  List<String> get _labels {
    final meses = _filtrados.map((d) => d.mes).toSet().toList()..sort();
    return meses.map((m) {
      final parts = m.split('-');
      const nomes = [
        '',
        'Jan',
        'Fev',
        'Mar',
        'Abr',
        'Mai',
        'Jun',
        'Jul',
        'Ago',
        'Set',
        'Out',
        'Nov',
        'Dez'
      ];
      return nomes[int.parse(parts[1])];
    }).toList();
  }

  // Variação do primeiro ao último mês com lotes na região (null = sem dados)
  double? _variacao(String regiao) {
    final r = _filtrados.where((d) => d.regiao == regiao).toList()
      ..sort((a, b) => a.mes.compareTo(b.mes));
    if (r.length < 2 || r.first.precoMedio == 0) return null;
    return ((r.last.precoMedio - r.first.precoMedio) / r.first.precoMedio) *
        100;
  }

  _SumCard _cardRegiao(String regiao, String rotulo) {
    final v = _variacao(regiao);
    return _SumCard(
        label: rotulo,
        value: v == null
            ? '—'
            : '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1).replaceAll('.', ',')}%',
        isUp: v == null || v >= 0,
        neutro: v == null,
        period: _periodo);
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels;
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Preços')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Resumo cards
          Row(children: [
            _cardRegiao('Sul de Minas', 'Sul de Minas'),
            const SizedBox(width: 10),
            _cardRegiao('Cerrado Mineiro', 'Cerrado Min.'),
            const SizedBox(width: 10),
            _cardRegiao('Zona da Mata', 'Zona da Mata'),
          ]),
          const SizedBox(height: 8),
          Text(
              'Preço médio pedido nos lotes de Arábica anunciados no Café Conecta, por mês de anúncio.',
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: CafeColors.lightRoast)),
          const SizedBox(height: 16),
          // Chart card
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Evolução por Região',
                                        style: GoogleFonts.playfairDisplay(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: CafeColors.darkRoast)),
                                    Text('Preço médio por saca (R\$)',
                                        style: GoogleFonts.dmSans(
                                            fontSize: 11,
                                            color: CafeColors.lightRoast)),
                                  ]),
                              Row(
                                  children: _periodosDoPlano(context
                                          .watch<AppState>()
                                          .planoTier)
                                      .map((p) => GestureDetector(
                                            onTap: () =>
                                                setState(() => _periodo = p),
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                  left: 4),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                  color: _periodo == p
                                                      ? CafeColors.caramel
                                                      : Colors.transparent,
                                                  border: Border.all(
                                                      color: _periodo == p
                                                          ? CafeColors.caramel
                                                          : CafeColors
                                                              .lightRoast
                                                              .withValues(
                                                                  alpha: 0.3)),
                                                  borderRadius:
                                                      BorderRadius.circular(6)),
                                              child: Text(p.toUpperCase(),
                                                  style: GoogleFonts.dmSans(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: _periodo == p
                                                          ? CafeColors.espresso
                                                          : CafeColors
                                                              .lightRoast)),
                                            ),
                                          ))
                                      .toList()),
                            ]),
                        const SizedBox(height: 16),
                        SizedBox(
                            height: 200,
                            child: !_carregado
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : _dados.isEmpty
                                ? Center(
                                    child: Text(
                                        'Ainda não há lotes de Arábica anunciados nos últimos meses.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: CafeColors.lightRoast)))
                                : LineChart(LineChartData(
                                    gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        getDrawingHorizontalLine: (_) => FlLine(
                                            color: CafeColors.lightRoast
                                                .withValues(alpha: 0.1),
                                            strokeWidth: 1)),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 52,
                                              getTitlesWidget: (v, _) => Text(
                                                  'R\$${(v / 1000).toStringAsFixed(1)}k',
                                                  style: GoogleFonts.dmSans(
                                                      fontSize: 9,
                                                      color: CafeColors
                                                          .lightRoast)))),
                                      bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 22,
                                              getTitlesWidget: (v, _) {
                                                final idx = v.toInt();
                                                return idx >= 0 &&
                                                        idx < labels.length
                                                    ? Text(labels[idx],
                                                        style: GoogleFonts.dmSans(
                                                            fontSize: 9,
                                                            color: CafeColors
                                                                .lightRoast))
                                                    : const SizedBox();
                                              })),
                                      topTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: regioes
                                        .asMap()
                                        .entries
                                        .map((e) => LineChartBarData(
                                              spots: _spots(e.value),
                                              isCurved: true,
                                              color: cores[e.key],
                                              barWidth: 2.5,
                                              dotData: FlDotData(
                                                  getDotPainter: (_, __, ___,
                                                          ____) =>
                                                      FlDotCirclePainter(
                                                          radius: 3,
                                                          color: cores[e.key],
                                                          strokeWidth: 1.5,
                                                          strokeColor:
                                                              Colors.white)),
                                              belowBarData: BarAreaData(
                                                  show: true,
                                                  color: cores[e.key]
                                                      .withValues(alpha: 0.07)),
                                            ))
                                        .toList(),
                                  ))),
                        const SizedBox(height: 12),
                        Wrap(
                            spacing: 12,
                            children: regioes
                                .asMap()
                                .entries
                                .map((e) => Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                  color: cores[e.key],
                                                  shape: BoxShape.circle)),
                                          const SizedBox(width: 4),
                                          Text(e.value,
                                              style: GoogleFonts.dmSans(
                                                  fontSize: 11,
                                                  color:
                                                      CafeColors.lightRoast)),
                                        ]))
                                .toList()),
                      ]))),
        ]),
      ),
    );
  }
}

class _SumCard extends StatelessWidget {
  final String label, value, period;
  final bool isUp, neutro;
  const _SumCard(
      {required this.label,
      required this.value,
      required this.isUp,
      required this.period,
      this.neutro = false});
  @override
  Widget build(BuildContext context) => Expanded(
          child: Card(
              child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(children: [
          Text(value,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: neutro
                      ? CafeColors.lightRoast
                      : isUp
                          ? CafeColors.greenOk
                          : CafeColors.redAlert)),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 10, color: CafeColors.lightRoast),
              textAlign: TextAlign.center),
          Text(period,
              style: GoogleFonts.dmSans(
                  fontSize: 9,
                  color: CafeColors.lightRoast.withValues(alpha: 0.6))),
        ]),
      )));
}
