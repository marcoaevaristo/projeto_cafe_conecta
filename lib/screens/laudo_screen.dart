// lib/screens/laudo_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class LaudoScreen extends StatelessWidget {
  final String id;
  final String conteudo;
  /// Página pública do laudo; é o que o QR Code abre.
  final String? url;

  const LaudoScreen(
      {super.key, required this.id, required this.conteudo, this.url});

  String get _qrData =>
      url ?? 'https://cafe-conecta-backend.vercel.app/laudos/$id';

  Future<void> _baixarPdf() async {
    final doc = pw.Document(title: 'Laudo Café Conecta $id');
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Laudo de Classificação de Café',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Café Conecta · Laudo nº $id',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(conteudo, style: const pw.TextStyle(fontSize: 12, lineSpacing: 4)),
          pw.SizedBox(height: 24),
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(), data: _qrData, width: 110, height: 110),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Text(
                  'Confira a autenticidade deste laudo lendo o QR Code ou acessando:\n$_qrData',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            ),
          ]),
          pw.Spacer(),
          pw.Text(
              'Análise visual automatizada por IA a partir de foto. Não substitui a classificação oficial nem a prova de xícara.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    ));
    await Printing.sharePdf(
        bytes: await doc.save(), filename: 'laudo-cafe-conecta-${id.split('-').first}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CafeColors.espresso,
      appBar: AppBar(
        title: const Text('Laudo Digital'),
        backgroundColor: CafeColors.espresso,
        foregroundColor: CafeColors.cream,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card do laudo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CafeColors.darkRoast,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.description, color: CafeColors.gold),
                    const SizedBox(width: 8),
                    Text('Laudo de Classificação',
                        style: GoogleFonts.playfairDisplay(
                            color: CafeColors.gold,
                            fontWeight: FontWeight.w700,
                            fontSize: 18)),
                  ]),
                  const Divider(color: CafeColors.caramel),
                  const SizedBox(height: 8),
                  Text(conteudo,
                      style: GoogleFonts.dmSans(
                          color: CafeColors.cream, fontSize: 14, height: 1.6)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // QR Code
            Center(
              child: Column(children: [
                Text('QR Code de Rastreabilidade',
                    style: GoogleFonts.dmSans(
                        color: CafeColors.cream,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // QrImageView substitui QrImage (depreciado em qr_flutter ^4.1)
                  child: QrImageView(
                    data: _qrData,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text('ID: $id',
                    style: GoogleFonts.dmSans(
                        color: CafeColors.cream.withOpacity(0.6),
                        fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 24),
            // Botão de compartilhar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CafeColors.caramel,
                  foregroundColor: CafeColors.espresso,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: Text('Baixar laudo em PDF',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                onPressed: _baixarPdf,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: CafeColors.cream,
                  side: const BorderSide(color: CafeColors.caramel),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.link),
                label: const Text('Copiar link do laudo'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _qrData));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link do laudo copiado')));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
