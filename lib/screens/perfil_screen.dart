// lib/screens/perfil_screen.dart — v3
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/theme.dart';
import '../widgets/cafe_card.dart';
import 'login_screen.dart';
import 'meus_anuncios_screen.dart';
import 'avaliacoes_screen.dart';
import 'historico_precos_screen.dart';
import 'cotacoes_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? _dadosCompletos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregar();
  }

  Future<void> _carregar() async {
    final u = context.read<AppState>().usuario;
    if (u?.id != null) {
      // simplified load
      setState(() => _dadosCompletos = {
            'media_avaliacao': 4.8,
            'total_avaliacoes': 47,
            'lotes_ativos': 3,
            'negocios_fechados': 23
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final u = state.usuario;

    if (!state.logado) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const EmptyState(
            icon: Icons.person_outline,
            titulo: 'Faça login para acessar seu perfil',
            action: ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Entrar'))),
      );
    }

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [CafeColors.espresso, CafeColors.mediumRoast],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight)),
              child: SafeArea(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            CafeColors.caramel.withValues(alpha: 0.25),
                        child: Text((u!.nome).substring(0, 1).toUpperCase(),
                            style: GoogleFonts.playfairDisplay(
                                color: CafeColors.gold,
                                fontSize: 30,
                                fontWeight: FontWeight.w700))),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(u.empresa ?? u.nome,
                          style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      if (u.verificado) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified,
                            color: CafeColors.caramel, size: 18)
                      ],
                    ]),
                    Text(u.tipo.toUpperCase(),
                        style: GoogleFonts.dmSans(
                            color: CafeColors.caramel,
                            fontSize: 11,
                            letterSpacing: 0.15)),
                    // Estrelas de avaliação
                    if (_dadosCompletos != null) ...[
                      const SizedBox(height: 6),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...List.generate(
                                5,
                                (i) => Icon(
                                    i <
                                            (_dadosCompletos!['media_avaliacao']
                                                    as num)
                                                .round()
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: CafeColors.gold,
                                    size: 16)),
                            const SizedBox(width: 6),
                            Text(
                                '${_dadosCompletos!['media_avaliacao']} (${_dadosCompletos!['total_avaliacoes']} avaliações)',
                                style: GoogleFonts.dmSans(
                                    color:
                                        CafeColors.cream.withValues(alpha: 0.7),
                                    fontSize: 11)),
                          ]),
                    ],
                  ])),
            ),
          ),
        ),
        SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  // Mini stats
                  if (_dadosCompletos != null)
                    Row(children: [
                      const _StatMini(
                          label: 'Lotes ativos',
                          value: '${_dadosCompletos!['lotes_ativos']}',
                          icon: '☕'),
                      const SizedBox(width: 10),
                      const _StatMini(
                          label: 'Negócios',
                          value: '${_dadosCompletos!['negocios_fechados']}',
                          icon: '🤝'),
                      const SizedBox(width: 10),
                      const _StatMini(
                          label: 'Avaliação',
                          value: '${_dadosCompletos!['media_avaliacao']}⭐',
                          icon: '🏆'),
                    ]),
                  const SizedBox(height: 14),
                  // Info card
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(children: [
                            _infoRow(Icons.person_outline, u.nome),
                            _infoRow(Icons.email_outlined, u.email),
                            if (u.telefone != null)
                              _infoRow(Icons.phone_outlined, u.telefone!),
                            if (u.regiao != null)
                              _infoRow(Icons.location_on_outlined, u.regiao!),
                          ]))),
                  const SizedBox(height: 12),
                  // Menu
                  Card(
                      child: Column(children: [
                    if (u.tipo == 'corretor')
                      _menuItem(
                          Icons.inventory_2_outlined,
                          'Meus Anúncios',
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MeusAnunciosScreen()))),
                    _menuItem(
                        Icons.star_outline,
                        'Minhas Avaliações',
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AvaliacoesScreen(
                                    usuarioId: u.id!,
                                    usuarioNome: u.empresa ?? u.nome)))),
                    _menuItem(
                        Icons.trending_up,
                        'Cotações de Mercado',
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CotacoesScreen()))),
                    _menuItem(
                        Icons.show_chart_outlined,
                        'Histórico de Preços',
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const HistoricoPrecosScreen()))),
                    _menuItem(
                        Icons.card_membership_outlined,
                        'Assinatura',
                        () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Em breve!')))),
                    _menuItem(
                        Icons.settings_outlined,
                        'Configurações',
                        () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Em breve!')))),
                    _menuItem(
                        Icons.help_outline,
                        'Ajuda e Suporte',
                        () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Em breve!')))),
                  ])),
                  const SizedBox(height: 14),
                  SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<AppState>().logout();
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                              (_) => false);
                        },
                        icon: const Icon(Icons.logout,
                            color: CafeColors.redAlert),
                        label: Text('Sair da Conta',
                            style: GoogleFonts.dmSans(
                                color: CafeColors.redAlert,
                                fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: CafeColors.redAlert
                                    .withValues(alpha: 0.4))),
                      )),
                  const SizedBox(height: 30),
                ]))),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 16, color: CafeColors.lightRoast),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: CafeColors.darkRoast,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis)),
      ]));

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) => ListTile(
        leading: Icon(icon, color: CafeColors.caramel),
        title:
            Text(label, style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: CafeColors.lightRoast),
        onTap: onTap,
      );
}

class _StatMini extends StatelessWidget {
  final String label, value, icon;
  const _StatMini(
      {required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Expanded(
          child: Card(
              child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CafeColors.darkRoast)),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 10, color: CafeColors.lightRoast),
              textAlign: TextAlign.center),
        ]),
      )));
}
