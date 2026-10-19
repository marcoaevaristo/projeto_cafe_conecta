// lib/screens/novo_anuncio_screen.dart

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/cafe_model.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';
import '../utils/erros.dart';
import '../utils/theme.dart';
import 'classificacao_ia_screen.dart';
import 'planos_screen.dart';

class NovoAnuncioScreen extends StatefulWidget {
  const NovoAnuncioScreen({super.key});
  @override
  State<NovoAnuncioScreen> createState() => _NovoAnuncioScreenState();
}

class _NovoAnuncioScreenState extends State<NovoAnuncioScreen> {
  String? _tipo;
  String? _classificacao;
  String? _bebida;
  String? _peneira;
  String? _regiao;
  String? _safra;
  final _qtdCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _fazendaCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  bool _loading = false;
  String? _erro;
  int? _score; // vem da classificação por IA
  final List<({Uint8List bytes, String tipo})> _fotos = [];

  // Fotos por lote em cada plano (tier 0=Grátis … 3=Premium); null = ilimitado
  static const _limiteFotos = [0, 3, 10, null];

  Future<void> _adicionarFotos() async {
    final tier = context.read<AppState>().planoTier;
    final limite = _limiteFotos[tier];
    final escolhidas = await ImagePicker()
        .pickMultiImage(maxWidth: 1600, maxHeight: 1600, imageQuality: 80);
    for (final f in escolhidas) {
      if (limite != null && _fotos.length >= limite) break;
      final nome = f.name.toLowerCase();
      _fotos.add((
        bytes: await f.readAsBytes(),
        tipo: f.mimeType ??
            (nome.endsWith('.png')
                ? 'image/png'
                : nome.endsWith('.webp')
                    ? 'image/webp'
                    : 'image/jpeg'),
      ));
    }
    if (mounted) setState(() {});
  }

  // Preenche o formulário com o resultado da IA, só onde o valor existe nas opções
  void _aplicarLaudo(Map<String, dynamic> r) {
    String? se(List<String> opcoes, Object? v) =>
        opcoes.contains(v?.toString()) ? v.toString() : null;
    setState(() {
      _tipo = se(tiposCafe, r['tipo']) ?? _tipo;
      _classificacao = se(classificacoesCafe, r['classificacao']) ?? _classificacao;
      _bebida = se(bebidasCafe, r['bebida']) ?? _bebida;
      _peneira = se(peneirasDisponiveis, r['peneira']) ?? _peneira;
      _score = (r['score'] as num?)?.toInt() ?? _score;
    });
  }

  Widget _secaoFotos() {
    final tier = context.watch<AppState>().planoTier;
    final limite = _limiteFotos[tier];
    if (limite == 0) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Fotos nos anúncios a partir do plano Básico'),
          trailing: TextButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PlanosScreen())),
            child: const Text('Ver planos'),
          ),
        ),
      );
    }
    final podeMais = limite == null || _fotos.length < limite;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(limite == null
          ? '${_fotos.length} foto(s) · ilimitadas no seu plano'
          : '${_fotos.length} de $limite fotos do seu plano',
          style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < _fotos.length; i++)
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(_fotos[i].bytes, width: 88, height: 88, fit: BoxFit.cover),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: () => setState(() => _fotos.removeAt(i)),
                child: const CircleAvatar(
                    radius: 11,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 14, color: Colors.white)),
              ),
            ),
          ]),
        if (podeMais)
          InkWell(
            onTap: _adicionarFotos,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CafeColors.caramel),
              ),
              child: const Icon(Icons.add_a_photo_outlined, color: CafeColors.caramel),
            ),
          ),
      ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Anúncio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _secao('Dados do Café'),
            _drop('Tipo de Café', tiposCafe, _tipo,
                (v) => setState(() => _tipo = v)),
            _drop('Classificação', classificacoesCafe, _classificacao,
                (v) => setState(() => _classificacao = v)),
            _drop('Bebida', bebidasCafe, _bebida,
                (v) => setState(() => _bebida = v)),
            _drop('Peneira', peneirasDisponiveis, _peneira,
                (v) => setState(() => _peneira = v)),
            _campo(_qtdCtrl, 'Quantidade (sacas)', TextInputType.number),
            _campo(_precoCtrl, 'Preço por saca (R\$)',
                const TextInputType.numberWithOptions(decimal: true)),
            _secao('Localização'),
            _drop('Região', regioesCafe, _regiao,
                (v) => setState(() => _regiao = v)),
            _campo(_cidadeCtrl, 'Cidade', TextInputType.text),
            _campo(_fazendaCtrl, 'Fazenda / Propriedade', TextInputType.text),
            _secao('Fotos do lote'),
            _secaoFotos(),
            _secao('Safra'),
            _drop('Safra', ['2024/2025', '2023/2024', '2022/2023'], _safra,
                (v) => setState(() => _safra = v)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ClassificacaoIAScreen()));
                if (res is Map<String, dynamic> && mounted) _aplicarLaudo(res);
              },
              icon: const Icon(Icons.smart_toy),
              label: const Text('Analisar com IA'),
            ),
            const SizedBox(height: 16),
            if (_erro != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CafeColors.redAlert.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: CafeColors.redAlert.withValues(alpha: 0.3)),
                ),
                child: Text(_erro!,
                    style: GoogleFonts.dmSans(color: CafeColors.redAlert)),
              ),
            ElevatedButton(
              onPressed: _loading ? null : _publicar,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Publicar Anúncio'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _secao(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 10),
        child: Text(t,
            style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CafeColors.darkRoast)),
      );

  Widget _drop(String label, List<String> items, String? value,
      void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(i)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label, TextInputType tipo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: tipo,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Future<void> _publicar() async {
    if (_tipo == null ||
        _classificacao == null ||
        _qtdCtrl.text.isEmpty ||
        _regiao == null ||
        _cidadeCtrl.text.isEmpty) {
      setState(() =>
          _erro = 'Preencha tipo, classificação, quantidade, região e cidade.');
      return;
    }
    setState(() {
      _loading = true;
      _erro = null;
    });

    final u = context.read<AppState>().usuario!;
    final cafe = CafeModel(
      usuarioId: u.id!,
      tipo: _tipo!,
      classificacao: _classificacao!,
      quantidade: int.tryParse(_qtdCtrl.text) ?? 0,
      bebida: _bebida,
      peneira: _peneira,
      safra: _safra,
      regiao: _regiao!,
      cidade: _cidadeCtrl.text.trim(),
      fazenda:
          _fazendaCtrl.text.trim().isEmpty ? null : _fazendaCtrl.text.trim(),
      precoSaca: double.tryParse(_precoCtrl.text.replaceAll(',', '.')),
      scoreQualidade: _score,
    );

    try {
      final cafeId = await ApiService.inserirCafe(cafe);
      // Envia as fotos depois que o lote existe; uma falha não desfaz o anúncio
      Object? erroFoto;
      var enviadas = 0;
      if (cafeId != null) {
        for (final f in _fotos) {
          try {
            await ApiService.adicionarFotoCafe(cafeId, f.bytes, f.tipo);
            enviadas++;
          } catch (e) {
            erroFoto = e;
            break;
          }
        }
      }
      if (!mounted) return;
      setState(() => _loading = false);
      if (erroFoto != null) {
        mostrarErro(context, erroFoto);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(enviadas > 0
                ? '✅ Anúncio publicado com $enviadas foto(s)!'
                : '✅ Anúncio publicado com sucesso!')));
      }
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = mensagemDeErro(e);
      });
      mostrarErro(context, e);
    }
  }
}
