// lib/screens/cotacoes_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/cotacoes_service.dart';
import '../utils/theme.dart';
import '../widgets/cafe_card.dart';

class CotacoesScreen extends StatefulWidget {
  const CotacoesScreen({super.key});

  @override
  State<CotacoesScreen> createState() => _CotacoesScreenState();
}

class _CotacoesScreenState extends State<CotacoesScreen> {
  CotacoesAtual? _atual;
  List<HistoricoPonto> _historico = [];
  String _fonteGrafico = 'cepea';
  String _tipoGrafico = 'arabica';
  bool _loading = true;
  String? _erro;

  final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _usd = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  final _dataFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final atual = await CotacoesService.fetchAtual();
      final hist = await CotacoesService.fetchHistorico(
        fonte: _fonteGrafico,
        tipo: _tipoGrafico,
        dias: 30,
      );
      if (!mounted) return;
      setState(() {
        _atual = atual;
        _historico = hist;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _trocarGrafico(String fonte, String tipo) async {
    setState(() {
      _fonteGrafico = fonte;
      _tipoGrafico = tipo;
    });
    try {
      final hist = await CotacoesService.fetchHistorico(
        fonte: fonte,
        tipo: tipo,
        dias: 30,
      );
      if (!mounted) return;
      setState(() => _historico = hist);
    } catch (_) {}
  }

  List<FlSpot> get _spots => _historico
      .asMap()
      .entries
      .map((e) => FlSpot(e.key.toDouble(), e.value.preco))
      .toList();

  String _fmtVar(double? v) {
    if (v == null) return '—';
    return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotações de Mercado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _carregar,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? EmptyState(
                  icon: Icons.cloud_off_outlined,
                  titulo: 'Não foi possível carregar cotações',
                  subtitulo:
                      'Verifique se a API está rodando (docker compose up).\n$_erro',
                  action: ElevatedButton(
                    onPressed: _carregar,
                    child: const Text('Tentar novamente'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_atual != null)
                          Text(
                            'Atualizado em ${_dataFmt.format(_atual!.atualizadoEm.toLocal())}',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: CafeColors.lightRoast,
                            ),
                          ),
                        const SizedBox(height: 12),
                        _buildResumoCards(),
                        const SizedBox(height: 16),
                        _buildGrafico(),
                        const SizedBox(height: 16),
                        _buildSecao('CEPEA / ESALQ', _atual?.cepea ?? [], true),
                        const SizedBox(height: 12),
                        _buildSecao(
                            'Notícias Agrícolas', _atual?.noticias ?? [], true),
                        const SizedBox(height: 12),
                        _buildDolarCard(),
                        const SizedBox(height: 12),
                        _buildB3Section(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildResumoCards() {
    final arabicaList = _atual?.cepea
            .where((c) => c.tipo.toLowerCase().contains('arab'))
            .toList() ??
        [];
    final conilonList = _atual?.cepea
            .where((c) => c.tipo.toLowerCase().contains('conil'))
            .toList() ??
        [];
    final arabica = arabicaList.isNotEmpty ? arabicaList.first : null;
    final conilon = conilonList.isNotEmpty ? conilonList.first : null;
    final dolar = _atual?.dolar;
    final futuro = (_atual?.b3.isNotEmpty ?? false) ? _atual!.b3.first : null;

    return Row(
      children: [
        _VarCard(
          label: 'Arábica CEPEA',
          value: arabica != null ? _moeda.format(arabica.preco) : '—',
          variacao: _fmtVar(arabica?.variacaoPct),
          isUp: (arabica?.variacaoPct ?? 0) >= 0,
        ),
        const SizedBox(width: 8),
        _VarCard(
          label: 'Conilon CEPEA',
          value: conilon != null ? _moeda.format(conilon.preco) : '—',
          variacao: _fmtVar(conilon?.variacaoPct),
          isUp: (conilon?.variacaoPct ?? 0) >= 0,
        ),
        const SizedBox(width: 8),
        _VarCard(
          label: dolar != null ? 'Dólar PTAX' : 'Futuro ICE',
          value: dolar != null
              ? 'R\$ ${dolar.cotacaoVenda.toStringAsFixed(4)}'
              : futuro != null
                  ? _usd.format(futuro.preco)
                  : '—',
          variacao: futuro != null && dolar == null
              ? _fmtVar(futuro.variacaoPct)
              : '—',
          isUp: (futuro?.variacaoPct ?? 0) >= 0,
        ),
      ],
    );
  }

  Widget _buildGrafico() {
    final labels = _historico.map((p) => _dataFmt.format(p.data)).toList();
    final isDolar = _fonteGrafico == 'dolar';

    return Card(
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
                    Text(
                      'Evolução — 30 dias',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CafeColors.darkRoast,
                      ),
                    ),
                    Text(
                      isDolar ? 'Dólar PTAX (venda)' : 'Preço por saca',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: CafeColors.lightRoast,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 4,
                  children: [
                    _chipGrafico('CEPEA Arábica', 'cepea', 'arabica'),
                    _chipGrafico('CEPEA Conilon', 'cepea', 'conilon'),
                    _chipGrafico('Dólar', 'dolar', 'ptax'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _historico.isEmpty
                  ? Center(
                      child: Text(
                        'Sem histórico ainda — aguarde a próxima coleta',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: CafeColors.lightRoast,
                        ),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: CafeColors.lightRoast.withValues(alpha: 0.1),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: isDolar ? 48 : 52,
                              getTitlesWidget: (v, _) => Text(
                                isDolar
                                    ? v.toStringAsFixed(2)
                                    : 'R\$${(v / 1000).toStringAsFixed(1)}k',
                                style: GoogleFonts.dmSans(
                                  fontSize: 9,
                                  color: CafeColors.lightRoast,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: (_historico.length / 4).clamp(1, 10).toDouble(),
                              getTitlesWidget: (v, _) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= labels.length) {
                                  return const SizedBox();
                                }
                                return Text(
                                  labels[idx].substring(0, 5),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9,
                                    color: CafeColors.lightRoast,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _spots,
                            isCurved: true,
                            color: CafeColors.caramel,
                            barWidth: 2.5,
                            dotData: FlDotData(
                              getDotPainter: (_, __, ___, ____) =>
                                  FlDotCirclePainter(
                                radius: 3,
                                color: CafeColors.caramel,
                                strokeWidth: 1.5,
                                strokeColor: Colors.white,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: CafeColors.caramel.withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipGrafico(String label, String fonte, String tipo) {
    final selected = _fonteGrafico == fonte && _tipoGrafico == tipo;
    return GestureDetector(
      onTap: () => _trocarGrafico(fonte, tipo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? CafeColors.caramel : Colors.transparent,
          border: Border.all(
            color: selected
                ? CafeColors.caramel
                : CafeColors.lightRoast.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? CafeColors.espresso : CafeColors.lightRoast,
          ),
        ),
      ),
    );
  }

  Widget _buildSecao(String titulo, List<CotacaoItem> items, bool emReais) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: GoogleFonts.playfairDisplay(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CafeColors.darkRoast,
              ),
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text(
                'Sem dados',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: CafeColors.lightRoast,
                ),
              )
            else
              ...items.map(
                (c) => _CotacaoRow(
                  titulo: c.tipo,
                  preco: emReais ? _moeda.format(c.preco) : _usd.format(c.preco),
                  variacao: _fmtVar(c.variacaoPct),
                  data: _dataFmt.format(c.dataReferencia),
                  isUp: (c.variacaoPct ?? 0) >= 0,
                  unidade: c.unidade,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDolarCard() {
    final d = _atual?.dolar;
    if (d == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dólar PTAX — Banco Central',
              style: GoogleFonts.playfairDisplay(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CafeColors.darkRoast,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Compra',
                    value: 'R\$ ${d.cotacaoCompra.toStringAsFixed(4)}',
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Venda',
                    value: 'R\$ ${d.cotacaoVenda.toStringAsFixed(4)}',
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Data',
                    value: _dataFmt.format(d.dataReferencia),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildB3Section() {
    final items = _atual?.b3 ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Futuros ICE / B3 (Investing)',
              style: GoogleFonts.playfairDisplay(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CafeColors.darkRoast,
              ),
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text(
                'Sem dados de futuros',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: CafeColors.lightRoast,
                ),
              )
            else
              ...items.map(
                (b) => _CotacaoRow(
                  titulo: b.contrato,
                  preco: '${b.moeda} ${b.preco.toStringAsFixed(2)}',
                  variacao: _fmtVar(b.variacaoPct),
                  data: _dataFmt.format(b.dataReferencia),
                  isUp: (b.variacaoPct ?? 0) >= 0,
                  unidade: b.simbolo ?? '',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VarCard extends StatelessWidget {
  final String label, value, variacao;
  final bool isUp;

  const _VarCard({
    required this.label,
    required this.value,
    required this.variacao,
    required this.isUp,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Text(
                  value,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CafeColors.darkRoast,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  variacao,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isUp ? CafeColors.greenOk : CafeColors.redAlert,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    color: CafeColors.lightRoast,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
}

class _CotacaoRow extends StatelessWidget {
  final String titulo, preco, variacao, data, unidade;
  final bool isUp;

  const _CotacaoRow({
    required this.titulo,
    required this.preco,
    required this.variacao,
    required this.data,
    required this.isUp,
    required this.unidade,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CafeColors.darkRoast,
                    ),
                  ),
                  if (unidade.isNotEmpty)
                    Text(
                      unidade,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: CafeColors.lightRoast,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              preco,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CafeColors.espresso,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isUp ? CafeColors.greenOk : CafeColors.redAlert)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                variacao,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isUp ? CafeColors.greenOk : CafeColors.redAlert,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              data,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: CafeColors.lightRoast,
              ),
            ),
          ],
        ),
      );
}

class _MiniStat extends StatelessWidget {
  final String label, value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: CafeColors.lightRoast,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CafeColors.darkRoast,
            ),
          ),
        ],
      );
}
