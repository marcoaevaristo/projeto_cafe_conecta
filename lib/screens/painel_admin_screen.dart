// lib/screens/painel_admin_screen.dart — Painel do desenvolvedor (só contas administradoras)
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../utils/erros.dart';
import '../utils/theme.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
final _data = DateFormat('dd/MM HH:mm');

const _nomePlano = {
  'gratuito': 'Gratuito',
  'basico': 'Básico',
  'profissional': 'Profissional',
  'premium': 'Premium',
};
const _nomeStatus = {
  'pendente': 'Aguardando',
  'aceita': 'Aceitas',
  'recusada': 'Recusadas',
  'cancelada': 'Canceladas',
  'contraproposta': 'Contrapropostas',
  'ativo': 'Ativas',
  'cancelado': 'Canceladas',
  'expirado': 'Expiradas',
};

class PainelAdminScreen extends StatefulWidget {
  const PainelAdminScreen({super.key});
  @override
  State<PainelAdminScreen> createState() => _PainelAdminScreenState();
}

class _PainelAdminScreenState extends State<PainelAdminScreen> {
  Map<String, dynamic>? _r;
  Object? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final r = await ApiService.getAdminResumo();
      if (mounted) setState(() { _r = r; _erro = null; });
    } catch (e) {
      if (mounted) setState(() => _erro = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Painel do desenvolvedor'), actions: [
        IconButton(onPressed: _carregar, icon: const Icon(Icons.refresh), tooltip: 'Atualizar'),
      ]),
      body: _erro != null
          ? Center(
              child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(mensagemDeErro(_erro!), textAlign: TextAlign.center),
            ))
          : _r == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(onRefresh: _carregar, child: _conteudo(_r!)),
    );
  }

  Widget _conteudo(Map<String, dynamic> r) {
    final u = r['usuarios'] as Map<String, dynamic>;
    final a = r['acessos'] as Map<String, dynamic>;
    final rec = r['receita'] as Map<String, dynamic>;
    final m = r['marketplace'] as Map<String, dynamic>;

    return ListView(padding: const EdgeInsets.all(14), children: [
      Text('Atualizado em ${_data.format(DateTime.parse(r['gerado_em']).toLocal())}',
          style: GoogleFonts.dmSans(fontSize: 11, color: CafeColors.lightRoast)),

      _secao('Receita e assinaturas'),
      _grade([
        _Kpi('Receita mensal', _brl.format(rec['mrr'] ?? 0), '${rec['pagantes']} assinantes pagantes'),
        _Kpi('Recebido em 30 dias', _brl.format(rec['recebido_30d'] ?? 0),
            'Total: ${_brl.format(rec['recebido_total'] ?? 0)}'),
        _Kpi('Vencem em 7 dias', '${rec['vencem_7d']}', 'planos pagos a renovar'),
        _Kpi('Cortesias', '${rec['cortesias']}', 'plano pago sem pagamento'),
      ]),
      _distribuicao('Assinaturas por situação', rec['assinaturas_por_status'], _nomeStatus),

      _secao('Acessos'),
      if (a['disponivel'] != true)
        _aviso('O registro de acessos ainda não está ativo: falta rodar migration_acessos.sql no Supabase.')
      else ...[
        _grade([
          _Kpi('Hoje', '${a['hoje_usuarios']}', 'usuários + ${a['hoje_anonimos']} visitas sem login'),
          _Kpi('Média diária', '${a['media_diaria_7d']}', 'usuários/dia (7 dias)'),
          _Kpi('Ativos em 7 dias', '${a['ativos_7d']}', 'usuários diferentes'),
          _Kpi('Ativos em 30 dias', '${a['ativos_30d']}', 'usuários diferentes'),
        ]),
        _grafico(
          'Acessos por dia (30 dias)',
          (a['serie_30d'] as List).cast<Map<String, dynamic>>(),
          [('usuarios', CafeColors.caramel, 'Usuários'), ('anonimos', CafeColors.lightRoast, 'Sem login')],
        ),
      ],

      _secao('Usuários'),
      _grade([
        _Kpi('Total', '${u['total']}', 'contas cadastradas'),
        _Kpi('Novos em 7 dias', '${u['novos_7d']}', '${u['novos_30d']} em 30 dias'),
      ]),
      _distribuicao('Por plano', u['por_plano'], _nomePlano),
      _distribuicao('Por tipo de conta', u['por_tipo'], const {
        'produtor': 'Produtores',
        'comprador': 'Compradores',
        'corretor': 'Corretores',
        'admin': 'Administradores',
      }),
      _grafico(
        'Cadastros por dia (30 dias)',
        (u['serie_cadastros_30d'] as List).cast<Map<String, dynamic>>(),
        [('total', CafeColors.greenOk, 'Cadastros')],
      ),

      _secao('Marketplace'),
      _grade([
        _Kpi('Lotes ativos', '${m['lotes_ativos']}',
            '${m['lotes_total']} no total · ${m['lotes_novos_30d']} novos em 30d'),
        _Kpi('Propostas', '${m['propostas_total']}', '${m['propostas_30d']} em 30 dias'),
        _Kpi('Taxa de aceite',
            m['taxa_aceite'] == null ? '—' : '${m['taxa_aceite']}%', 'das propostas respondidas'),
        _Kpi('Volume negociado', _brl.format(m['volume_negociado'] ?? 0), 'propostas aceitas'),
        _Kpi('Mensagens', '${m['mensagens_30d']}', 'em 30 dias'),
        _Kpi('Laudos de IA', '${m['laudos_ia_30d']}', '${m['laudos_ia_total']} no total'),
        _Kpi('Alertas ativos', '${m['alertas_ativos']}', 'de preço'),
      ]),
      _distribuicao('Propostas por situação', m['propostas_por_status'], _nomeStatus),

      _secao('Últimos pagamentos'),
      _lista(
        (rec['ultimos_pagamentos'] as List).cast<Map<String, dynamic>>(),
        vazio: 'Nenhum pagamento confirmado ainda.',
        titulo: (p) => '${p['usuario']} · ${_nomePlano[p['plano']] ?? p['plano']}',
        detalhe: (p) =>
            '${_brl.format(p['valor'] ?? 0)} · ${p['metodo'] ?? '—'} · ${_data.format(DateTime.parse(p['criado_em']).toLocal())}',
      ),

      _secao('Últimos cadastros'),
      _lista(
        (u['ultimos'] as List).cast<Map<String, dynamic>>(),
        vazio: 'Nenhum cadastro ainda.',
        titulo: (c) => '${c['nome']} · ${c['tipo']}',
        detalhe: (c) =>
            '${c['email']} · ${_nomePlano[c['plano']] ?? c['plano']} · ${c['criado_em'] == null ? '' : _data.format(DateTime.parse(c['criado_em']).toLocal())}',
      ),
      const SizedBox(height: 24),
    ]);
  }

  // ── Blocos de layout ───────────────────────────────────────────────
  Widget _secao(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 20, 2, 8),
        child: Text(t,
            style: GoogleFonts.playfairDisplay(
                fontSize: 17, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
      );

  Widget _aviso(String t) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CafeColors.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(t, style: GoogleFonts.dmSans(fontSize: 13)),
      );

  Widget _grade(List<_Kpi> kpis) => LayoutBuilder(builder: (context, c) {
        final colunas = c.maxWidth > 600 ? 4 : 2;
        final largura = (c.maxWidth - (colunas - 1) * 10) / colunas;
        return Wrap(spacing: 10, runSpacing: 10, children: [
          for (final k in kpis)
            SizedBox(
              width: largura,
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(k.titulo,
                        style: GoogleFonts.dmSans(fontSize: 11, color: CafeColors.lightRoast)),
                    const SizedBox(height: 4),
                    Text(k.valor,
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 20, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
                    const SizedBox(height: 2),
                    Text(k.detalhe,
                        style: GoogleFonts.dmSans(fontSize: 10, color: CafeColors.lightRoast)),
                  ]),
                ),
              ),
            ),
        ]);
      });

  Widget _distribuicao(String titulo, dynamic dados, Map<String, String> nomes) {
    final mapa = (dados as Map?)?.cast<String, dynamic>() ?? {};
    final total = mapa.values.fold<num>(0, (s, v) => s + (v as num));
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          if (mapa.isEmpty)
            Text('Sem dados ainda', style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
          for (final e in mapa.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(
                    width: 120,
                    child: Text(nomes[e.key] ?? e.key, style: GoogleFonts.dmSans(fontSize: 12))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : (e.value as num) / total,
                      minHeight: 8,
                      backgroundColor: CafeColors.lightRoast.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation(CafeColors.caramel),
                    ),
                  ),
                ),
                SizedBox(
                    width: 36,
                    child: Text('${e.value}',
                        textAlign: TextAlign.right, style: GoogleFonts.dmSans(fontSize: 12))),
              ]),
            ),
        ]),
      ),
    );
  }

  /// Barras empilhadas por dia. series: (campo, cor, legenda)
  Widget _grafico(String titulo, List<Map<String, dynamic>> pontos,
      List<(String, Color, String)> series) {
    double maior = 1;
    for (final p in pontos) {
      final soma = series.fold<double>(0, (s, x) => s + ((p[x.$1] as num?) ?? 0).toDouble());
      if (soma > maior) maior = soma;
    }
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Wrap(spacing: 12, children: [
            for (final s in series)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10, color: s.$2),
                const SizedBox(width: 4),
                Text(s.$3, style: GoogleFonts.dmSans(fontSize: 11)),
              ]),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            height: 160,
            child: BarChart(BarChartData(
              maxY: maior * 1.15,
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (g, _, __, ___) {
                    final p = pontos[g.x];
                    final d = DateTime.parse(p['dia']);
                    final linhas = series.map((s) => '${s.$3}: ${p[s.$1]}').join('\n');
                    return BarTooltipItem('${DateFormat('dd/MM').format(d)}\n$linhas',
                        const TextStyle(color: Colors.white, fontSize: 11));
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, meta) => v % 1 != 0 || v == meta.max
                        ? const SizedBox()
                        : Text(v.toInt().toString(), style: const TextStyle(fontSize: 9)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      // mostra só alguns dias para não amontoar
                      if (i % 7 != 0 && i != pontos.length - 1) return const SizedBox();
                      return Text(DateFormat('dd/MM').format(DateTime.parse(pontos[i]['dia'])),
                          style: const TextStyle(fontSize: 9));
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < pontos.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    () {
                      double acumulado = 0;
                      final itens = <BarChartRodStackItem>[];
                      for (final s in series) {
                        final v = ((pontos[i][s.$1] as num?) ?? 0).toDouble();
                        itens.add(BarChartRodStackItem(acumulado, acumulado + v, s.$2));
                        acumulado += v;
                      }
                      return BarChartRodData(
                        toY: acumulado,
                        width: 6,
                        rodStackItems: itens,
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      );
                    }(),
                  ]),
              ],
            )),
          ),
        ]),
      ),
    );
  }

  Widget _lista(List<Map<String, dynamic>> itens,
      {required String vazio,
      required String Function(Map<String, dynamic>) titulo,
      required String Function(Map<String, dynamic>) detalhe}) {
    return Card(
      margin: EdgeInsets.zero,
      child: itens.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(14),
              child: Text(vazio, style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
            )
          : Column(children: [
              for (final i in itens)
                ListTile(
                  dense: true,
                  title: Text(titulo(i), style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(detalhe(i), style: GoogleFonts.dmSans(fontSize: 11)),
                ),
            ]),
    );
  }
}

class _Kpi {
  final String titulo, valor, detalhe;
  const _Kpi(this.titulo, this.valor, this.detalhe);
}
