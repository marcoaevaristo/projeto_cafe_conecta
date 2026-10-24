// lib/utils/relatorio_export.dart — transforma o relatório do servidor em PDF e em planilha
// (CSV com ; e acentos, que o Excel abre direto em português).
import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
final _int = NumberFormat.decimalPattern('pt_BR');
final _num2 = NumberFormat('#,##0.00', 'pt_BR');

String dataBr(String? iso) {
  if (iso == null || iso.length < 10) return '—';
  return '${iso.substring(8, 10)}/${iso.substring(5, 7)}/${iso.substring(0, 4)}';
}

String _dinheiro(Object? v) => v == null ? '—' : _brl.format((v as num).toDouble());

List<Map<String, dynamic>> _lista(Map<String, dynamic> r, String chave) =>
    (r[chave] as List? ?? []).cast<Map<String, dynamic>>();

// ── Planilha ──────────────────────────────────────────────────────────
String _celula(Object? v) {
  final t = v == null ? '' : '$v';
  return (t.contains(';') || t.contains('"') || t.contains('\n')) ? '"${t.replaceAll('"', '""')}"' : t;
}

String _numeroCsv(Object? v) => v == null ? '' : _num2.format((v as num).toDouble());

Uint8List gerarCsvRelatorio(Map<String, dynamic> r, {required String titulo}) {
  final p = r['periodo'] as Map? ?? {};
  final res = r['resumo'] as Map? ?? {};
  final temMembro = _lista(r, 'vendas').any((x) => x['membro'] != null) || r['por_membro'] != null;
  final linhas = <List<Object?>>[
    [titulo],
    ['Período', '${dataBr(p['de'])} a ${dataBr(p['ate'])}'],
    [],
    ['Resumo'],
    ['Lotes ativos', res['lotes_ativos']],
    ['Sacas ofertadas', res['sacas_ofertadas']],
    ['Propostas no período', res['propostas_no_periodo']],
    ['Vendas (negócios)', (res['vendas'] as Map?)?['negocios']],
    ['Sacas vendidas', (res['vendas'] as Map?)?['sacas']],
    ['Valor vendido (R\$)', _numeroCsv((res['vendas'] as Map?)?['valor'])],
    ['Preço médio de venda (R\$/saca)', _numeroCsv(res['preco_medio_venda'])],
    ['Sacas compradas', (res['compras'] as Map?)?['sacas']],
    ['Valor comprado (R\$)', _numeroCsv((res['compras'] as Map?)?['valor'])],
  ];
  if (r['por_membro'] != null) {
    linhas.addAll([[], ['Por membro'], ['Membro', 'Lotes ativos', 'Sacas ofertadas', 'Sacas vendidas', 'Valor vendido (R\$)', 'Sacas compradas']]);
    for (final m in _lista(r, 'por_membro')) {
      linhas.add([m['nome'], m['lotes_ativos'], m['sacas_ofertadas'], m['sacas_vendidas'], _numeroCsv(m['valor_vendido']), m['sacas_compradas']]);
    }
  }
  void tabela(String nome, List<Map<String, dynamic>> itens) {
    linhas.addAll([[], [nome], [
      'Data', if (temMembro) 'Membro', 'Lote', 'Origem', 'Sacas', 'Preço por saca (R\$)', 'Total (R\$)'
    ]]);
    for (final x in itens) {
      linhas.add([dataBr(x['data']), if (temMembro) x['membro'], x['lote'], x['origem'], x['sacas'],
        _numeroCsv(x['preco_saca']), _numeroCsv(x['total'])]);
    }
  }
  tabela('Vendas', _lista(r, 'vendas'));
  tabela('Compras', _lista(r, 'compras'));
  linhas.addAll([[], ['Lotes'], [
    if (temMembro) 'Membro', 'Tipo', 'Classificação', 'Fazenda', 'Cidade', 'Sacas', 'Preço por saca (R\$)', 'Situação', 'Criado em'
  ]]);
  for (final l in _lista(r, 'lotes')) {
    linhas.add([if (temMembro) l['membro'], l['tipo'], l['classificacao'], l['fazenda'], l['cidade'], l['sacas'],
      _numeroCsv(l['preco_saca']), l['status'], dataBr(l['criado_em'])]);
  }
  final csv = linhas.map((l) => l.map(_celula).join(';')).join('\r\n');
  // BOM no começo para o Excel reconhecer UTF-8 (acentos)
  return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
}

// ── PDF ───────────────────────────────────────────────────────────────
Future<Uint8List> gerarPdfRelatorio(Map<String, dynamic> r, {required String titulo, String? subtitulo}) async {
  final doc = pw.Document();
  final p = r['periodo'] as Map? ?? {};
  final res = r['resumo'] as Map? ?? {};
  final vendas = res['vendas'] as Map? ?? {};
  final compras = res['compras'] as Map? ?? {};
  const marrom = PdfColor.fromInt(0xFF2C1A0E);
  const caramelo = PdfColor.fromInt(0xFFC4863A);
  const creme = PdfColor.fromInt(0xFFF5EAD8);
  final temMembro = r['por_membro'] != null;

  pw.Widget kpi(String rotulo, String valor) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 6),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(color: creme, borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(rotulo, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(valor, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: marrom)),
          ]),
        ),
      );

  pw.Widget tabela(String nome, List<String> cab, List<List<String>> linhas) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 14),
          pw.Text(nome, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: marrom)),
          pw.SizedBox(height: 6),
          if (linhas.isEmpty)
            pw.Text('Nada no período.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700))
          else
            pw.TableHelper.fromTextArray(
              headers: cab,
              data: linhas,
              headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: marrom),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              oddRowDecoration: const pw.BoxDecoration(color: creme),
            ),
        ],
      );

  List<List<String>> negocios(List<Map<String, dynamic>> itens) => [
        for (final x in itens)
          [dataBr(x['data']), if (temMembro) '${x['membro'] ?? '—'}', '${x['lote']}', '${x['origem']}',
            _int.format(x['sacas'] ?? 0), _dinheiro(x['preco_saca']), _dinheiro(x['total'])],
      ];
  final cabNegocio = ['Data', if (temMembro) 'Membro', 'Lote', 'Origem', 'Sacas', 'R\$/saca', 'Total'];

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    header: (ctx) => pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: caramelo, width: 2))),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('Café Conecta', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: marrom)),
        pw.Text('${dataBr(p['de'])} a ${dataBr(p['ate'])}', style: const pw.TextStyle(fontSize: 9)),
      ]),
    ),
    footer: (ctx) => pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text('Gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())} · página ${ctx.pageNumber} de ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
    ),
    build: (ctx) => [
      pw.SizedBox(height: 10),
      pw.Text(titulo, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: marrom)),
      if (subtitulo != null) pw.Text(subtitulo, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
      pw.SizedBox(height: 12),
      pw.Row(children: [
        kpi('Valor vendido', _dinheiro(vendas['valor'])),
        kpi('Sacas vendidas', _int.format(vendas['sacas'] ?? 0)),
        kpi('Preço médio', res['preco_medio_venda'] == null ? '—' : _dinheiro(res['preco_medio_venda'])),
        kpi('Negócios', '${vendas['negocios'] ?? 0}'),
      ]),
      pw.SizedBox(height: 6),
      pw.Row(children: [
        kpi('Lotes ativos', '${res['lotes_ativos'] ?? 0}'),
        kpi('Sacas ofertadas', _int.format(res['sacas_ofertadas'] ?? 0)),
        kpi('Propostas no período', '${res['propostas_no_periodo'] ?? 0}'),
        kpi('Valor comprado', _dinheiro(compras['valor'])),
      ]),
      if (temMembro)
        tabela('Por membro', ['Membro', 'Lotes ativos', 'Sacas ofertadas', 'Sacas vendidas', 'Valor vendido', 'Sacas compradas'], [
          for (final m in _lista(r, 'por_membro'))
            ['${m['nome']}', '${m['lotes_ativos']}', _int.format(m['sacas_ofertadas'] ?? 0), _int.format(m['sacas_vendidas'] ?? 0),
              _dinheiro(m['valor_vendido']), _int.format(m['sacas_compradas'] ?? 0)],
        ]),
      tabela('Vendas', cabNegocio, negocios(_lista(r, 'vendas'))),
      tabela('Compras', cabNegocio, negocios(_lista(r, 'compras'))),
      tabela('Lotes ativos', [if (temMembro) 'Membro', 'Lote', 'Cidade', 'Sacas', 'R\$/saca'], [
        for (final l in _lista(r, 'lotes').where((l) => l['status'] == 'ativo'))
          [if (temMembro) '${l['membro'] ?? '—'}',
            [l['tipo'], l['classificacao'], l['fazenda']].where((e) => e != null).join(' · '),
            '${l['cidade'] ?? '—'}', _int.format(l['sacas'] ?? 0), _dinheiro(l['preco_saca'])],
      ]),
      pw.SizedBox(height: 16),
      pw.Text('Vendas incluem propostas aceitas e lotes marcados como vendidos com preço final informado.',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
    ],
  ));
  return doc.save();
}
