import 'screens/detalhes_cafe_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/app_state.dart';
import 'utils/theme.dart';
import 'screens/boas_vindas_screen.dart';
import 'screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const CafeConectaApp(),
    ),
  );
}

class CafeConectaApp extends StatelessWidget {
  const CafeConectaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Café Conecta',
      debugShowCheckedModeBanner: false,
      theme: CafeTheme.theme,
      home: const _Splash(),
      scrollBehavior: kIsWeb ? const _WebScrollBehavior() : null,
    );
  }
}

class _WebScrollBehavior extends ScrollBehavior {
  const _WebScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      child: child,
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash();
  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final state = context.read<AppState>();
    await state.tryRestoreSession();
    ApiService.registrarVisita(); // sem await: não atrasa a abertura
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => state.logado ? const MainScreen() : const BoasVindasScreen(),
      ),
    );
    // Chegou por um link compartilhado (?lote=ID): abre o lote por cima
    final loteId = Uri.base.queryParameters['lote'];
    if (loteId != null && loteId.isNotEmpty) {
      try {
        final cafe = await ApiService.getCafe(loteId);
        navigator.push(MaterialPageRoute(builder: (_) => DetalhesCafeScreen(cafe: cafe)));
      } catch (_) {
        // lote removido ou link inválido: segue na tela inicial
      }
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}