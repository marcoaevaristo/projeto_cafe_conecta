// lib/widgets/conversor_bolsa.dart — converte a cotação da bolsa em R$ por saca de 60 kg.
// O usuário digita o preço que vê no quadro da bolsa; o dólar vem do PTAX (editável).
//   B3 (ICF):  US$/saca            → R$/saca = valor × dólar
//   NY (KC):   centavos US$/libra  → R$/saca = valor ÷ 100 × 132,277 lb × dólar
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../utils/theme.dart';

const librasPorSaca = 132.277; // 60 kg ÷ 0,45359237 kg

/// Converte o preço da bolsa para R$ por saca de 60 kg.
double? paraReaisPorSaca({required bool ny, required double? valor, required double? dolar}) {
  if (valor == null || dolar == null || valor <= 0 || dolar <= 0) return null;
  final usdPorSaca = ny ? valor / 100 * librasPorSaca : valor;
  return usdPorSaca * dolar;
}

double? _lerNumero(String t) {
  final v = t.trim();
  if (v.isEmpty) return null;
  return double.tryParse(v.contains(',') ? v.replaceAll('.', '').replaceAll(',', '.') : v);
}

class ConversorBolsa extends StatefulWidget {
  /// Dólar PTAX de venda (preenche o campo do dólar)
  final double? dolarPtax;

  /// Preço médio do arábica no Índice Café Conecta, para comparar
  final double? mediaArabicaApp;

  const ConversorBolsa({super.key, this.dolarPtax, this.mediaArabicaApp});

  @override
  State<ConversorBolsa> createState() => _ConversorBolsaState();
}

class _ConversorBolsaState extends State<ConversorBolsa> {
  bool _ny = false;
  final _valor = TextEditingController();
  final _dolar = TextEditingController();
  bool _dolarEditado = false;
  final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

  @override
  void didUpdateWidget(covariant ConversorBolsa old) {
    super.didUpdateWidget(old);
    // o PTAX chega depois: preenche, a menos que a pessoa já tenha digitado outro
    if (!_dolarEditado && widget.dolarPtax != null && widget.dolarPtax != old.dolarPtax) {
      _dolar.text = widget.dolarPtax!.toStringAsFixed(4).replaceAll('.', ',');
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.dolarPtax != null) {
      _dolar.text = widget.dolarPtax!.toStringAsFixed(4).replaceAll('.', ',');
    }
  }

  @override
  void dispose() {
    _valor.dispose();
    _dolar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reais = paraReaisPorSaca(ny: _ny, valor: _lerNumero(_valor.text), dolar: _lerNumero(_dolar.text));
    final media = widget.mediaArabicaApp;
    final entrada = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Converter para R\$ por saca',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
          const SizedBox(height: 4),
          Text('Digite o preço que aparece no quadro da bolsa.',
              style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            ChoiceChip(
              label: const Text('B3 · US\$/saca'),
              selected: !_ny,
              onSelected: (_) => setState(() => _ny = false),
            ),
            ChoiceChip(
              label: const Text('NY · ¢/libra'),
              selected: _ny,
              onSelected: (_) => setState(() => _ny = true),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _valor,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: entrada,
                decoration: InputDecoration(
                  labelText: _ny ? 'Preço NY (¢/lb)' : 'Preço B3 (US\$/saca)',
                  hintText: _ny ? 'ex.: 305,45' : 'ex.: 386,25',
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _dolar,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: entrada,
                decoration: const InputDecoration(labelText: 'Dólar (R\$)', isDense: true),
                onChanged: (_) => setState(() => _dolarEditado = true),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          if (reais == null)
            Text('O resultado aparece aqui.',
                style: GoogleFonts.dmSans(fontSize: 13, color: CafeColors.lightRoast))
          else ...[
            Text(_brl.format(reais),
                style: GoogleFonts.playfairDisplay(
                    fontSize: 26, fontWeight: FontWeight.w700, color: CafeColors.mediumRoast)),
            Text('por saca de 60 kg',
                style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
            if (media != null && media > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Média do arábica no Café Conecta: ${_brl.format(media)}. '
                'A bolsa está ${((reais / media - 1).abs() * 100).toStringAsFixed(1).replaceAll('.', ',')}% '
                '${reais >= media ? 'acima' : 'abaixo'}.',
                style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.darkRoast),
              ),
            ],
          ],
          const SizedBox(height: 8),
          Text(
            _ny
                ? 'Conta: centavos ÷ 100 × 132,277 libras por saca × dólar. Referência de bolsa; '
                    'o preço do físico varia com tipo, bebida e região.'
                : 'Conta: US\$ por saca × dólar. Referência de bolsa; o preço do físico varia com tipo, bebida e região.',
            style: GoogleFonts.dmSans(fontSize: 11, color: CafeColors.lightRoast, height: 1.35),
          ),
        ]),
      ),
    );
  }
}
