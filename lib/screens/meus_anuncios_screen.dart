// lib/screens/meus_anuncios_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/cafe_model.dart';
import '../services/app_state.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
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
  final _status = ['ativo', 'pausado', 'encerrado'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
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
          tabs: const [
            Tab(text: 'Ativos'),
            Tab(text: 'Pausados'),
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
          setState(() {});
        },
      ),
      body: TabBarView(
        controller: _tabs,
        children: _status.map((s) => _ListaStatus(status: s)).toList(),
      ),
    );
  }
}

class _ListaStatus extends StatefulWidget {
  final String status;
  const _ListaStatus({required this.status});
  @override
  State<_ListaStatus> createState() => _ListaStatusState();
}

class _ListaStatusState extends State<_ListaStatus>
    with AutomaticKeepAliveClientMixin {
  List<CafeModel> _cafes = [];

  @override
  bool get wantKeepAlive => false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregar();
  }

  Future<void> _carregar() async {
    final u = context.read<AppState>().usuario;
    if (u == null) return;
    final list = await DatabaseService.getCafes(
      usuarioId: u.id,
      statusFiltro: widget.status,
      apenasAtivos: false,
    );
    setState(() => _cafes = list);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_cafes.isEmpty) {
      return const EmptyState(
        icon: Icons.inventory_2_outlined,
        titulo: 'Nenhum anúncio ${widget.status}',
      );
    }
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.builder(
        itemCount: _cafes.length,
        itemBuilder: (_, i) {
          final cafe = _cafes[i];
          return CafeCard(
            cafe: cafe,
            onDetalhes: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => DetalhesCafeScreen(cafe: cafe))),
            onProposta: null,
            onFavorito: null,
          );
        },
      ),
    );
  }
}
