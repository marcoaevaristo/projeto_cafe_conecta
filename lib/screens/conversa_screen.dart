// lib/screens/conversa_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/cafe_model.dart';
import '../services/app_state.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';

class ConversaScreen extends StatefulWidget {
  final int contatoId;
  final String contatoNome;
  final String? contatoEmpresa;
  const ConversaScreen(
      {super.key,
      required this.contatoId,
      required this.contatoNome,
      this.contatoEmpresa});
  @override
  State<ConversaScreen> createState() => _ConversaScreenState();
}

class _ConversaScreenState extends State<ConversaScreen> {
  List<MensagemModel> _msgs = [];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final u = context.read<AppState>().usuario!;
    final list =
        await DatabaseService.getMensagensConversa(u.id!, widget.contatoId);
    setState(() => _msgs = list);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _enviar() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty) return;
    final u = context.read<AppState>().usuario!;
    _ctrl.clear();
    await DatabaseService.enviarMensagem(u.id!, widget.contatoId, texto);
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final meuId = context.read<AppState>().usuario!.id!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.contatoEmpresa ?? widget.contatoNome,
                style: GoogleFonts.playfairDisplay(
                    color: CafeColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            if (widget.contatoEmpresa != null)
              Text(widget.contatoNome,
                  style: GoogleFonts.dmSans(
                      color: CafeColors.cream.withValues(alpha: 0.7), fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _msgs.isEmpty
                ? Center(
                    child: Text('Inicie a conversa abaixo.',
                        style:
                            GoogleFonts.dmSans(color: CafeColors.lightRoast)))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _msgs.length,
                    itemBuilder: (_, i) => _buildBubble(_msgs[i], meuId),
                  ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBubble(MensagemModel msg, int meuId) {
    final minha = msg.deUsuarioId == meuId;
    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: minha ? CafeColors.caramel : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: minha ? const Radius.circular(16) : Radius.zero,
            bottomRight: minha ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              minha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg.texto,
                style: GoogleFonts.dmSans(
                  color: minha ? CafeColors.espresso : CafeColors.darkRoast,
                  fontSize: 14,
                )),
            const SizedBox(height: 4),
            Text(
              msg.criadoEm != null ? _formatarHora(msg.criadoEm!) : '',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: minha
                    ? CafeColors.espresso.withValues(alpha: 0.5)
                    : CafeColors.lightRoast,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarHora(String dt) {
    try {
      final d = DateTime.parse(dt);
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                hintText: 'Digite uma mensagem...',
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                isDense: true,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _enviar(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: CafeColors.caramel,
            child: IconButton(
              icon:
                  const Icon(Icons.send, color: CafeColors.espresso, size: 18),
              onPressed: _enviar,
            ),
          ),
        ],
      ),
    );
  }
}
