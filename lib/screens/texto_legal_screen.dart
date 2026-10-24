// lib/screens/texto_legal_screen.dart — Termos de uso e Política de privacidade
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/textos_legais.dart';
import '../utils/theme.dart';

class TextoLegalScreen extends StatelessWidget {
  final String titulo;
  final List<SecaoLegal> secoes;

  const TextoLegalScreen({super.key, required this.titulo, required this.secoes});

  const TextoLegalScreen.termos({super.key})
      : titulo = 'Termos de uso',
        secoes = termosDeUso;

  const TextoLegalScreen.privacidade({super.key})
      : titulo = 'Política de privacidade',
        secoes = politicaDePrivacidade;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              Text('Versão de $dataTermos',
                  style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
              const SizedBox(height: 8),
              for (final s in secoes) ...[
                const SizedBox(height: 16),
                Text(s.titulo,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 17, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
                const SizedBox(height: 8),
                for (final p in s.paragrafos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SelectableText(p,
                        style: GoogleFonts.dmSans(
                            fontSize: 14, height: 1.55, color: CafeColors.darkRoast)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
