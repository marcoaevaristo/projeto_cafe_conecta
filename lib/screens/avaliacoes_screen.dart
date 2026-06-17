// lib/screens/avaliacoes_screen.dart — v3: Sistema de avaliações
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cafe_model.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';

class AvaliacoesScreen extends StatefulWidget {
  final int usuarioId;
  final String usuarioNome;
  const AvaliacoesScreen(
      {super.key, required this.usuarioId, required this.usuarioNome});
  @override
  State<AvaliacoesScreen> createState() => _AvaliacoesScreenState();
}

class _AvaliacoesScreenState extends State<AvaliacoesScreen> {
  List<AvaliacaoModel> _avaliacoes = [];
  Map<String, dynamic> _resumo = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final avs = await DatabaseService.getAvaliacoes(widget.usuarioId);
    final res = await DatabaseService.getResumoAvaliacoes(widget.usuarioId);
    setState(() {
      _avaliacoes = avs;
      _resumo = res;
    });
  }

  double get _media => (_resumo['media'] ?? 0.0) is double
      ? _resumo['media'] ?? 0.0
      : (_resumo['media'] ?? 0.0).toDouble();
  int get _total => (_resumo['total'] ?? 0) as int;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Avaliações — ${widget.usuarioNome}')),
      body: _total == 0
          ? const EmptyStateSimples(
              icon: Icons.star_border, titulo: 'Nenhuma avaliação ainda')
          : ListView(children: [
              _buildResumo(),
              const Divider(height: 1),
              ..._avaliacoes.map(_buildCard),
            ]),
    );
  }

  Widget _buildResumo() => Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Row(children: [
          Column(children: [
            Text(_media.toStringAsFixed(1),
                style: GoogleFonts.playfairDisplay(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: CafeColors.gold)),
            Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                        i < _media.round() ? Icons.star : Icons.star_border,
                        color: CafeColors.gold,
                        size: 18))),
            const SizedBox(height: 4),
            Text('$_total avaliações',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: CafeColors.lightRoast)),
          ]),
          const SizedBox(width: 20),
          Expanded(
              child: Column(children: [
            _barra(5, _resumo['n5'] ?? 0),
            _barra(4, _resumo['n4'] ?? 0),
            _barra(3, _resumo['n3'] ?? 0),
            _barra(2, _resumo['n2'] ?? 0),
          ])),
        ]),
      );

  Widget _barra(int nota, int count) {
    final pct = _total > 0 ? count / _total : 0.0;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Text('$nota',
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: CafeColors.lightRoast)),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 11, color: CafeColors.gold),
          const SizedBox(width: 6),
          Expanded(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor:
                        CafeColors.lightRoast.withValues(alpha: 0.1),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(CafeColors.gold),
                  ))),
          const SizedBox(width: 6),
          SizedBox(
              width: 22,
              child: Text('$count',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: CafeColors.lightRoast),
                  textAlign: TextAlign.right)),
        ]));
  }

  Widget _buildCard(AvaliacaoModel av) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CafeColors.lightRoast.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
                backgroundColor: CafeColors.darkRoast,
                radius: 18,
                child: Text(
                    (av.avaliadorNome ?? 'U').substring(0, 1).toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                        color: CafeColors.gold, fontWeight: FontWeight.w700))),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(av.avaliadorEmpresa ?? av.avaliadorNome ?? 'Usuário',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: CafeColors.darkRoast)),
                  Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                              i < av.nota ? Icons.star : Icons.star_border,
                              size: 14,
                              color: CafeColors.gold))),
                ])),
            Text(_formatarData(av.criadoEm),
                style: GoogleFonts.dmSans(
                    fontSize: 10, color: CafeColors.lightRoast)),
          ]),
          if (av.comentario != null && av.comentario!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(av.comentario!,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: CafeColors.darkRoast, height: 1.4)),
          ],
        ]),
      );

  String _formatarData(String? dt) {
    if (dt == null) return '';
    try {
      final d = DateTime.parse(dt);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return '';
    }
  }
}

// Widget para avaliar após negociação
class AvaliarDialog extends StatefulWidget {
  final int deUsuarioId;
  final int paraUsuarioId;
  final int propostaId;
  final String nomeAvaliado;
  const AvaliarDialog(
      {super.key,
      required this.deUsuarioId,
      required this.paraUsuarioId,
      required this.propostaId,
      required this.nomeAvaliado});
  @override
  State<AvaliarDialog> createState() => _AvaliarDialogState();
}

class _AvaliarDialogState extends State<AvaliarDialog> {
  int _nota = 5;
  final _comentCtrl = TextEditingController();
  bool _enviando = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('⭐ Avaliar negociação',
          style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Como foi sua experiência com ${widget.nomeAvaliado}?',
            style:
                GoogleFonts.dmSans(fontSize: 13, color: CafeColors.lightRoast)),
        const SizedBox(height: 16),
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                5,
                (i) => GestureDetector(
                      onTap: () => setState(() => _nota = i + 1),
                      child: Icon(i < _nota ? Icons.star : Icons.star_border,
                          color: CafeColors.gold, size: 36),
                    ))),
        const SizedBox(height: 8),
        Text(_textoNota,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CafeColors.caramel)),
        const SizedBox(height: 14),
        TextField(
          controller: _comentCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'Comentário (opcional)', alignLabelWithHint: true),
        ),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _enviando ? null : _enviar,
          child: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Enviar'),
        ),
      ],
    );
  }

  String get _textoNota {
    switch (_nota) {
      case 5:
        return 'Excelente! 🎉';
      case 4:
        return 'Muito bom! 👍';
      case 3:
        return 'Regular';
      case 2:
        return 'Ruim';
      default:
        return 'Muito ruim';
    }
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    await DatabaseService.inserirAvaliacao(AvaliacaoModel(
      deUsuarioId: widget.deUsuarioId,
      paraUsuarioId: widget.paraUsuarioId,
      propostaId: widget.propostaId,
      nota: _nota,
      comentario:
          _comentCtrl.text.trim().isEmpty ? null : _comentCtrl.text.trim(),
    ));
    if (mounted) Navigator.pop(context, true);
  }
}

class EmptyStateSimples extends StatelessWidget {
  final IconData icon;
  final String titulo;
  const EmptyStateSimples(
      {super.key, required this.icon, required this.titulo});
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
            size: 60, color: CafeColors.lightRoast.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text(titulo,
            style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                color: CafeColors.darkRoast,
                fontWeight: FontWeight.w700)),
      ]));
}
