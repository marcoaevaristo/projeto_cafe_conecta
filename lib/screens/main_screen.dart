// lib/screens/main_screen.dart — v3
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/theme.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';
import 'mapa_screen.dart';
import 'alertas_screen.dart';
import 'propostas_screen.dart';
import 'mensagens_screen.dart';
import 'perfil_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    HomeScreen(),
    MapaScreen(),
    AlertasScreen(),
    PropostasScreen(),
    MensagensScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) { setState(() => _index = i); if (i == 5) state.refresh(); },
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 10),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 10),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          const BottomNavigationBarItem(icon: Icon(Icons.coffee_outlined), activeIcon: Icon(Icons.coffee), label: 'Catálogo'),
          const BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Mapa'),
          const BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Alertas'),
          BottomNavigationBarItem(
            icon: Stack(clipBehavior: Clip.none, children: [
              const Icon(Icons.assignment_outlined),
              if (state.propostasNaoLidas > 0)
                Positioned(top: -4, right: -6, child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: CafeColors.redAlert, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                  child: Text('${state.propostasNaoLidas}', textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                )),
            ]),
            activeIcon: const Icon(Icons.assignment),
            label: 'Propostas',
          ),
          BottomNavigationBarItem(
            icon: Stack(clipBehavior: Clip.none, children: [
              const Icon(Icons.message_outlined),
              if (state.msgNaoLidas > 0)
                Positioned(top: -4, right: -6, child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: CafeColors.redAlert, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                  child: Text('${state.msgNaoLidas}', textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                )),
            ]),
            activeIcon: const Icon(Icons.message),
            label: 'Mensagens',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
