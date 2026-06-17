// lib/screens/favoritos_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cafe_model.dart';
import '../services/app_state.dart';
import '../services/database_service.dart';
import '../widgets/cafe_card.dart';
import 'detalhes_cafe_screen.dart';
import 'login_screen.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});
  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  List<CafeModel> _favs = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregar();
  }

  Future<void> _carregar() async {
    final u = context.read<AppState>().usuario;
    if (u == null) return;
    final list = await DatabaseService.getFavoritos(u.id!);
    setState(() => _favs = list);
  }

  @override
  Widget build(BuildContext context) {
    final logado = context.watch<AppState>().logado;
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Favoritos')),
      body: !logado
          ? EmptyState(
              icon: Icons.favorite_border,
              titulo: 'Faça login para ver favoritos',
              action: ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Entrar'),
              ),
            )
          : _favs.isEmpty
              ? const EmptyState(
                  icon: Icons.favorite_outline,
                  titulo: 'Nenhum favorito ainda',
                  subtitulo: 'Toque no coração em um café para salvar.',
                )
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.builder(
                    itemCount: _favs.length,
                    itemBuilder: (_, i) {
                      final cafe = _favs[i];
                      return CafeCard(
                        cafe: cafe,
                        favorito: true,
                        onFavorito: () async {
                          await DatabaseService.toggleFavorito(
                              context.read<AppState>().usuario!.id!, cafe.id!);
                          _carregar();
                        },
                        onDetalhes: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    DetalhesCafeScreen(cafe: cafe))),
                      );
                    },
                  ),
                ),
    );
  }
}
