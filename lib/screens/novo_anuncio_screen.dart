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

/// Cria um anúncio novo ou, com [cafe], edita um anúncio existente.
/// Na edição, devolve `true` ao salvar.
class NovoAnuncioScreen extends StatefulWidget {
  final CafeModel? cafe;
  const NovoAnuncioScreen({super.key, this.cafe});
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
  // Ficha do café especial (opcional)
  String? _variedade;
  String? _processamento;
  final _altitudeCtrl = TextEditingController();
  final _scaCtrl = TextEditingController();
  final Set<String> _certificacoes = {};
  bool _loading = false;
  String? _erro;
  int? _score; // vem da classificação por IA
  final List<({Uint8List bytes, String tipo})> _fotos = [];
  // Edição: fotos que o lote já tem e as que o usuário tirou
  final List<String> _fotosExistentes = [];
  final List<String> _fotosRemovidas = [];

  bool get _editando => widget.cafe != null;
  int get _totalFotos => _fotosExistentes.length + _fotos.length;

  static const _safras = ['2026/2027', '2025/2026', '2024/2025', '2023/2024', '2022/2023'];

  @override
  void initState() {
    super.initState();
    final c = widget.cafe;
    if (c == null) return;
    _tipo = c.tipo.isEmpty ? null : c.tipo;
    _classificacao = c.classificacao.isEmpty ? null : c.classificacao;
    _bebida = c.bebida;
    _peneira = c.peneira;
    _regiao = c.regiao.isEmpty ? null : c.regiao;
    _safra = c.safra;
    _score = c.scoreQualidade;
    _qtdCtrl.text = c.quantidade > 0 ? '${c.quantidade}' : '';
    _cidadeCtrl.text = c.cidade;
    _fazendaCtrl.text = c.fazenda ?? '';
    if (c.precoSaca != null) {
      final p = c.precoSaca!;
      _precoCtrl.text = p == p.roundToDouble()
          ? p.toStringAsFixed(0)
          : p.toStringAsFixed(2).replaceAll('.', ',');
    }
    _fotosExistentes.addAll(c.fotos);
    _variedade = c.variedade;
    _processamento = c.processamento;
    if (c.altitude != null) _altitudeCtrl.text = '${c.altitude}';
    if (c.pontuacaoSca != null) {
      _scaCtrl.text = c.pontuacaoSca!.toStringAsFixed(1).replaceAll('.', ',');
    }
    _certificacoes.addAll(c.certificacoes);
  }

  int? get _altitude => int.tryParse(_altitudeCtrl.text.trim());
  double? get _sca => double.tryParse(_scaCtrl.text.trim().replaceAll(',', '.'));

  Widget _secaoFicha() => Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          initiallyExpanded: widget.cafe?.temFichaEspecial ?? false,
          title: Text('Ficha do café especial (opcional)',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 16, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
          subtitle: Text('Variedade, processamento, altitude, pontuação SCA e certificações',
              style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
          children: [
            const SizedBox(height: 8),
            _drop('Variedade', variedadesCafe, _variedade, (v) => setState(() => _variedade = v)),
            _drop('Processamento', processamentosCafe, _processamento,
                (v) => setState(() => _processamento = v)),
            Row(children: [
              Expanded(child: _campo(_altitudeCtrl, 'Altitude (m)', TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(
                  child: _campo(_scaCtrl, 'Pontuação SCA (80–100)',
                      const TextInputType.numberWithOptions(decimal: true))),
            ]),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Certificações',
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final c in certificacoesCafe)
                FilterChip(
                  label: Text(c),
                  selected: _certificacoes.contains(c),
                  onSelected: (v) => setState(() => v ? _certificacoes.add(c) : _certificacoes.remove(c)),
                ),
            ]),
            const SizedBox(height: 8),
          ],
        ),
      );

  @override
  void dispose() {
    _qtdCtrl.dispose();
    _cidadeCtrl.dispose();
    _fazendaCtrl.dispose();
    _precoCtrl.dispose();
    _altitudeCtrl.dispose();
    _scaCtrl.dispose();
    super.dispose();
  }

  // Fotos por lote em cada plano (tier 0=Grátis … 3=Premium); null = ilimitado
  static const _limiteFotos = [0, 3, 10, null];

  Future<void> _adicionarFotos() async {
    final tier = context.read<AppState>().planoTier;
    final limite = _limiteFotos[tier];
    final escolhidas = await ImagePicker()
        .pickMultiImage(maxWidth: 1600, maxHeight: 1600, imageQuality: 80);
    for (final f in escolhidas) {
      if (limite != null && _totalFotos >= limite) break;
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
    final podeMais = limite == null || _totalFotos < limite;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(limite == null
          ? '$_totalFotos foto(s) · ilimitadas no seu plano'
          : '$_totalFotos de $limite fotos do seu plano',
          style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final url in List.of(_fotosExistentes))
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(url, width: 88, height: 88, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(width: 88, height: 88, color: CafeColors.mediumRoast)),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: () => setState(() {
                  _fotosExistentes.remove(url);
                  _fotosRemovidas.add(url);
                }),
                child: const CircleAvatar(
                    radius: 11,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 14, color: Colors.white)),
              ),
            ),
          ]),
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
      appBar: AppBar(title: Text(_editando ? 'Editar Anúncio' : 'Novo Anúncio')),
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
            const SizedBox(height: 8),
            _secaoFicha(),
            _secao('Fotos do lote'),
            _secaoFotos(),
            _secao('Safra'),
            _drop('Safra', _safras, _safra,
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
                  : Text(_editando ? 'Salvar alterações' : 'Publicar Anúncio'),
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
        // um valor antigo que não está mais na lista continua aparecendo
        items: [if (value != null && !items.contains(value)) value, ...items]
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

    if (_editando) return _salvarEdicao();

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
      precoSaca: _lerPreco(_precoCtrl.text),
      scoreQualidade: _score,
      variedade: _variedade,
      processamento: _processamento,
      altitude: _altitude,
      pontuacaoSca: _sca,
      certificacoes: _certificacoes.toList(),
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

  // Aceita "1500", "1500,50", "1.500,50" e "1500.50"
  static double? _lerPreco(String t) {
    final v = t.trim();
    if (v.isEmpty) return null;
    return double.tryParse(
        v.contains(',') ? v.replaceAll('.', '').replaceAll(',', '.') : v);
  }

  Future<void> _salvarEdicao() async {
    final id = widget.cafe!.id!;
    final fazenda = _fazendaCtrl.text.trim();
    try {
      await ApiService.atualizarCafe(id, {
        'tipo': _tipo,
        'classificacao': _classificacao,
        'quantidade_sacas': int.tryParse(_qtdCtrl.text) ?? 0,
        'preco_saca': _lerPreco(_precoCtrl.text),
        'bebida': _bebida,
        'peneira': _peneira,
        'safra': _safra,
        'regiao': _regiao,
        'cidade': _cidadeCtrl.text.trim(),
        'fazenda': fazenda.isEmpty ? null : fazenda,
        'score': _score,
        // ficha: envia quando preenchida ou quando o lote já tinha ficha (para permitir apagar)
        if (_variedade != null || widget.cafe!.variedade != null) 'variedade': _variedade,
        if (_processamento != null || widget.cafe!.processamento != null) 'processamento': _processamento,
        if (_altitude != null || widget.cafe!.altitude != null) 'altitude': _altitude,
        if (_sca != null || widget.cafe!.pontuacaoSca != null) 'pontuacao_sca': _sca,
        if (_certificacoes.isNotEmpty || widget.cafe!.certificacoes.isNotEmpty)
          'certificacoes': _certificacoes.toList(),
      });
      // Fotos: primeiro tira as removidas (libera espaço no limite), depois envia as novas
      Object? erroFoto;
      for (final url in _fotosRemovidas) {
        try {
          await ApiService.removerFotoCafe(id, url);
        } catch (e) {
          erroFoto = e;
        }
      }
      for (final f in _fotos) {
        try {
          await ApiService.adicionarFotoCafe(id, f.bytes, f.tipo);
        } catch (e) {
          erroFoto = e;
          break;
        }
      }
      if (!mounted) return;
      setState(() => _loading = false);
      if (erroFoto != null) {
        mostrarErro(context, erroFoto);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('✅ Anúncio atualizado')));
      }
      Navigator.pop(context, true);
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
