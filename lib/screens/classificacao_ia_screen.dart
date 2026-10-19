// lib/screens/classificacao_ia_screen.dart
// Classificação de café por IA: a foto vai para o backend, que chama a IA
// (a chave fica só no servidor) e devolve o laudo estruturado.
// Ao tocar em "Usar resultado", a tela devolve o Map do laudo para quem a abriu.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../utils/erros.dart';
import '../widgets/upgrade_gate.dart';
import 'laudo_screen.dart';

class ClassificacaoIAScreen extends StatefulWidget {
  final String? cafeId;
  const ClassificacaoIAScreen({super.key, this.cafeId});

  @override
  State<ClassificacaoIAScreen> createState() => _ClassificacaoIAScreenState();
}

class _ClassificacaoIAScreenState extends State<ClassificacaoIAScreen> {
  Uint8List? _bytes;
  String _contentType = 'image/jpeg';
  bool _analisando = false;
  Map<String, dynamic>? _laudo;

  final ImagePicker _picker = ImagePicker();

  Future<void> _escolherFoto(ImageSource origem) async {
    final XFile? f = await _picker.pickImage(
        source: origem, maxWidth: 1600, maxHeight: 1600, imageQuality: 80);
    if (f == null) return;
    final bytes = await f.readAsBytes(); // funciona no navegador e no celular
    final nome = f.name.toLowerCase();
    setState(() {
      _bytes = bytes;
      _contentType = f.mimeType ??
          (nome.endsWith('.png')
              ? 'image/png'
              : nome.endsWith('.webp')
                  ? 'image/webp'
                  : 'image/jpeg');
      _laudo = null;
    });
  }

  Future<void> _analisar() async {
    if (_bytes == null) return;
    setState(() {
      _analisando = true;
      _laudo = null;
    });
    try {
      final laudo = await ApiService.gerarLaudoIA(_bytes!, _contentType,
          cafeId: widget.cafeId);
      if (!mounted) return;
      setState(() {
        _analisando = false;
        _laudo = laudo;
      });
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => LaudoScreen(
                  id: laudo['id']?.toString() ?? '',
                  conteudo: laudo['texto']?.toString() ?? '',
                  url: laudo['url']?.toString())));
    } catch (e) {
      if (!mounted) return;
      setState(() => _analisando = false);
      mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UpgradeGate(
      requiredTier: 2,
      titulo: 'Classificação por IA',
      message:
          'A classificação por IA e o laudo digital fazem parte dos planos Profissional e Premium.',
      child: Scaffold(
        appBar: AppBar(title: const Text('Classificação por IA')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Expanded(
              child: Center(
                child: _bytes == null
                    ? const Text(
                        'Tire ou escolha uma foto nítida da amostra de grãos, com boa luz e fundo neutro.',
                        textAlign: TextAlign.center)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_bytes!, fit: BoxFit.contain)),
              ),
            ),
            if (_laudo != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                    '${_laudo!['tipo'] ?? ''} · ${_laudo!['classificacao'] ?? ''} · '
                    '${_laudo!['score'] ?? '-'} pts · confiança ${_laudo!['confianca'] ?? '-'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _analisando ? null : () => _escolherFoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Câmera'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _analisando ? null : () => _escolherFoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeria'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_bytes != null && !_analisando) ? _analisar : null,
                child: _analisando
                    ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Analisando… pode levar até 30 s'),
                      ])
                    : const Text('Analisar com IA'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _laudo == null ? null : () => Navigator.pop(context, _laudo),
                child: const Text('Usar resultado no anúncio'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
