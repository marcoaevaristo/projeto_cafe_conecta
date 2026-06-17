// lib/screens/home_screen.dart — v2 com Score Filter (Melhoria 1) e Verified Seal (Melhoria 3)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/cafe_model.dart';
import '../services/app_state.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../widgets/cafe_card.dart';
import 'detalhes_cafe_screen.dart';
import 'nova_proposta_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CafeModel> _cafes = [];
  bool _loading = true;
  String _tipoFiltro = 'Todos';
  String _classiFiltro = 'Todas';
  int _scoreMinimo = 70;
  final _searchCtrl = TextEditingController();
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _carregar();
    _searchCtrl.addListener(
        () => setState(() => _busca = _searchCtrl.text.toLowerCase()));
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final cafes = await DatabaseService.getCafes(
      tipo: _tipoFiltro == 'Todos' ? null : _tipoFiltro,
      classificacao: _classiFiltro == 'Todas' ? null : _classiFiltro,
      scoreMinimo: _scoreMinimo,
    );
    setState(() {
      _cafes = cafes;
      _loading = false;
    });
  }

  List<CafeModel> get _filtrados => _busca.isEmpty
      ? _cafes
      : _cafes
          .where((c) =>
              c.tipo.toLowerCase().contains(_busca) ||
              c.classificacao.toLowerCase().contains(_busca) ||
              c.cidade.toLowerCase().contains(_busca) ||
              (c.fazenda?.toLowerCase().contains(_busca) ?? false))
          .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 130,
            floating: false,
            pinned: true,
            backgroundColor: CafeColors.espresso,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [
                  CafeColors.espresso,
                  CafeColors.darkRoast,
                  CafeColors.mediumRoast
                ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Cafés Disponíveis',
                          style: GoogleFonts.playfairDisplay(
                              color: CafeColors.gold,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      Text(
                          '${_filtrados.length} lote${_filtrados.length != 1 ? "s" : ""} encontrado${_filtrados.length != 1 ? "s" : ""}',
                          style: GoogleFonts.dmSans(
                              color: CafeColors.cream.withValues(alpha: 0.6),
                              fontSize: 12)),
                    ]),
              ),
            ),
          ),
        ],
        body: Column(children: [
          _buildFiltros(),
          _buildScoreFilter(), // MELHORIA 1
          Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtrados.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off,
                          titulo: 'Nenhum café com score ≥ $_scoreMinimo',
                          subtitulo: 'Ajuste o filtro de qualidade.')
                      : RefreshIndicator(
                          onRefresh: _carregar,
                          child: ListView.builder(
                              itemCount: _filtrados.length,
                              itemBuilder: (_, i) =>
                                  _buildCard(_filtrados[i])))),
        ]),
      ),
    );
  }

  // MELHORIA 1: Score slider
  Widget _buildScoreFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('🏆 Score mínimo de qualidade',
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CafeColors.mediumRoast)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: CafeColors.caramel.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Text('$_scoreMinimo pts',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CafeColors.caramel)),
          ),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: CafeColors.caramel,
            inactiveTrackColor: CafeColors.lightRoast.withValues(alpha: 0.2),
            thumbColor: CafeColors.caramel,
            overlayColor: CafeColors.caramel.withValues(alpha: 0.15),
            trackHeight: 4,
          ),
          child: Slider(
            value: _scoreMinimo.toDouble(),
            min: 60,
            max: 95,
            divisions: 7,
            onChanged: (v) {
              setState(() => _scoreMinimo = v.round());
              _carregar();
            },
          ),
        ),
        Row(children: [
          _scoreChip('Todos ≥70', 70),
          const SizedBox(width: 6),
          _scoreChip('Bom ≥80', 80),
          const SizedBox(width: 6),
          _scoreChip('Excelente ≥90', 90),
        ]),
      ]),
    );
  }

  Widget _scoreChip(String label, int value) {
    final sel = _scoreMinimo == value;
    return GestureDetector(
      onTap: () {
        setState(() => _scoreMinimo = value);
        _carregar();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: sel ? CafeColors.caramel : Colors.transparent,
          border: Border.all(
              color: sel
                  ? CafeColors.caramel
                  : CafeColors.lightRoast.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: sel ? CafeColors.espresso : CafeColors.lightRoast)),
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Buscar cafés...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _busca.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => _searchCtrl.clear())
                : null,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child:
                  _dropdown('Tipo', ['Todos', ...tiposCafe], _tipoFiltro, (v) {
            _tipoFiltro = v!;
            _carregar();
          })),
          const SizedBox(width: 8),
          Expanded(
              child: _dropdown(
                  'Classif.', ['Todas', ...classificacoesCafe], _classiFiltro,
                  (v) {
            _classiFiltro = v!;
            _carregar();
          })),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _dropdown(String label, List<String> items, String value,
      void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      isDense: true,
      decoration: InputDecoration(
          labelText: label,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          isDense: true),
      style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.espresso),
      items:
          items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCard(CafeModel cafe) {
    final usuario = context.read<AppState>().usuario;
    return FutureBuilder<bool>(
      future: usuario != null
          ? DatabaseService.isFavorito(usuario.id!, cafe.id!)
          : Future.value(false),
      builder: (_, snap) {
        final fav = snap.data ?? false;
        return CafeCard(
          cafe: cafe,
          favorito: fav,
          onFavorito: usuario == null
              ? null
              : () async {
                  await DatabaseService.toggleFavorito(usuario.id!, cafe.id!);
                  setState(() {});
                },
          onDetalhes: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => DetalhesCafeScreen(cafe: cafe))),
          onProposta: usuario == null || cafe.usuarioId == usuario.id
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => NovaPropostaScreen(cafe: cafe))),
        );
      },
    );
  }
}
