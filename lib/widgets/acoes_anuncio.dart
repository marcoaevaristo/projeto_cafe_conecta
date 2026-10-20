// lib/widgets/acoes_anuncio.dart — Editar, Pausar/Reativar, Encerrar e Excluir
// um anúncio do próprio usuário. Usado em "Meus anúncios" e nos detalhes do lote.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/cafe_model.dart';
import '../screens/novo_anuncio_screen.dart';
import '../services/api_service.dart';
import '../utils/erros.dart';
import '../utils/theme.dart';

/// O que aconteceu com o anúncio depois de uma ação.
enum ResultadoAcao { alterado, excluido }

class AcoesAnuncio extends StatefulWidget {
  final CafeModel cafe;

  /// Chamado depois de uma ação concluída (para recarregar a lista ou fechar a tela).
  final void Function(ResultadoAcao) onConcluido;

  const AcoesAnuncio({super.key, required this.cafe, required this.onConcluido});

  @override
  State<AcoesAnuncio> createState() => _AcoesAnuncioState();
}

class _AcoesAnuncioState extends State<AcoesAnuncio> {
  bool _ocupado = false;

  Future<void> _executar(Future<void> Function() acao, String sucesso,
      ResultadoAcao resultado) async {
    setState(() => _ocupado = true);
    try {
      await acao();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(sucesso)));
      widget.onConcluido(resultado);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<bool> _confirmar(String titulo, String texto, String botao,
      {bool perigo = false}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: perigo ? CafeColors.redAlert : CafeColors.caramel),
            child: Text(botao),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _editar() async {
    final salvou = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => NovoAnuncioScreen(cafe: widget.cafe)));
    if (salvou == true) widget.onConcluido(ResultadoAcao.alterado);
  }

  Future<void> _status(String novo) async {
    final id = widget.cafe.id!;
    switch (novo) {
      case 'pausado':
        if (!await _confirmar('Pausar anúncio?',
            'O lote sai do catálogo até você reativar. Nada é apagado.', 'Pausar')) {
          return;
        }
        return _executar(() => ApiService.atualizarStatusCafe(id, 'pausado'),
            'Anúncio pausado', ResultadoAcao.alterado);
      case 'encerrado':
        if (!await _confirmar('Encerrar anúncio?',
            'Use quando o lote foi vendido ou não está mais disponível. Ele sai do catálogo e fica em "Encerrados".',
            'Encerrar')) {
          return;
        }
        return _executar(() => ApiService.atualizarStatusCafe(id, 'encerrado'),
            'Anúncio encerrado', ResultadoAcao.alterado);
      default:
        return _executar(() => ApiService.atualizarStatusCafe(id, 'ativo'),
            'Anúncio reativado e de volta ao catálogo', ResultadoAcao.alterado);
    }
  }

  Future<void> _excluir() async {
    if (!await _confirmar(
        'Excluir anúncio?',
        'O anúncio e as fotos serão apagados de vez. Se o lote já recebeu propostas, '
            'ele não pode ser excluído: encerre o anúncio para manter o histórico.',
        'Excluir',
        perigo: true)) {
      return;
    }
    await _executar(() => ApiService.excluirCafe(widget.cafe.id!),
        'Anúncio excluído', ResultadoAcao.excluido);
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.cafe.status;
    if (_ocupado) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(
            child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    final estilo = GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600);
    Widget botao(IconData icone, String rotulo, VoidCallback acao, {Color? cor}) =>
        TextButton.icon(
          onPressed: acao,
          icon: Icon(icone, size: 18),
          label: Text(rotulo, style: estilo),
          style: TextButton.styleFrom(
            foregroundColor: cor ?? CafeColors.darkRoast,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        );

    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 4,
      children: [
        botao(Icons.edit_outlined, 'Editar', _editar),
        if (status == 'ativo')
          botao(Icons.pause_circle_outline, 'Pausar', () => _status('pausado'))
        else
          botao(Icons.play_circle_outline, 'Reativar', () => _status('ativo'),
              cor: CafeColors.greenOk),
        if (status != 'encerrado')
          botao(Icons.check_circle_outline, 'Encerrar', () => _status('encerrado')),
        botao(Icons.delete_outline, 'Excluir', _excluir, cor: CafeColors.redAlert),
      ],
    );
  }
}
