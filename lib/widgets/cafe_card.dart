// lib/widgets/cafe_card.dart — v2 com score badge e verified seal (Melhorias 1, 3)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/cafe_model.dart';
import '../utils/theme.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class CafeCard extends StatelessWidget {
  final CafeModel cafe;
  final bool favorito;
  final VoidCallback? onFavorito;
  final VoidCallback? onDetalhes;
  final VoidCallback? onProposta;

  const CafeCard({super.key, required this.cafe, this.favorito = false,
    this.onFavorito, this.onDetalhes, this.onProposta});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14), onTap: onDetalhes,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _header(), _body(context), _footer(),
        ]),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [CafeColors.darkRoast, CafeColors.mediumRoast],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cafe.nomeCurto, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          if (cafe.fazenda != null)
            Text(cafe.fazenda!, style: GoogleFonts.dmSans(color: CafeColors.caramel, fontSize: 11)),
        ])),
        Row(children: [
          // MELHORIA 1: Score badge
          if (cafe.scoreQualidade != null) _ScoreBadge(score: cafe.scoreQualidade!),
          const SizedBox(width: 8),
          GestureDetector(onTap: onFavorito,
            child: Icon(favorito ? Icons.favorite : Icons.favorite_border,
              color: favorito ? Colors.redAccent : CafeColors.cream, size: 20)),
        ]),
      ]),
    );
  }

  Widget _body(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // MELHORIA 3: Verified seal
        if (cafe.verificado) _VerifiedSeal(context: context),
        Row(children: [
          Expanded(child: _InfoItem(label: 'Quantidade',
            value: '${NumberFormat('#,###').format(cafe.quantidade)} sacas', highlight: true)),
          if (cafe.precoSaca != null)
            Expanded(child: _InfoItem(label: 'Preço/saca',
              value: _brl.format(cafe.precoSaca), highlight: true,
              highlightColor: CafeColors.greenOk)),
        ]),
        const SizedBox(height: 8),
        _Row('Região', cafe.regiao),
        _Row('Bebida', cafe.bebida ?? '—'),
        _Row('Peneira', cafe.peneira ?? '—'),
        if (cafe.corretorEmpresa != null) _Row('Corretor', cafe.corretorEmpresa!),
      ]),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(color: CafeColors.milk,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14))),
      child: Row(children: [
        if (onDetalhes != null)
          Expanded(child: OutlinedButton.icon(onPressed: onDetalhes,
            icon: const Icon(Icons.info_outline, size: 15),
            label: const Text('Detalhes'),
            style: OutlinedButton.styleFrom(foregroundColor: CafeColors.darkRoast,
              side: const BorderSide(color: CafeColors.lightRoast),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 9),
              textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 12)))),
        if (onDetalhes != null && onProposta != null) const SizedBox(width: 8),
        if (onProposta != null)
          Expanded(child: ElevatedButton.icon(onPressed: onProposta,
            icon: const Icon(Icons.assignment_outlined, size: 15),
            label: const Text('Proposta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CafeColors.caramel, foregroundColor: CafeColors.espresso,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 9),
              textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 12)))),
      ]),
    );
  }
}

// MELHORIA 1: Badge circular de score
class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge({required this.score});

  Color get _color => scoreColor(score);
  String get _label => score >= 90 ? 'EXC' : score >= 85 ? 'MB' : score >= 80 ? 'BOM' : 'REG';

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${scoreLabel(score)} · $score pontos de qualidade',
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [_color.withValues(alpha: 0.7), _color], begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [BoxShadow(color: _color.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$score', style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, height: 1)),
          Text(_label, style: GoogleFonts.dmSans(color: Colors.white.withValues(alpha: 0.85), fontSize: 7, fontWeight: FontWeight.w400)),
        ]),
      ),
    );
  }
}

// MELHORIA 3: Verified seal com tooltip
class _VerifiedSeal extends StatelessWidget {
  final BuildContext context;
  const _VerifiedSeal({required this.context});

  @override
  Widget build(BuildContext _) {
    return GestureDetector(
      onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          const Icon(Icons.verified, color: CafeColors.blue, size: 22),
          const SizedBox(width: 8),
          Text('Empresa Verificada', style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _vtItem('✓', 'CNPJ confirmado pela Receita Federal'),
          _vtItem('✓', 'Ativo há mais de 12 meses na plataforma'),
          _vtItem('⭐', 'Score de reputação: 4.8 / 5.0'),
          _vtItem('🤝', '47 negociações concluídas'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(_), child: const Text('OK'))],
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: CafeColors.blue.withValues(alpha: 0.08),
          border: Border.all(color: CafeColors.blue.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.verified, size: 12, color: CafeColors.blue),
          const SizedBox(width: 3),
          Text('CNPJ Verificado', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: CafeColors.blue)),
          const SizedBox(width: 3),
          Icon(Icons.info_outline, size: 11, color: CafeColors.blue.withValues(alpha: 0.6)),
        ]),
      ),
    );
  }

  Widget _vtItem(String icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(icon, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: GoogleFonts.dmSans(fontSize: 13, color: CafeColors.darkRoast))),
    ]),
  );
}

class _Row extends StatelessWidget {
  final String l; final String v;
  const _Row(this.l, this.v);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: GoogleFonts.dmSans(fontSize: 11, color: CafeColors.lightRoast, fontWeight: FontWeight.w500)),
      Text(v, style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.darkRoast, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _InfoItem extends StatelessWidget {
  final String label; final String value;
  final bool highlight; final Color highlightColor;
  const _InfoItem({required this.label, required this.value, this.highlight = false, this.highlightColor = CafeColors.caramel});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: CafeColors.lightRoast)),
    Text(value, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700,
      color: highlight ? highlightColor : CafeColors.darkRoast)),
  ]);
}

class EmptyState extends StatelessWidget {
  final IconData icon; final String titulo; final String subtitulo; final Widget? action;
  const EmptyState({super.key, required this.icon, required this.titulo, this.subtitulo = '', this.action});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 60, color: CafeColors.lightRoast.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        Text(titulo, textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(fontSize: 18, color: CafeColors.darkRoast, fontWeight: FontWeight.w700)),
        if (subtitulo.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(subtitulo, textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 13, color: CafeColors.lightRoast)),
        ],
        if (action != null) ...[const SizedBox(height: 20), action!],
      ]),
    ),
  );
}
