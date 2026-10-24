// lib/screens/boas_vindas_screen.dart — primeira tela para quem não está logado
// (ex.: quem chega pelo link do LinkedIn). Mostra o que o app faz, números reais
// do Índice Café Conecta e deixa ver os lotes sem cadastro.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/cotacoes_service.dart';
import '../utils/theme.dart';
import 'cadastro_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class BoasVindasScreen extends StatefulWidget {
  const BoasVindasScreen({super.key});
  @override
  State<BoasVindasScreen> createState() => _BoasVindasScreenState();
}

class _BoasVindasScreenState extends State<BoasVindasScreen> {
  Map<String, dynamic>? _indice;
  double? _dolar;
  final _saca = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 0);
  final _int = NumberFormat.decimalPattern('pt_BR');

  @override
  void initState() {
    super.initState();
    _carregarNumeros();
  }

  Future<void> _carregarNumeros() async {
    try {
      final i = await CotacoesService.fetchIndice();
      if (mounted) setState(() => _indice = i);
    } catch (_) {}
    try {
      final a = await CotacoesService.fetchAtual();
      if (mounted) setState(() => _dolar = a.dolar?.cotacaoVenda);
    } catch (_) {}
  }

  void _abrir(Widget tela) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => tela));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [CafeColors.espresso, CafeColors.darkRoast, CafeColors.mediumRoast],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _cabecalho(),
                  const SizedBox(height: 28),
                  _numeros(),
                  const SizedBox(height: 28),
                  ..._recursos(),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: () => _abrir(const CatalogoPublicoScreen()),
                    icon: const Icon(Icons.coffee_outlined),
                    label: const Text('Ver lotes disponíveis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CafeColors.gold,
                      foregroundColor: CafeColors.espresso,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _abrir(const CadastroScreen()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CafeColors.cream,
                      side: const BorderSide(color: CafeColors.caramel),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Criar conta grátis'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _abrir(const LoginScreen()),
                    style: TextButton.styleFrom(foregroundColor: CafeColors.gold),
                    child: const Text('Já tenho conta · Entrar'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() => Column(children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: CafeColors.caramel.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: CafeColors.gold.withValues(alpha: 0.5), width: 2),
          ),
          child: const Center(child: Text('☕', style: TextStyle(fontSize: 40))),
        ),
        const SizedBox(height: 16),
        Text('CAFÉ CONECTA',
            style: GoogleFonts.playfairDisplay(
                color: CafeColors.gold, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 10),
        Text(
          'O marketplace do café: produtores, corretores e compradores negociando direto, '
          'com preço de referência e histórico de cada negócio.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(color: CafeColors.cream, fontSize: 15, height: 1.45),
        ),
      ]);

  // Números reais do app (somem enquanto ainda não há lotes)
  Widget _numeros() {
    final i = _indice;
    final lotes = (i?['total_lotes'] as num?)?.toInt() ?? 0;
    final sacas = (i?['total_sacas'] as num?)?.toInt() ?? 0;
    final arabica = ((i?['por_tipo'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .where((t) => t['tipo'] == 'Arábica')
        .firstOrNull;
    final itens = <(String, String)>[
      if (lotes > 0) ('${_int.format(lotes)}', lotes == 1 ? 'lote à venda' : 'lotes à venda'),
      if (sacas > 0) (_int.format(sacas), 'sacas anunciadas'),
      if (arabica != null) (_saca.format(arabica['preco_medio']), 'média arábica/saca'),
      if (_dolar != null)
        (NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 2).format(_dolar), 'dólar PTAX hoje'),
    ];
    if (itens.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final (valor, rotulo) in itens)
          Container(
            width: 125,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CafeColors.caramel.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              Text(valor,
                  style: GoogleFonts.playfairDisplay(
                      color: CafeColors.gold, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(rotulo,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(color: CafeColors.cream.withValues(alpha: 0.8), fontSize: 11)),
            ]),
          ),
      ],
    );
  }

  List<Widget> _recursos() {
    const itens = [
      (Icons.storefront_outlined, 'Anuncie seus lotes',
          'Tipo, bebida, peneira, safra, fotos e localização no mapa.'),
      (Icons.handshake_outlined, 'Negocie direto',
          'Propostas, contrapropostas e chat com quem compra ou vende.'),
      (Icons.show_chart, 'Preço de referência',
          'Índice Café Conecta, café na B3 e dólar ao vivo.'),
      (Icons.notifications_active_outlined, 'Alertas de preço',
          'Saiba quando aparece o lote que você procura.'),
    ];
    return [
      for (final (icone, titulo, texto) in itens)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: CafeColors.caramel.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, color: CafeColors.gold, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titulo,
                    style: GoogleFonts.dmSans(
                        color: CafeColors.cream, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(texto,
                    style: GoogleFonts.dmSans(
                        color: CafeColors.cream.withValues(alpha: 0.75), fontSize: 13, height: 1.35)),
              ]),
            ),
          ]),
        ),
    ];
  }
}

/// Catálogo aberto, sem login. Para conversar ou propor, o app pede para entrar.
class CatalogoPublicoScreen extends StatelessWidget {
  const CatalogoPublicoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeScreen(acoes: [
      TextButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const LoginScreen())),
        style: TextButton.styleFrom(foregroundColor: CafeColors.gold),
        child: const Text('Entrar'),
      ),
      const SizedBox(width: 8),
    ]);
  }
}
