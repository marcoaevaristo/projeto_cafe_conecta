// lib/screens/laudo_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class LaudoScreen extends StatelessWidget {
  final String id;
  final String conteudo;

  const LaudoScreen({super.key, required this.id, required this.conteudo});

  @override
  Widget build(BuildContext context) {
    final qrData = 'cafe-conecta://laudo/$id';
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
                    data: qrData,
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
                icon: const Icon(Icons.share),
                label: Text('Compartilhar Laudo',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Função de compartilhamento em breve!')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
