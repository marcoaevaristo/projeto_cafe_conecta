// lib/screens/mensagens_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../widgets/cafe_card.dart';
import 'conversa_screen.dart';
import 'login_screen.dart';

class MensagensScreen extends StatefulWidget {
  const MensagensScreen({super.key});
  @override
  State<MensagensScreen> createState() => _MensagensScreenState();
}

class _MensagensScreenState extends State<MensagensScreen> {
  List<Map<String, dynamic>> _conversas = [];
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregar();
  }

  Future<void> _carregar() async {
    final u = context.read<AppState>().usuario;
    if (u == null) return;
    setState(() => _loading = true);
    final c = await DatabaseService.getConversas(u.id!);
    setState(() {
      _conversas = c;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final logado = context.watch<AppState>().logado;
    return Scaffold(
      appBar: AppBar(title: const Text('Mensagens')),
      body: !logado
          ? const EmptyState(
              icon: Icons.message_outlined,
              titulo: 'Faça login para ver mensagens',
              action: ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Entrar'),
              ),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _conversas.isEmpty
                  ? const EmptyState(
                      icon: Icons.inbox_outlined,
                      titulo: 'Nenhuma conversa ainda',
                      subtitulo:
                          'Inicie uma conversa pelos detalhes de um café.',
                    )
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      child: ListView.builder(
                        itemCount: _conversas.length,
                        itemBuilder: (_, i) => _buildConversa(_conversas[i]),
                      ),
                    ),
    );
  }

  Widget _buildConversa(Map<String, dynamic> c) {
    final naoLida =
        c['de_usuario_id'] != context.read<AppState>().usuario!.id &&
            c['lida'] == 0;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: CafeColors.darkRoast,
        child: Text(
          (c['contato_nome'] as String? ?? 'U').substring(0, 1).toUpperCase(),
          style: GoogleFonts.playfairDisplay(
              color: CafeColors.gold, fontWeight: FontWeight.w700),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              c['contato_empresa'] ?? c['contato_nome'] ?? 'Usuário',
              style: GoogleFonts.dmSans(
                fontWeight: naoLida ? FontWeight.w700 : FontWeight.w500,
                color: CafeColors.espresso,
              ),
            ),
          ),
          if (c['contato_verificado'] == 1)
            const Icon(Icons.verified, size: 16, color: CafeColors.caramel),
        ],
      ),
      subtitle: Text(
        c['ultima_mensagem'] ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          color: naoLida ? CafeColors.darkRoast : CafeColors.lightRoast,
          fontWeight: naoLida ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: naoLida
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                  color: CafeColors.caramel, shape: BoxShape.circle),
            )
          : null,
      onTap: () async {
        await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConversaScreen(
                contatoId: c['contato_id'] as int,
                contatoNome: c['contato_nome'] ?? 'Usuário',
                contatoEmpresa: c['contato_empresa'],
              ),
            ));
        _carregar();
      },
    );
  }
}
