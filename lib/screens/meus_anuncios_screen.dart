// lib/screens/meus_anuncios_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/cafe_model.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../widgets/acoes_anuncio.dart';
import '../widgets/cafe_card.dart';
import 'detalhes_cafe_screen.dart';
import 'novo_anuncio_screen.dart';

class MeusAnunciosScreen extends StatefulWidget {
  const MeusAnunciosScreen({super.key});
  @override
  State<MeusAnunciosScreen> createState() => _MeusAnunciosScreenState();
}

class _MeusAnunciosScreenState extends State<MeusAnunciosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _status = ['ativo', 'pausado', 'vendido', 'encerrado'];
  // Muda a cada ação para recarregar as três abas (um lote pausado muda de aba)
  int _versao = 0;
  void _recarregarTudo() => setState(() => _versao++);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Anúncios'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: CafeColors.gold,
          unselectedLabelColor: CafeColors.cream,
          indicatorColor: CafeColors.caramel,
          labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Ativos'),
            Tab(text: 'Pausados'),
            Tab(text: 'Vendidos'),
            Tab(text: 'Encerrados'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CafeColors.caramel,
        foregroundColor: CafeColors.espresso,
        icon: const Icon(Icons.add),
        label: Text('Novo Anúncio',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NovoAnuncioScreen()));
          _recarregarTudo();
        },
      ),
      body: TabBarView(
        controller: _tabs,
        children: _status
            .map((s) => _ListaStatus(
                key: ValueKey('$s-$_versao'),
                status: s,
                onAlterado: _recarregarTudo))
            .toList(),
      ),
    );
  }
}

class _ListaStatus extends StatefulWidget {
  final String status;
  final VoidCallback onAlterado;
  const _ListaStatus({super.key, required this.status, required this.onAlterado});
  @override
  State<_ListaStatus> createState() => _ListaStatusState();
}

class _ListaStatusState extends State<_ListaStatus>
    with AutomaticKeepAliveClientMixin {
  List<CafeModel> _cafes = [];
  bool _carregado = false;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final u = context.read<AppState>().usuario;
    if (u == null) return;
    try {
      final list = await ApiService.getCafes(usuarioId: u.id, status: widget.status);
      if (mounted) setState(() { _cafes = list; _carregado = true; });
    } catch (_) {
      if (mounted) setState(() => _carregado = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_carregado) return const Center(child: CircularProgressIndicator());
    if (_cafes.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        titulo: 'Nenhum anúncio ${widget.status}',
      );
    }
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 6, bottom: 96), // espaço para o botão Novo Anúncio
        itemCount: _cafes.length,
        itemBuilder: (_, i) {
          final cafe = _cafes[i];
          return Column(children: [
            CafeCard(
              cafe: cafe,
              onDetalhes: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DetalhesCafeScreen(cafe: cafe)));
                widget.onAlterado();
              },
              onProposta: null,
              onFavorito: null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: AcoesAnuncio(cafe: cafe, onConcluido: (_) => widget.onAlterado()),
            ),
            const Divider(height: 18, indent: 14, endIndent: 14),
          ]);
        },
      ),
    );
  }
}
