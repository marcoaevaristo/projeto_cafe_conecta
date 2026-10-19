// lib/widgets/upgrade_gate.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/planos_service.dart';
import '../services/app_state.dart';
import '../screens/planos_screen.dart';

class UpgradeGate extends StatelessWidget {
  final int requiredTier;
  final Widget child;
  final String? message;
  /// Quando informado, o bloqueio ocupa a tela inteira com este título na barra.
  final String? titulo;

  const UpgradeGate(
      {super.key,
      required this.requiredTier,
      required this.child,
      this.message,
      this.titulo});

  @override
  Widget build(BuildContext context) {
    final has =
        context.select<AppState, bool>((s) => s.hasAccessForTier(requiredTier));
    if (has) return child;

    if (titulo != null) {
      return Scaffold(
        appBar: AppBar(title: Text(titulo!)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_outline, size: 56, color: Colors.grey),
              const SizedBox(height: 16),
              Text(message ?? 'Recurso disponível para planos pagos.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PlanosScreen())),
                child: const Text('Ver Planos'),
              ),
            ]),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message ?? 'Recurso disponível para planos pagos.',
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PlanosScreen())),
            child: const Text('Ver Planos'),
          )
        ]),
      ),
    );
  }
}
