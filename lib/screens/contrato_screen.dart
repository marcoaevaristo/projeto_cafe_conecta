// lib/screens/contrato_screen.dart — minuta de contrato de compra e venda a partir
// de uma proposta aceita. Mostra o resumo e gera o PDF para baixar ou compartilhar.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/api_service.dart';
import '../utils/erros.dart';
import '../utils/theme.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
final _int = NumberFormat.decimalPattern('pt_BR');

String _t(Object? v) => (v == null || '$v'.trim().isEmpty) ? '—' : '$v'.trim();

String _local(Map<String, dynamic>? p) =>
    [p?['cidade'], p?['estado']].where((e) => e != null && '$e'.isNotEmpty).join('/');

class ContratoScreen extends StatefulWidget {
  final String propostaId;
  const ContratoScreen({super.key, required this.propostaId});
  @override
  State<ContratoScreen> createState() => _ContratoScreenState();
}

class _ContratoScreenState extends State<ContratoScreen> {
  Map<String, dynamic>? _c;
  Object? _erro;
  bool _gerando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final c = await ApiService.getContrato(widget.propostaId);
      if (mounted) setState(() => _c = c);
    } catch (e) {
      if (mounted) setState(() => _erro = e);
    }
  }

  Future<void> _pdf() async {
    setState(() => _gerando = true);
    try {
      final bytes = await gerarPdfContrato(_c!);
      await Printing.sharePdf(bytes: bytes, filename: 'contrato-cafe-conecta-${_c!['numero']}.pdf');
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contrato do negócio')),
      body: _erro != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(mensagemDeErro(_erro!), textAlign: TextAlign.center),
              ),
            )
          : _c == null
              ? const Center(child: CircularProgressIndicator())
              : _resumo(),
    );
  }

  Widget _resumo() {
    final c = _c!;
    final lote = (c['lote'] as Map?)?.cast<String, dynamic>() ?? {};
    final cond = (c['condicoes'] as Map?)?.cast<String, dynamic>() ?? {};
    Widget linha(String r, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: 120,
                child: Text(r, style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast))),
            Expanded(child: Text(v, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600))),
          ]),
        );
    Widget parte(String papel, Map? p) => Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(papel.toUpperCase(),
                  style: GoogleFonts.dmSans(
                      fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w700, color: CafeColors.caramel)),
              const SizedBox(height: 6),
              linha('Nome', _t(p?['nome'])),
              linha('Cidade', _t(_local(p?.cast<String, dynamic>()))),
              linha('Telefone', _t(p?['telefone'])),
              linha('E-mail', _t(p?['email'])),
            ]),
          ),
        );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Negócio nº ${c['numero']}',
              style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
          Text('Proposta aceita em ${_dataBr(c['aceita_em'])}',
              style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
          const SizedBox(height: 12),
          parte('Vendedor', c['vendedor'] as Map?),
          parte('Comprador', c['comprador'] as Map?),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('O NEGÓCIO',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w700, color: CafeColors.caramel)),
                const SizedBox(height: 6),
                linha('Café', '${_t(lote['tipo'])} · ${_t(lote['classificacao'])}'),
                linha('Bebida / peneira', '${_t(lote['bebida'])} · ${_t(lote['peneira'])}'),
                linha('Safra', _t(lote['safra'])),
                linha('Origem', '${_t(lote['fazenda'])} · ${_t(_local(lote))}'),
                linha('Quantidade', '${_int.format(c['quantidade_sacas'] ?? 0)} sacas de 60 kg'),
                linha('Preço por saca', _brl.format(c['preco_saca'] ?? 0)),
                linha('Valor total', _brl.format(c['total'] ?? 0)),
                linha('Pagamento', _t(cond['pagamento'])),
                linha('Prazo de entrega', _t(cond['prazo_entrega'])),
                linha('Local de entrega', _t(cond['local_entrega'])),
                if (cond['observacoes'] != null) linha('Observações', _t(cond['observacoes'])),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'O PDF é uma minuta para as partes conferirem, completarem (CPF/CNPJ) e assinarem. '
            'O Café Conecta não participa do negócio. Em caso de dúvida, revise com um advogado.',
            style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _gerando ? null : _pdf,
            icon: _gerando
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Baixar contrato em PDF'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ]),
      ),
    );
  }
}

const _meses = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho',
  'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];

String _dataBr(Object? iso) {
  final d = DateTime.tryParse('${iso ?? ''}')?.toLocal();
  return d == null ? '—' : '${d.day} de ${_meses[d.month - 1]} de ${d.year}';
}

/// Monta o PDF da minuta de contrato de compra e venda.
Future<Uint8List> gerarPdfContrato(Map<String, dynamic> c) async {
  final lote = (c['lote'] as Map?)?.cast<String, dynamic>() ?? {};
  final cond = (c['condicoes'] as Map?)?.cast<String, dynamic>() ?? {};
  final vend = (c['vendedor'] as Map?)?.cast<String, dynamic>() ?? {};
  final comp = (c['comprador'] as Map?)?.cast<String, dynamic>() ?? {};
  final doc = pw.Document(title: 'Contrato Café Conecta ${c['numero']}');

  pw.Widget titulo(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
        child: pw.Text(t, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      );
  pw.Widget par(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(t, style: const pw.TextStyle(fontSize: 10, lineSpacing: 2), textAlign: pw.TextAlign.justify),
      );
  String pessoa(Map<String, dynamic> p) =>
      '${_t(p['nome'])}, residente em ${_t(_local(p))}, telefone ${_t(p['telefone'])}, '
      'e-mail ${_t(p['email'])}, CPF/CNPJ nº ______________________';

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(50, 45, 50, 45),
    footer: (ctx) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text('Gerado pelo Café Conecta · negócio nº ${c['numero']}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
    ]),
    build: (_) => [
      pw.Center(
        child: pw.Text('CONTRATO DE COMPRA E VENDA DE CAFÉ',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      ),
      pw.Center(
        child: pw.Text('Minuta gerada a partir da proposta aceita em ${_dataBr(c['aceita_em'])}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ),
      pw.SizedBox(height: 14),
      titulo('PARTES'),
      par('VENDEDOR: ${pessoa(vend)}.'),
      par('COMPRADOR: ${pessoa(comp)}.'),
      titulo('CLÁUSULA 1 – OBJETO'),
      par('O VENDEDOR vende ao COMPRADOR ${_int.format(c['quantidade_sacas'] ?? 0)} (sacas de 60 kg) de café '
          '${_t(lote['tipo'])}, classificação ${_t(lote['classificacao'])}, bebida ${_t(lote['bebida'])}, '
          'peneira ${_t(lote['peneira'])}, safra ${_t(lote['safra'])}, com origem em ${_t(lote['fazenda'])}, '
          '${_t(_local(lote))}.'),
      titulo('CLÁUSULA 2 – PREÇO'),
      par('O preço é de ${_brl.format(c['preco_saca'] ?? 0)} por saca de 60 kg, totalizando '
          '${_brl.format(c['total'] ?? 0)}.'),
      titulo('CLÁUSULA 3 – PAGAMENTO'),
      par('Condição de pagamento: ${_t(cond['pagamento'])}. Forma de pagamento e dados bancários: '
          '____________________________________________.'),
      titulo('CLÁUSULA 4 – ENTREGA'),
      par('Prazo de entrega: ${_t(cond['prazo_entrega'])}. Local de entrega: ${_t(cond['local_entrega'])}. '
          'Frete e responsabilidade pelo transporte: ________________________________.'),
      titulo('CLÁUSULA 5 – QUALIDADE'),
      par('O café entregue deve corresponder às características acima e à amostra apresentada. '
          'Divergências de qualidade ou de peso devem ser comunicadas em até ____ dias após o recebimento.'),
      if (cond['observacoes'] != null) ...[
        titulo('CLÁUSULA 6 – CONDIÇÕES ADICIONAIS'),
        par(_t(cond['observacoes'])),
      ],
      titulo('DISPOSIÇÕES GERAIS'),
      par('As partes declaram que negociaram diretamente entre si. O Café Conecta apenas disponibilizou a '
          'plataforma de anúncio e negociação e não é parte deste contrato. Fica eleito o foro da comarca de '
          '______________________ para dirimir eventuais dúvidas.'),
      pw.SizedBox(height: 16),
      par('Local e data: ______________________, ____ de ______________ de ______.'),
      pw.SizedBox(height: 36),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        for (final (papel, p) in [('VENDEDOR', vend), ('COMPRADOR', comp)])
          pw.Column(children: [
            pw.Container(width: 200, height: 0.8, color: PdfColors.black),
            pw.SizedBox(height: 4),
            pw.Text(_t(p['nome']), style: const pw.TextStyle(fontSize: 9)),
            pw.Text(papel, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ]),
      ]),
      pw.SizedBox(height: 28),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        for (final n in ['TESTEMUNHA 1', 'TESTEMUNHA 2'])
          pw.Column(children: [
            pw.Container(width: 200, height: 0.8, color: PdfColors.black),
            pw.SizedBox(height: 4),
            pw.Text('$n · CPF: ______________', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ]),
      ]),
      pw.SizedBox(height: 20),
      pw.Text('Minuta gerada automaticamente. Confira os dados, complete os campos em branco e, se necessário, '
          'revise com um advogado antes de assinar.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
    ],
  ));
  return doc.save();
}
