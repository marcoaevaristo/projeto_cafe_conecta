// lib/screens/historico_precos_screen.dart — Melhoria 2
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cafe_model.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';

class HistoricoPrecosScreen extends StatefulWidget {
  const HistoricoPrecosScreen({super.key});
  @override
  State<HistoricoPrecosScreen> createState() => _HistoricoPrecosScreenState();
}

class _HistoricoPrecosScreenState extends State<HistoricoPrecosScreen> {
  List<HistoricoPrecoModel> _dados = [];
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
    final d = await DatabaseService.getHistoricoPrecos();
    setState(() => _dados = d);
  }

  List<HistoricoPrecoModel> get _filtrados {
    final limit = _periodo == '1m'
        ? 1
        : _periodo == '3m'
            ? 3
            : 6;
    final meses = _dados.map((d) => d.mes).toSet().toList()..sort();
    final mesesFiltro =
        meses.length > limit ? meses.sublist(meses.length - limit) : meses;
    return _dados.where((d) => mesesFiltro.contains(d.mes)).toList();
  }

  List<FlSpot> _spots(String regiao) {
    final meses = _filtrados.map((d) => d.mes).toSet().toList()..sort();
    return meses.asMap().entries.map((e) {
      final item = _filtrados.firstWhere(
          (d) => d.mes == e.value && d.regiao == regiao,
          orElse: () => HistoricoPrecoModel(
              tipoCafe: '', regiao: regiao, precoMedio: 0, mes: e.value));
      return FlSpot(e.key.toDouble(), item.precoMedio);
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

  double get _variacaoSul {
    final sul = _filtrados.where((d) => d.regiao == 'Sul de Minas').toList()
      ..sort((a, b) => a.mes.compareTo(b.mes));
    if (sul.length < 2) return 0;
    return ((sul.last.precoMedio - sul.first.precoMedio) /
            sul.first.precoMedio) *
        100;
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
            _SumCard(
                label: 'Sul de Minas',
                value:
                    '${_variacaoSul >= 0 ? '+' : ''}${_variacaoSul.toStringAsFixed(1)}%',
                isUp: _variacaoSul >= 0,
                period: '30d'),
            const SizedBox(width: 10),
            _SumCard(
                label: 'Cerrado Min.',
                value: '+5,1%',
                isUp: true,
                period: '30d'),
            const SizedBox(width: 10),
            _SumCard(
                label: 'Zona da Mata',
                value: '-2,4%',
                isUp: false,
                period: '30d'),
          ]),
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
                                  children: ['1m', '3m', '6m']
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
                            child: _dados.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator())
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
  final bool isUp;
  const _SumCard(
      {required this.label,
      required this.value,
      required this.isUp,
      required this.period});
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
                  color: isUp ? CafeColors.greenOk : CafeColors.redAlert)),
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
