// lib/screens/detalhes_cafe_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cafe_model.dart';
import '../services/app_state.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import 'conversa_screen.dart';

class DetalhesCafeScreen extends StatefulWidget {
  final CafeModel cafe;
  const DetalhesCafeScreen({super.key, required this.cafe});
  @override
  State<DetalhesCafeScreen> createState() => _DetalhesCafeScreenState();
}

class _DetalhesCafeScreenState extends State<DetalhesCafeScreen> {
  bool _favorito = false;
  final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _checkFavorito();
  }

  Future<void> _checkFavorito() async {
    final u = context.read<AppState>().usuario;
    if (u != null && widget.cafe.id != null) {
      final f = await DatabaseService.isFavorito(u.id!, widget.cafe.id!);
      setState(() => _favorito = f);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cafe = widget.cafe;
    final usuario = context.read<AppState>().usuario;
    final meuAnuncio = usuario?.id == cafe.usuarioId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              if (usuario != null)
                IconButton(
                  icon: Icon(_favorito ? Icons.favorite : Icons.favorite_border,
                      color: _favorito ? Colors.redAccent : CafeColors.cream),
                  onPressed: () async {
                    await DatabaseService.toggleFavorito(usuario.id!, cafe.id!);
                    setState(() => _favorito = !_favorito);
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [CafeColors.espresso, CafeColors.mediumRoast],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text('☕', style: const TextStyle(fontSize: 56)),
                      Text(cafe.nomeCurto,
                          style: GoogleFonts.playfairDisplay(
                            color: CafeColors.gold,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + Qtd + Preço
                  Row(
                    children: [
                      _StatusChip(cafe.status),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                              NumberFormat('#,###').format(cafe.quantidade) +
                                  ' sacas',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: CafeColors.caramel,
                              )),
                          if (cafe.precoSaca != null)
                            Text(_brl.format(cafe.precoSaca) + '/saca',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: CafeColors.greenOk,
                                )),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _secao('Especificações do Café'),
                  _Card(children: [
                    _linha('Tipo', cafe.tipo),
                    _linha('Classificação', cafe.classificacao),
                    _linha('Bebida', cafe.bebida ?? '—'),
                    _linha('Peneira', cafe.peneira ?? '—'),
                    _linha('Safra', cafe.safra ?? '—'),
                  ]),
                  _secao('Localização'),
                  _Card(children: [
                    _linha('Região', cafe.regiao),
                    _linha('Cidade', cafe.cidade),
                    _linha('Fazenda', cafe.fazenda ?? '—'),
                  ]),
                  _secao('Corretor Responsável'),
                  _Card(children: [
                    _linha('Nome', cafe.corretorNome ?? '—'),
                    _linha('Empresa', cafe.corretorEmpresa ?? '—'),
                    _linha('Contato', cafe.corretorTelefone ?? '—'),
                  ]),
                  const SizedBox(height: 24),
                  if (!meuAnuncio && usuario != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _ligar(cafe.corretorTelefone),
                            icon: const Icon(Icons.phone),
                            label: const Text('Ligar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CafeColors.greenOk,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _whatsapp(cafe.corretorTelefone),
                            icon: const Icon(Icons.chat),
                            label: const Text('WhatsApp'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConversaScreen(
                                contatoId: cafe.usuarioId,
                                contatoNome: cafe.corretorNome ?? 'Corretor',
                                contatoEmpresa: cafe.corretorEmpresa,
                              ),
                            )),
                        icon: const Icon(Icons.message_outlined),
                        label: const Text('Enviar Mensagem no App'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CafeColors.darkRoast,
                          side: const BorderSide(color: CafeColors.lightRoast),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _secao(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 16),
        child: Text(t,
            style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CafeColors.darkRoast)),
      );

  Widget _linha(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l,
                style: GoogleFonts.dmSans(
                    color: CafeColors.lightRoast,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            Text(v,
                style: GoogleFonts.dmSans(
                    color: CafeColors.darkRoast,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Future<void> _ligar(String? tel) async {
    if (tel == null) return;
    final num = tel.replaceAll(RegExp(r'[^\d+]'), '');
    await launchUrl(Uri.parse('tel:$num'));
  }

  Future<void> _whatsapp(String? tel) async {
    if (tel == null) return;
    final num = '55${tel.replaceAll(RegExp(r'[^\d]'), '')}';
    await launchUrl(Uri.parse('https://wa.me/$num'),
        mode: LaunchMode.externalApplication);
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: children),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);
  @override
  Widget build(BuildContext context) {
    final cfg = switch (status) {
      'ativo' => (CafeColors.greenOk, 'Disponível'),
      'pausado' => (Colors.amber.shade700, 'Pausado'),
      'encerrado' => (CafeColors.redAlert, 'Encerrado'),
      _ => (Colors.grey, status),
    };
    return Chip(
      avatar: CircleAvatar(backgroundColor: cfg.$1, radius: 5),
      label: Text(cfg.$2,
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
      backgroundColor: cfg.$1.withValues(alpha: 0.1),
      side: BorderSide(color: cfg.$1.withValues(alpha: 0.3)),
    );
  }
}
