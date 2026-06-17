// lib/utils/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CafeColors {
  static const espresso = Color(0xFF1A0F08);
  static const darkRoast = Color(0xFF2C1A0E);
  static const mediumRoast = Color(0xFF5C3317);
  static const lightRoast = Color(0xFF8B5E3C);
  static const caramel = Color(0xFFC4863A);
  static const gold = Color(0xFFD4A843);
  static const cream = Color(0xFFF5EAD8);
  static const milk = Color(0xFFFDF6EC);
  static const greenOk = Color(0xFF2D7A4F);
  static const redAlert = Color(0xFF9B2335);
  static const blue = Color(0xFF2563A8);
}

Color scoreColor(int score) {
  if (score >= 90) return const Color(0xFF2D7A4F);
  if (score >= 85) return const Color(0xFF5A9E00);
  if (score >= 80) return const Color(0xFFC49200);
  return const Color(0xFFB85000);
}

String scoreLabel(int score) {
  if (score >= 90) return 'Excelente';
  if (score >= 85) return 'Muito Bom';
  if (score >= 80) return 'Bom';
  return 'Regular';
}

class CafeTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: CafeColors.caramel,
            primary: CafeColors.caramel,
            secondary: CafeColors.gold,
            surface: CafeColors.milk,
            error: CafeColors.redAlert),
        scaffoldBackgroundColor: CafeColors.milk,
        textTheme: GoogleFonts.dmSansTextTheme().copyWith(
          displayLarge: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w900, color: CafeColors.espresso),
          titleLarge: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w700, color: CafeColors.espresso),
          titleMedium: GoogleFonts.dmSans(
              fontWeight: FontWeight.w600, color: CafeColors.darkRoast),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: CafeColors.espresso,
          foregroundColor: CafeColors.cream,
          elevation: 0,
          titleTextStyle: GoogleFonts.playfairDisplay(
              color: CafeColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.w700),
          iconTheme: const IconThemeData(color: CafeColors.cream),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: CafeColors.espresso,
          selectedItemColor: CafeColors.gold,
          unselectedItemColor: CafeColors.lightRoast,
          type: BottomNavigationBarType.fixed,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: CafeColors.caramel,
            foregroundColor: CafeColors.espresso,
            textStyle:
                GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: CafeColors.lightRoast, width: 1.2)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: CafeColors.lightRoast.withValues(alpha: 0.4),
                  width: 1.2)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: CafeColors.caramel, width: 2)),
          labelStyle: GoogleFonts.dmSans(
              color: CafeColors.lightRoast, fontWeight: FontWeight.w600),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: CafeColors.espresso.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                  color: CafeColors.lightRoast.withValues(alpha: 0.12))),
        ),
      );
}

const tiposCafe = ['Arábica', 'Conilon', 'Robusta'];
const classificacoesCafe = [
  'Tipo 4',
  'Tipo 5',
  'Tipo 6',
  'Tipo 7',
  'Tipo 8',
  'Especial'
];
const bebidasCafe = [
  'Estritamente Mole',
  'Mole',
  'Apenas Mole',
  'Dura',
  'Riada',
  'Rio',
  'Rio Zona'
];
const peneirasDisponiveis = [
  '13/14',
  '13/15',
  '14/16',
  '15/16',
  '16/18',
  '17/18',
  '18 acima'
];
const regioesCafe = [
  'Sul de Minas',
  'Cerrado Mineiro',
  'Zona da Mata',
  'Matas de Minas',
  'Espírito Santo',
  'Bahia',
  'Outro'
];
const condicoesPagamento = [
  'À vista',
  '30 dias',
  '30/60 dias',
  '30/60/90 dias'
];
const prazosEntrega = ['7 dias', '15 dias', '30 dias', 'A combinar'];
const locaisEntrega = ['FOB Fazenda', 'CIF destino', 'A combinar'];
