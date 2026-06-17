// lib/screens/planos_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/planos_service.dart';
import '../services/app_state.dart';

class PlanosScreen extends StatelessWidget {
  const PlanosScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final atual = context.select<AppState, Plan?>((s) => s.plano);
    return Scaffold(
      appBar: AppBar(title: const Text('Planos')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (ctx, i) {
          final p = PlanosService.planos[i];
          final ativo = atual?.id == p.id;
          return ListTile(
            title: Text(p.nome),
            subtitle: Text('${p.features.join(' · ')}\nR\$ ${p.preco.toStringAsFixed(2)} / mês'),
            isThreeLine: true,
            trailing: ativo ? const Chip(label: Text('Ativo')) : ElevatedButton(
              onPressed: () {
                context.read<AppState>().upgradePlan(p);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Plano ${p.nome} ativado')));
              },
              child: const Text('Assinar')),
          );
        },
        separatorBuilder: (_, __) => const Divider(),
        itemCount: PlanosService.planos.length,
      ),
    );
  }
}
