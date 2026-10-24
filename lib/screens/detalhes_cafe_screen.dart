// lib/screens/detalhes_cafe_screen.dart

import '../utils/compartilhar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import '../widgets/acoes_anuncio.dart';
import '../widgets/frete_estimado.dart';
import '../models/cafe_model.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import 'nova_proposta_screen.dart';
import 'amostras_screen.dart';
import '../utils/conversa_lote.dart';

class DetalhesCafeScreen extends StatefulWidget {
  final CafeModel cafe;
  const DetalhesCafeScreen({super.key, required this.cafe});
  @override
  State<DetalhesCafeScreen> createState() => _DetalhesCafeScreenState();
}

class _DetalhesCafeScreenState extends State<DetalhesCafeScreen> {
  bool _favorito = false;
  List<Map<String, dynamic>> _provas = [];
  final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _checkFavorito();
    if (widget.cafe.id != null) ApiService.registrarVisualizacao(widget.cafe.id!);
    _carregarProvas();
  }

  Future<void> _carregarProvas() async {
    if (widget.cafe.id == null || context.read<AppState>().usuario == null) return;
    try {
      final p = await ApiService.getProvasDoLote(widget.cafe.id!);
      if (mounted) setState(() => _provas = p);
    } catch (_) {}
  }

  Future<void> _checkFavorito() async {
    final u = context.read<AppState>().usuario;
    if (u != null && widget.cafe.id != null) {
      final f = await ApiService.isFavorito(widget.cafe.id!);
      setState(() => _favorito = f);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cafe = widget.cafe;
    final usuario = context.read<AppState>().usuario;
    final meuAnuncio = usuario?.id == cafe.usuarioId;

    final podePropor = usuario != null && !meuAnuncio && usuario.tipo != 'produtor';
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
          ),
          child: usuario == null
              ? ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  icon: const Icon(Icons.login),
                  label: const Text('Entrar para conversar ou fazer proposta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CafeColors.caramel,
                    foregroundColor: CafeColors.espresso,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                )
              : meuAnuncio
                  // Dono do anúncio: gerenciar. Depois de qualquer ação volta para a
                  // lista, que recarrega com os dados novos.
                  ? AcoesAnuncio(cafe: cafe, onConcluido: (_) => Navigator.pop(context, true))
                  : Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => abrirConversaSobreLote(context, cafe),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Mensagem'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CafeColors.darkRoast,
                            side: const BorderSide(color: CafeColors.caramel),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                      if (podePropor) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => NovaPropostaScreen(cafe: cafe))),
                            icon: const Icon(Icons.assignment_outlined),
                            label: const Text('Fazer proposta'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CafeColors.caramel,
                              foregroundColor: CafeColors.espresso,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                          ),
                        ),
                      ],
                    ]),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              IconButton(
                tooltip: 'Compartilhar',
                icon: const Icon(Icons.share_outlined, color: CafeColors.cream),
                onPressed: () => compartilharLote(context, cafe),
              ),
              if (usuario != null)
                IconButton(
                  icon: Icon(_favorito ? Icons.favorite : Icons.favorite_border,
                      color: _favorito ? Colors.redAccent : CafeColors.cream),
                  onPressed: () async {
                    await ApiService.toggleFavorito(cafe.id!);
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
                child: cafe.fotos.isNotEmpty
                    ? _GaleriaFotos(fotos: cafe.fotos)
                    : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Text('☕', style: TextStyle(fontSize: 56)),
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
                              '${NumberFormat('#,###').format(cafe.quantidade)} sacas',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: CafeColors.caramel,
                              )),
                          if (cafe.precoSaca != null)
                            Text('${_brl.format(cafe.precoSaca)}/saca',
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
                  if (cafe.temFichaEspecial) ...[
                    _secao('Ficha do Café'),
                    _Card(children: [
                      if (cafe.variedade != null) _linha('Variedade', cafe.variedade!),
                      if (cafe.processamento != null) _linha('Processamento', cafe.processamento!),
                      if (cafe.altitude != null) _linha('Altitude', '${cafe.altitude} m'),
                      if (cafe.pontuacaoSca != null)
                        _linha('Pontuação SCA', cafe.pontuacaoSca!.toStringAsFixed(1).replaceAll('.', ',')),
                      if (cafe.certificacoes.isNotEmpty)
                        _linha('Certificações', cafe.certificacoes.join(', ')),
                    ]),
                  ],
                  if (_provas.isNotEmpty) ...[
                    _secao('Provas de amostra'),
                    _Card(children: [
                      for (final p in _provas)
                        _linha(
                          p['nota'] != null
                              ? 'Nota ${(p['nota'] as num).toStringAsFixed(1).replaceAll('.', ',')}'
                              : 'Prova',
                          _resumoProva(p),
                        ),
                    ]),
                  ],
                  if (usuario != null && !meuAnuncio && cafe.status == 'ativo') ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => pedirAmostra(context, cafe),
                      icon: const Icon(Icons.inventory_outlined),
                      label: const Text('Pedir amostra deste lote'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CafeColors.darkRoast,
                        side: const BorderSide(color: CafeColors.caramel),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                  _secao('Localização'),
                  _Card(children: [
                    _linha('Região', cafe.regiao),
                    _linha('Cidade', cafe.cidade),
                    _linha('Fazenda', cafe.fazenda ?? '—'),
                  ]),
                  if (!meuAnuncio) ...[
                    _secao('Frete estimado'),
                    FreteEstimado(cafe: cafe),
                  ],
                  _secao('Corretor Responsável'),
                  _Card(children: [
                    _linha('Nome', cafe.corretorNome ?? '—'),
                    _linha('Empresa', cafe.corretorEmpresa ?? '—'),
                    _linha('Contato', cafe.corretorTelefone ?? '—'),
                  ]),
                  const SizedBox(height: 24),
                  // Ligar/WhatsApp só quando o anunciante tem telefone cadastrado
                  if (!meuAnuncio && usuario != null && cafe.corretorTelefone != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _ligar(cafe.corretorTelefone),
                            icon: const Icon(Icons.phone),
                            label: const Text('Ligar'),
                            style: OutlinedButton.styleFrom(foregroundColor: CafeColors.greenOk),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _whatsapp(cafe.corretorTelefone),
                            icon: const Icon(Icons.chat),
                            label: const Text('WhatsApp'),
                            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF128C7E)),
                          ),
                        ),
                      ],
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

  String _resumoProva(Map<String, dynamic> p) {
    final partes = [
      if (p['bebida_resultado'] != null) '${p['bebida_resultado']}',
      if (p['defeitos'] != null) '${p['defeitos']} defeitos',
    ];
    return partes.isEmpty ? '—' : partes.join(' · ');
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
            const SizedBox(width: 12),
            Flexible(
              child: Text(v,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.dmSans(
                      color: CafeColors.darkRoast,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
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
      'vendido' => (CafeColors.blue, 'Vendido'),
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


/// Fotos do lote no topo da tela, com troca por arraste e indicador de posição.
class _GaleriaFotos extends StatefulWidget {
  final List<String> fotos;
  const _GaleriaFotos({required this.fotos});
  @override
  State<_GaleriaFotos> createState() => _GaleriaFotosState();
}

class _GaleriaFotosState extends State<_GaleriaFotos> {
  int _atual = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      PageView.builder(
        itemCount: widget.fotos.length,
        onPageChanged: (i) => setState(() => _atual = i),
        itemBuilder: (_, i) => Image.network(widget.fotos[i],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.broken_image, color: Colors.white54))),
      ),
      if (widget.fotos.length > 1)
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                widget.fotos.length,
                (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _atual ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                          color: i == _atual ? CafeColors.gold : Colors.white70,
                          borderRadius: BorderRadius.circular(4)),
                    )),
          ),
        ),
    ]);
  }
}
