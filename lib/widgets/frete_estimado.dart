// lib/widgets/frete_estimado.dart — estimativa de frete até o comprador.
// Distância em linha reta × 1,3 (fator de estrada) ou digitada; custo por saca·km editável.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/cafe_model.dart';
import '../utils/erros.dart';
import '../utils/localizacao/localizacao.dart';
import '../utils/theme.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
final _brl3 = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 3);

/// Distância em km entre dois pontos (fórmula de haversine).
double distanciaKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  double rad(double g) => g * pi / 180;
  final dLat = rad(lat2 - lat1), dLon = rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) + cos(rad(lat1)) * cos(rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return 2 * r * asin(sqrt(a));
}

const fatorEstrada = 1.3;
// Referência: carreta com ~500 sacas a cerca de R$ 8/km rodado ≈ R$ 0,016 por saca·km.
const custoSacaKmPadrao = 0.016;

double? _ler(String t) {
  final v = t.trim();
  if (v.isEmpty) return null;
  return double.tryParse(v.contains(',') ? v.replaceAll('.', '').replaceAll(',', '.') : v);
}

class FreteEstimado extends StatefulWidget {
  final CafeModel cafe;
  const FreteEstimado({super.key, required this.cafe});
  @override
  State<FreteEstimado> createState() => _FreteEstimadoState();
}

class _FreteEstimadoState extends State<FreteEstimado> {
  final _km = TextEditingController();
  final _custo = TextEditingController(text: custoSacaKmPadrao.toString().replaceAll('.', ','));
  late final _sacas = TextEditingController(text: '${widget.cafe.quantidade}');
  bool _buscando = false;

  @override
  void dispose() {
    _km.dispose();
    _custo.dispose();
    _sacas.dispose();
    super.dispose();
  }

  Future<void> _usarLocalizacao() async {
    final c = widget.cafe;
    if (c.lat == null || c.lng == null) return;
    setState(() => _buscando = true);
    try {
      final (lat, lng) = await minhaLocalizacao();
      final km = distanciaKm(lat, lng, c.lat!, c.lng!) * fatorEstrada;
      _km.text = km.round().toString();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final km = _ler(_km.text);
    final custo = _ler(_custo.text);
    final sacas = int.tryParse(_sacas.text.trim());
    final porSaca = km != null && custo != null ? km * custo : null;
    final total = porSaca != null && sacas != null ? porSaca * sacas : null;
    final preco = widget.cafe.precoSaca;
    final entrada = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (widget.cafe.lat != null && widget.cafe.lng != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _buscando ? null : _usarLocalizacao,
                icon: _buscando
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location, size: 18),
                label: const Text('Calcular a partir de onde estou'),
              ),
            ),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _km,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: entrada,
                decoration: const InputDecoration(labelText: 'Distância', suffixText: 'km', isDense: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _sacas,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Sacas', isDense: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _custo,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: entrada,
                decoration: const InputDecoration(labelText: r'R$/saca·km', isDense: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          if (porSaca == null)
            Text('Informe a distância para ver o custo.', style: GoogleFonts.dmSans(fontSize: 13, color: CafeColors.lightRoast))
          else ...[
            Text('Frete ≈ ${_brl.format(porSaca)} por saca${total != null ? ' · ${_brl.format(total)} no total' : ''}',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
            if (preco != null)
              Text('Preço posto no destino ≈ ${_brl.format(preco + porSaca)} por saca',
                  style: GoogleFonts.dmSans(fontSize: 13, color: CafeColors.darkRoast)),
          ],
          const SizedBox(height: 6),
          Text(
            'Estimativa: distância em linha reta × ${fatorEstrada.toString().replaceAll('.', ',')} e '
            '${_brl3.format(custoSacaKmPadrao)} por saca·km (carreta cheia). Ajuste os valores e confirme com a transportadora.',
            style: GoogleFonts.dmSans(fontSize: 11, color: CafeColors.lightRoast),
          ),
        ]),
      ),
    );
  }
}
