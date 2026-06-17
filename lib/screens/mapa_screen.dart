// lib/screens/mapa_screen.dart — v3: Mapa de disponibilidade
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../models/cafe_model.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import 'detalhes_cafe_screen.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});
  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  List<CafeModel> _cafes = [];
  CafeModel? _selecionado;
  String _filtroTipo = 'Todos';
  final _mapCtrl = MapController();
  final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final cafes = await DatabaseService.getCafes(
      tipo: _filtroTipo == 'Todos' ? null : _filtroTipo,
    );
    setState(() {
      _cafes = cafes.where((c) => c.lat != null && c.lng != null).toList();
    });
  }

  Color _corPorTipo(String tipo) {
    switch (tipo) {
      case 'Arábica':
        return CafeColors.caramel;
      case 'Conilon':
        return CafeColors.greenOk;
      default:
        return CafeColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Disponibilidade'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<String>(
              value: _filtroTipo,
              dropdownColor: CafeColors.espresso,
              style: GoogleFonts.dmSans(color: CafeColors.cream, fontSize: 13),
              underline: const SizedBox(),
              icon: const Icon(Icons.filter_list,
                  color: CafeColors.cream, size: 18),
              items: ['Todos', ...tiposCafe]
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() => _filtroTipo = v!);
                _carregar();
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: const LatLng(-19.5, -44.5),
              initialZoom: 6.5,
              onTap: (_, __) => setState(() => _selecionado = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.cafeconecta.app',
              ),
              MarkerLayer(
                markers: _cafes.map((cafe) {
                  final cor = _corPorTipo(cafe.tipo);
                  final selecionado = _selecionado?.id == cafe.id;
                  return Marker(
                    point: LatLng(cafe.lat!, cafe.lng!),
                    width: selecionado ? 52 : 44,
                    height: selecionado ? 52 : 44,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selecionado = cafe);
                        _mapCtrl.move(LatLng(cafe.lat!, cafe.lng!), 9);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: cor,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: selecionado ? 3 : 2),
                          boxShadow: [
                            BoxShadow(
                                color: cor.withValues(alpha: 0.5),
                                blurRadius: selecionado ? 12 : 6,
                                spreadRadius: selecionado ? 2 : 0)
                          ],
                        ),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('☕',
                                  style: TextStyle(
                                      fontSize: selecionado ? 18 : 14)),
                              if (!selecionado)
                                Text(
                                  NumberFormat.compact()
                                      .format(cafe.quantidade),
                                  style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700),
                                ),
                            ]),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Legenda
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)
                ],
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_cafes.length} lotes no mapa',
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: CafeColors.darkRoast)),
                    const SizedBox(height: 6),
                    ...[
                      ('Arábica', CafeColors.caramel),
                      ('Conilon', CafeColors.greenOk),
                      ('Robusta', CafeColors.blue)
                    ].map((e) => Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(children: [
                          Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: e.$2, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text(e.$1,
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, color: CafeColors.lightRoast)),
                        ]))),
                  ]),
            ),
          ),

          // Card do lote selecionado
          if (_selecionado != null)
            Positioned(
              bottom: 16,
              left: 12,
              right: 12,
              child: _buildLoteCard(_selecionado!),
            ),
        ],
      ),
    );
  }

  Widget _buildLoteCard(CafeModel cafe) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [CafeColors.darkRoast, CafeColors.mediumRoast]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            const Text('☕', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(cafe.nomeCurto,
                      style: GoogleFonts.playfairDisplay(
                          color: CafeColors.gold,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  Text('${cafe.fazenda ?? ''} · ${cafe.cidade}',
                      style: GoogleFonts.dmSans(
                          color: CafeColors.cream.withValues(alpha: 0.7),
                          fontSize: 11)),
                ])),
            if (cafe.scoreQualidade != null)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor(cafe.scoreQualidade!),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${cafe.scoreQualidade}',
                          style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1)),
                      Text('pts',
                          style: GoogleFonts.dmSans(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 7)),
                    ]),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            _stat('Quantidade',
                '${NumberFormat('#,###').format(cafe.quantidade)} sc'),
            _stat('Preço/saca',
                cafe.precoSaca != null ? _brl.format(cafe.precoSaca) : '—'),
            _stat('Região', cafe.regiao.split(' - ').first),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(children: [
            Expanded(
                child: OutlinedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DetalhesCafeScreen(cafe: cafe))),
              style: OutlinedButton.styleFrom(
                  foregroundColor: CafeColors.darkRoast,
                  side: const BorderSide(color: CafeColors.lightRoast),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10)),
              child: Text('Ver detalhes',
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600, fontSize: 12)),
            )),
            const SizedBox(width: 8),
            Expanded(
                child: ElevatedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DetalhesCafeScreen(cafe: cafe))),
              style: ElevatedButton.styleFrom(
                  backgroundColor: CafeColors.caramel,
                  foregroundColor: CafeColors.espresso,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10)),
              child: Text('Proposta',
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600, fontSize: 12)),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _stat(String label, String value) => Expanded(
          child: Column(children: [
        Text(value,
            style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CafeColors.darkRoast),
            overflow: TextOverflow.ellipsis),
        Text(label,
            style:
                GoogleFonts.dmSans(fontSize: 10, color: CafeColors.lightRoast)),
      ]));
}
