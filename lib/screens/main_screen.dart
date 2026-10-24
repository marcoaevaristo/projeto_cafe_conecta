// lib/screens/main_screen.dart — navegação principal
// Celular: barra inferior com 5 itens (Início, Catálogo, Propostas, Mensagens, Menu)
//          e menu lateral com o restante.
// Tela larga (computador/tablet): menu lateral fixo com tudo, sem barra inferior.
import 'pedidos_compra_screen.dart';
import 'amostras_screen.dart';
import 'custo_margem_screen.dart';
import 'boas_vindas_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/theme.dart';
import '../widgets/upgrade_gate.dart';
import 'ajuda_screen.dart';
import 'alertas_screen.dart';
import 'avaliacoes_screen.dart';
import 'classificacao_ia_screen.dart';
import 'configuracoes_screen.dart';
import 'cotacoes_screen.dart';
import 'dashboard_screen.dart';
import 'historico_precos_screen.dart';
import 'home_screen.dart';
import 'liberar_plano_screen.dart';
import 'login_screen.dart';
import 'mapa_screen.dart';
import 'mensagens_screen.dart';
import 'meus_anuncios_screen.dart';
import 'painel_admin_screen.dart';
import 'perfil_screen.dart';
import 'planos_screen.dart';
import 'propostas_screen.dart';

// Posições das telas dentro do IndexedStack
const _inicio = 0, _catalogo = 1, _mapa = 2, _cotacoes = 3, _alertas = 4,
    _propostas = 5, _mensagens = 6, _perfil = 7;

// Itens da barra inferior (celular) e a tela de cada um; o 5º é o botão Menu
const _barra = [_inicio, _catalogo, _propostas, _mensagens];

// A partir desta largura o menu lateral fica fixo
const _larguraTelaLarga = 840.0;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = _inicio;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _screens = const [
    DashboardScreen(),
    HomeScreen(),
    UpgradeGate(
        requiredTier: 2,
        titulo: 'Mapa de Disponibilidade',
        message: 'O mapa de disponibilidade faz parte dos planos Profissional e Premium.',
        child: MapaScreen()),
    CotacoesScreen(),
    AlertasScreen(),
    PropostasScreen(),
    MensagensScreen(),
    PerfilScreen(),
  ];

  void _irPara(int i) {
    setState(() => _index = i);
    if (i == _mensagens || i == _propostas) context.read<AppState>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final largo = MediaQuery.sizeOf(context).width >= _larguraTelaLarga;
    final corpo = IndexedStack(index: _index, children: _screens);

    if (largo) {
      return Scaffold(
        body: Row(children: [
          SizedBox(
            width: 260,
            child: Material(
              color: CafeColors.espresso,
              child: _MenuNavegacao(atual: _index, aoSelecionar: _irPara, completo: true),
            ),
          ),
          Expanded(child: corpo),
        ]),
      );
    }

    final state = context.watch<AppState>();
    final posicao = _barra.indexOf(_index);
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: CafeColors.espresso,
        child: _MenuNavegacao(
          atual: _index,
          completo: false,
          aoSelecionar: (i) {
            Navigator.pop(context); // fecha o menu
            _irPara(i);
          },
          antesDeAbrir: () => Navigator.pop(context),
        ),
      ),
      body: corpo,
      bottomNavigationBar: BottomNavigationBar(
        // telas que não estão na barra (Mapa, Alertas, Perfil...) destacam o "Menu"
        currentIndex: posicao >= 0 ? posicao : 4,
        onTap: (p) {
          if (p == 4) {
            _scaffoldKey.currentState?.openDrawer();
          } else {
            _irPara(_barra[p]);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 11),
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Início'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.coffee_outlined),
              activeIcon: Icon(Icons.coffee),
              label: 'Catálogo'),
          BottomNavigationBarItem(
              icon: _ComContador(
                  icone: Icons.assignment_outlined, total: state.propostasNaoLidas),
              activeIcon: _ComContador(icone: Icons.assignment, total: state.propostasNaoLidas),
              label: 'Propostas'),
          BottomNavigationBarItem(
              icon: _ComContador(icone: Icons.message_outlined, total: state.msgNaoLidas),
              activeIcon: _ComContador(icone: Icons.message, total: state.msgNaoLidas),
              label: 'Mensagens'),
          const BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        ],
      ),
    );
  }
}

// ── Ícone com bolinha de contagem ─────────────────────────────────────
class _ComContador extends StatelessWidget {
  final IconData icone;
  final int total;
  const _ComContador({required this.icone, required this.total});

  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        Icon(icone),
        if (total > 0)
          Positioned(
            top: -4,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                  color: CafeColors.redAlert, borderRadius: BorderRadius.circular(10)),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(total > 99 ? '99+' : '$total',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                      fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
      ]);
}

// ── Menu lateral (gaveta no celular, coluna fixa na tela larga) ───────
class _MenuNavegacao extends StatelessWidget {
  final int atual;
  final void Function(int) aoSelecionar;
  /// Na tela larga mostra também os itens que no celular ficam na barra inferior
  final bool completo;
  /// No celular, fecha a gaveta antes de abrir outra tela
  final VoidCallback? antesDeAbrir;

  const _MenuNavegacao({
    required this.atual,
    required this.aoSelecionar,
    required this.completo,
    this.antesDeAbrir,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final u = state.usuario;

    void abrir(Widget tela) {
      // pega o Navigator antes: no celular a gaveta fecha e este contexto deixa de existir
      final navigator = Navigator.of(context);
      antesDeAbrir?.call();
      navigator.push(MaterialPageRoute(builder: (_) => tela));
    }

    Widget item(IconData icone, String texto, {int? tela, Widget? abre, int contador = 0}) {
      final selecionado = tela != null && tela == atual;
      return ListTile(
        dense: true,
        selected: selecionado,
        selectedTileColor: CafeColors.caramel.withValues(alpha: 0.18),
        leading: _ComContador(icone: icone, total: contador),
        iconColor: CafeColors.cream.withValues(alpha: 0.75),
        selectedColor: CafeColors.gold,
        textColor: CafeColors.cream,
        title: Text(texto,
            style: GoogleFonts.dmSans(
                fontSize: 14, fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500)),
        onTap: () => tela != null ? aoSelecionar(tela) : abrir(abre!),
      );
    }

    Widget secao(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(t.toUpperCase(),
              style: GoogleFonts.dmSans(
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: CafeColors.caramel)),
        );

    return SafeArea(
      child: ListView(padding: EdgeInsets.zero, children: [
        // Cabeçalho: quem está logado; toque abre o Perfil
        InkWell(
          onTap: () => aoSelecionar(_perfil),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: CafeColors.caramel.withValues(alpha: 0.3),
                child: Text((u?.nome.isNotEmpty ?? false) ? u!.nome[0].toUpperCase() : '?',
                    style: GoogleFonts.playfairDisplay(
                        color: CafeColors.gold, fontWeight: FontWeight.w700, fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u?.nome ?? 'Café Conecta',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                          color: CafeColors.cream, fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('Plano ${state.plano.nome} · ver perfil',
                      style: GoogleFonts.dmSans(color: CafeColors.caramel, fontSize: 11)),
                ]),
              ),
            ]),
          ),
        ),
        const Divider(color: Colors.white12, height: 1),

        if (completo) ...[
          secao('Principal'),
          item(Icons.dashboard_outlined, 'Início', tela: _inicio),
          item(Icons.coffee_outlined, 'Catálogo', tela: _catalogo),
          item(Icons.assignment_outlined, 'Propostas',
              tela: _propostas, contador: state.propostasNaoLidas),
          item(Icons.message_outlined, 'Mensagens',
              tela: _mensagens, contador: state.msgNaoLidas),
        ],

        secao('Mercado'),
        item(Icons.map_outlined, 'Mapa de disponibilidade', tela: _mapa),
        item(Icons.show_chart_outlined, 'Cotações', tela: _cotacoes),
        item(Icons.shopping_basket_outlined, 'Pedidos de compra', abre: const PedidosCompraScreen()),
        item(Icons.inventory_outlined, 'Amostras', abre: const AmostrasScreen()),
        item(Icons.notifications_outlined, 'Alertas de preço', tela: _alertas),
        item(Icons.query_stats_outlined, 'Histórico de preços',
            abre: const UpgradeGate(
                requiredTier: 1,
                titulo: 'Histórico de Preços',
                message: 'O histórico de preços faz parte dos planos pagos, a partir do Básico.',
                child: HistoricoPrecosScreen())),

        secao('Meu negócio'),
        item(Icons.inventory_2_outlined, 'Meus anúncios', abre: const MeusAnunciosScreen()),
        item(Icons.calculate_outlined, 'Custo e margem', abre: const CustoMargemScreen()),
        item(Icons.smart_toy_outlined, 'Classificação por IA', abre: const ClassificacaoIAScreen()),
        if (u?.id != null)
          item(Icons.star_outline, 'Minhas avaliações',
              abre: AvaliacoesScreen(usuarioId: u!.id!, usuarioNome: u.empresa ?? u.nome)),

        secao('Conta'),
        item(Icons.person_outline, 'Perfil', tela: _perfil),
        item(Icons.card_membership_outlined, 'Assinatura', abre: const PlanosScreen()),
        item(Icons.settings_outlined, 'Configurações', abre: const ConfiguracoesScreen()),
        item(Icons.help_outline, 'Ajuda e contato', abre: const AjudaScreen()),

        if (u?.isAdmin == true) ...[
          secao('Administração'),
          item(Icons.insights_outlined, 'Painel do desenvolvedor', abre: const PainelAdminScreen()),
          item(Icons.card_giftcard_outlined, 'Liberar plano (cortesia)',
              abre: const LiberarPlanoScreen()),
        ],

        const Divider(color: Colors.white12, height: 24),
        ListTile(
          dense: true,
          leading: const Icon(Icons.logout, color: CafeColors.redAlert),
          title: Text('Sair da conta',
              style: GoogleFonts.dmSans(color: CafeColors.redAlert, fontWeight: FontWeight.w600)),
          onTap: () async {
            final navigator = Navigator.of(context);
            await context.read<AppState>().logout();
            navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const BoasVindasScreen()), (_) => false);
          },
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}
