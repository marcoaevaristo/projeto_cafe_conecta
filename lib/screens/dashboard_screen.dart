// lib/screens/dashboard_screen.dart — v3: Dashboard analítico
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/cafe_model.dart';
import '../services/app_state.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../widgets/cafe_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _stats = {};
  List<HistoricoPrecoModel> _historico = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final u = context.read<AppState>().usuario;
    if (u == null) return;
    final stats = await DatabaseService.getDashboard(u.id!);
    final hist = await DatabaseService.getHistoricoPrecos();
    setState(() {
      _stats = stats;
      _historico = hist;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppState>().usuario;
    if (u == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Dashboard')),
          body: const EmptyState(
              icon: Icons.dashboard_outlined,
              titulo: 'Faça login para ver o dashboard'));
    }
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: CafeColors.espresso,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [
                  CafeColors.espresso,
                  CafeColors.darkRoast,
                  CafeColors.mediumRoast
                ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Dashboard',
                          style: GoogleFonts.playfairDisplay(
                              color: CafeColors.gold,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      Text('Olá, ${u.empresa ?? u.nome}',
                          style: GoogleFonts.dmSans(
                              color: CafeColors.cream.withValues(alpha: 0.65),
                              fontSize: 12)),
                    ]),
              ),
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _carregar,
                child: ListView(padding: const EdgeInsets.all(14), children: [
                  // KPIs
                  GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.6,
                      children: [
                        const _KpiCard(
                            icon: '☕',
                            label: 'Lotes Ativos',
                            value: '${_stats['lotes_ativos'] ?? 0}',
                            delta: '+12 este mês',
                            color: CafeColors.caramel),
                        const _KpiCard(
                            icon: '👁',
                            label: 'Visualizações',
                            value: '${_stats['visualizacoes'] ?? 0}',
                            delta: '+18% este mês',
                            color: CafeColors.blue),
                        const _KpiCard(
                            icon: '📋',
                            label: 'Propostas',
                            value: '${_stats['propostas_recebidas'] ?? 0}',
                            delta: '+3 esta semana',
                            color: CafeColors.gold),
                        const _KpiCard(
                            icon: '🤝',
                            label: 'Negócios',
                            value: '${_stats['negocios_fechados'] ?? 0}',
                            delta: '+2 este mês',
                            color: CafeColors.greenOk),
                      ]),
                  const SizedBox(height: 14),

                  // Avaliação média
                  if ((_stats['media_avaliacao'] ?? 0) > 0)
                    Card(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Sua reputação',
                                        style: GoogleFonts.playfairDisplay(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: CafeColors.darkRoast)),
                                    const SizedBox(height: 4),
                                    Row(
                                        children: List.generate(
                                            5,
                                            (i) => Icon(
                                                i <
                                                        (_stats['media_avaliacao']
                                                                as num)
                                                            .round()
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: CafeColors.gold,
                                                size: 20))),
                                  ]),
                              const SizedBox(width: 16),
                              Text(
                                  (_stats['media_avaliacao'] as num)
                                      .toStringAsFixed(1),
                                  style: GoogleFonts.playfairDisplay(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      color: CafeColors.gold)),
                              const Spacer(),
                              Icon(Icons.verified,
                                  color: CafeColors.blue, size: 28),
                            ]))),
                  const SizedBox(height: 14),

                  // Gráfico histórico
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Evolução de Preços — Sul de Minas',
                                    style: GoogleFonts.playfairDisplay(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: CafeColors.darkRoast)),
                                Text('Arábica Tipo 6 · últimos 6 meses',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: CafeColors.lightRoast)),
                                const SizedBox(height: 14),
                                SizedBox(
                                    height: 150,
                                    child: _historico.isEmpty
                                        ? const Center(
                                            child: CircularProgressIndicator())
                                        : LineChart(_buildChart())),
                              ]))),
                  const SizedBox(height: 14),

                  // Funil de conversão
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Funil de Conversão',
                                    style: GoogleFonts.playfairDisplay(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: CafeColors.darkRoast)),
                                const SizedBox(height: 14),
                                _FunnelBar(
                                    label: 'Visualizações',
                                    value: _stats['visualizacoes'] ?? 0,
                                    max: _stats['visualizacoes'] ?? 1,
                                    color: CafeColors.caramel),
                                const SizedBox(height: 8),
                                _FunnelBar(
                                    label: 'Propostas recebidas',
                                    value: _stats['propostas_recebidas'] ?? 0,
                                    max: _stats['visualizacoes'] ?? 1,
                                    color: CafeColors.gold),
                                const SizedBox(height: 8),
                                _FunnelBar(
                                    label: 'Negócios fechados',
                                    value: _stats['negocios_fechados'] ?? 0,
                                    max: _stats['visualizacoes'] ?? 1,
                                    color: CafeColors.greenOk),
                              ]))),
                  const SizedBox(height: 14),

                  // Distribuição por tipo
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mercado por Tipo de Café',
                                    style: GoogleFonts.playfairDisplay(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: CafeColors.darkRoast)),
                                const SizedBox(height: 14),
                                Row(children: [
                                  SizedBox(
                                      height: 120,
                                      width: 120,
                                      child: PieChart(PieChartData(
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 30,
                                        sections: [
                                          PieChartSectionData(
                                              value: 65,
                                              color: CafeColors.caramel,
                                              title: '65%',
                                              radius: 30,
                                              titleStyle: GoogleFonts.dmSans(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white)),
                                          PieChartSectionData(
                                              value: 25,
                                              color: CafeColors.greenOk,
                                              title: '25%',
                                              radius: 30,
                                              titleStyle: GoogleFonts.dmSans(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white)),
                                          PieChartSectionData(
                                              value: 10,
                                              color: CafeColors.blue,
                                              title: '10%',
                                              radius: 30,
                                              titleStyle: GoogleFonts.dmSans(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white)),
                                        ],
                                      ))),
                                  const SizedBox(width: 16),
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _LegendItem(
                                            color: CafeColors.caramel,
                                            label: 'Arábica',
                                            pct: '65%'),
                                        const SizedBox(height: 8),
                                        _LegendItem(
                                            color: CafeColors.greenOk,
                                            label: 'Conilon',
                                            pct: '25%'),
                                        const SizedBox(height: 8),
                                        _LegendItem(
                                            color: CafeColors.blue,
                                            label: 'Robusta',
                                            pct: '10%'),
                                      ]),
                                ]),
                              ]))),
                  const SizedBox(height: 20),
                ])),
      ),
    );
  }

  LineChartData _buildChart() {
    final sulData = _historico.where((h) => h.regiao == 'Sul de Minas').toList()
      ..sort((a, b) => a.mes.compareTo(b.mes));
    final spots = sulData
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.precoMedio))
        .toList();
    final meses = sulData.map((h) {
      final p = h.mes.split('-');
      const n = [
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
      return n[int.parse(p[1])];
    }).toList();
    return LineChartData(
      gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
              color: CafeColors.lightRoast.withValues(alpha: 0.08),
              strokeWidth: 1)),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (v, _) => Text(
                    'R\$${(v / 1000).toStringAsFixed(1)}k',
                    style: GoogleFonts.dmSans(
                        fontSize: 9, color: CafeColors.lightRoast)))),
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  return i >= 0 && i < meses.length
                      ? Text(meses[i],
                          style: GoogleFonts.dmSans(
                              fontSize: 9, color: CafeColors.lightRoast))
                      : const SizedBox();
                })),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: CafeColors.caramel,
          barWidth: 2.5,
          dotData: FlDotData(
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color: CafeColors.caramel,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white)),
          belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(colors: [
                CafeColors.caramel.withValues(alpha: 0.2),
                CafeColors.caramel.withValues(alpha: 0.0)
              ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        )
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String icon, label, value, delta;
  final Color color;
  const _KpiCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.delta,
      required this.color});
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8)),
                          child: Center(
                              child: Text(icon,
                                  style: const TextStyle(fontSize: 15)))),
                    ]),
                Text(value,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: CafeColors.darkRoast)),
                Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: CafeColors.lightRoast)),
                Text(delta,
                    style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: CafeColors.greenOk)),
              ])));
}

class _FunnelBar extends StatelessWidget {
  final String label;
  final int value, max;
  final Color color;
  const _FunnelBar(
      {required this.label,
      required this.value,
      required this.max,
      required this.color});
  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? value / max : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style:
                GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
        Text('$value',
            style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CafeColors.darkRoast)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          )),
    ]);
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label, pct;
  const _LegendItem(
      {required this.color, required this.label, required this.pct});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style:
                GoogleFonts.dmSans(fontSize: 12, color: CafeColors.darkRoast)),
        const SizedBox(width: 4),
        Text(pct,
            style:
                GoogleFonts.dmSans(fontSize: 11, color: CafeColors.lightRoast)),
      ]);
}
