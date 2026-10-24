// lib/screens/relatorios_screen.dart — relatório de negócios por período, com download
// em PDF e em planilha (Excel). O mesmo painel é usado na conta empresarial.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../services/api_service.dart';
import '../utils/baixar/baixar_arquivo.dart';
import '../utils/erros.dart';
import '../utils/relatorio_export.dart';
import '../utils/theme.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
final _int = NumberFormat.decimalPattern('pt_BR');
String _iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

class RelatoriosScreen extends StatelessWidget {
  const RelatoriosScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Relatórios')),
        body: PainelRelatorio(
          titulo: 'Relatório de negócios',
          nomeArquivo: 'relatorio-cafe-conecta',
          carregar: (de, ate) => ApiService.getRelatorio(de, ate),
        ),
      );
}

/// Escolha de período + resumo + lista de vendas/compras + botões de exportar.
class PainelRelatorio extends StatefulWidget {
  final String titulo;
  final String? subtitulo;
  final String nomeArquivo;
  final Future<Map<String, dynamic>> Function(String de, String ate) carregar;
  const PainelRelatorio({super.key, required this.titulo, this.subtitulo, required this.nomeArquivo, required this.carregar});
  @override
  State<PainelRelatorio> createState() => _PainelRelatorioState();
}

class _PainelRelatorioState extends State<PainelRelatorio> {
  late DateTimeRange _periodo;
  Map<String, dynamic>? _r;
  Object? _erro;
  bool _carregando = true;
  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    _periodo = DateTimeRange(start: DateTime(hoje.year - 1, hoje.month, hoje.day), end: hoje);
    _buscar();
  }

  Future<void> _buscar() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final r = await widget.carregar(_iso(_periodo.start), _iso(_periodo.end));
      if (mounted) setState(() => _r = r);
    } catch (e) {
      if (mounted) setState(() => _erro = e);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _escolherPeriodo() async {
    final p = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _periodo,
    );
    if (p != null) {
      _periodo = p;
      _buscar();
    }
  }

  void _atalho(int meses) {
    final hoje = DateTime.now();
    _periodo = DateTimeRange(start: DateTime(hoje.year, hoje.month - meses, hoje.day), end: hoje);
    _buscar();
  }

  Future<void> _exportar(bool pdf) async {
    final r = _r;
    if (r == null) return;
    setState(() => _exportando = true);
    final sufixo = '${_iso(_periodo.start)}_${_iso(_periodo.end)}';
    try {
      if (pdf) {
        final bytes = await gerarPdfRelatorio(r, titulo: widget.titulo, subtitulo: widget.subtitulo);
        await Printing.sharePdf(bytes: bytes, filename: '${widget.nomeArquivo}_$sufixo.pdf');
      } else {
        await baixarArquivo(gerarCsvRelatorio(r, titulo: widget.titulo), '${widget.nomeArquivo}_$sufixo.csv',
            'text/csv;charset=utf-8');
      }
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    final res = (r?['resumo'] as Map?) ?? {};
    final vendas = (res['vendas'] as Map?) ?? {};
    final compras = (res['compras'] as Map?) ?? {};
    final porMembro = (r?['por_membro'] as List?)?.cast<Map<String, dynamic>>();
    final f = DateFormat('dd/MM/yyyy');

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: RefreshIndicator(
          onRefresh: _buscar,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (widget.subtitulo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(widget.subtitulo!, style: GoogleFonts.dmSans(color: CafeColors.lightRoast)),
              ),
            Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              OutlinedButton.icon(
                onPressed: _escolherPeriodo,
                icon: const Icon(Icons.date_range, size: 18),
                label: Text('${f.format(_periodo.start)} a ${f.format(_periodo.end)}'),
              ),
              ActionChip(label: const Text('3 meses'), onPressed: () => _atalho(3)),
              ActionChip(label: const Text('6 meses'), onPressed: () => _atalho(6)),
              ActionChip(label: const Text('12 meses'), onPressed: () => _atalho(12)),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ElevatedButton.icon(
                onPressed: r == null || _exportando ? null : () => _exportar(true),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Baixar PDF'),
              ),
              OutlinedButton.icon(
                onPressed: r == null || _exportando ? null : () => _exportar(false),
                icon: const Icon(Icons.table_view_outlined),
                label: const Text('Baixar planilha (Excel)'),
              ),
            ]),
            const SizedBox(height: 16),
            if (_carregando)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (_erro != null)
              Padding(padding: const EdgeInsets.all(24), child: Text(mensagemDeErro(_erro!), textAlign: TextAlign.center))
            else if (r != null) ...[
              LayoutBuilder(builder: (context, c) {
                final colunas = c.maxWidth > 640 ? 4 : 2;
                final itens = [
                  ('Valor vendido', _brl.format((vendas['valor'] ?? 0) as num)),
                  ('Sacas vendidas', _int.format(vendas['sacas'] ?? 0)),
                  ('Preço médio', res['preco_medio_venda'] == null ? '—' : _brl.format(res['preco_medio_venda'] as num)),
                  ('Negócios fechados', '${vendas['negocios'] ?? 0}'),
                  ('Lotes ativos', '${res['lotes_ativos'] ?? 0}'),
                  ('Sacas ofertadas', _int.format(res['sacas_ofertadas'] ?? 0)),
                  ('Propostas no período', '${res['propostas_no_periodo'] ?? 0}'),
                  ('Valor comprado', _brl.format((compras['valor'] ?? 0) as num)),
                ];
                final largura = (c.maxWidth - (colunas - 1) * 8) / colunas;
                return Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final (rotulo, valor) in itens)
                    SizedBox(
                      width: largura,
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(rotulo, style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
                            const SizedBox(height: 4),
                            Text(valor,
                                style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
                          ]),
                        ),
                      ),
                    ),
                ]);
              }),
              if (porMembro != null) ...[
                _titulo('Por membro'),
                for (final m in porMembro)
                  Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      title: Text('${m['nome']}', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                      subtitle: Text('${m['lotes_ativos']} lotes ativos · ${_int.format(m['sacas_ofertadas'] ?? 0)} sacas ofertadas'
                          ' · ${_int.format(m['sacas_compradas'] ?? 0)} compradas'),
                      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(_brl.format((m['valor_vendido'] ?? 0) as num), style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                        Text('${_int.format(m['sacas_vendidas'] ?? 0)} sacas', style: GoogleFonts.dmSans(fontSize: 11)),
                      ]),
                    ),
                  ),
              ],
              _titulo('Vendas'),
              ..._negocios((r['vendas'] as List? ?? []).cast<Map<String, dynamic>>()),
              _titulo('Compras'),
              ..._negocios((r['compras'] as List? ?? []).cast<Map<String, dynamic>>()),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
        child: Text(t, style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
      );

  List<Widget> _negocios(List<Map<String, dynamic>> itens) {
    if (itens.isEmpty) {
      return [Text('Nada no período.', style: GoogleFonts.dmSans(color: CafeColors.lightRoast))];
    }
    return [
      for (final x in itens.reversed)
        Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            dense: true,
            title: Text('${x['lote']}', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
            subtitle: Text('${dataBr(x['data'])}${x['membro'] != null ? ' · ${x['membro']}' : ''} · ${x['origem']}'),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(x['total'] == null ? '—' : _brl.format(x['total'] as num), style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
              Text('${_int.format(x['sacas'] ?? 0)} sc${x['preco_saca'] != null ? ' · ${_brl.format(x['preco_saca'] as num)}' : ''}',
                  style: GoogleFonts.dmSans(fontSize: 11)),
            ]),
          ),
        ),
    ];
  }
}
