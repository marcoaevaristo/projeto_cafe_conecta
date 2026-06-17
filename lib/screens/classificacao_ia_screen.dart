// lib/screens/classificacao_ia_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/laudo_service.dart';
import 'laudo_screen.dart';

class ClassificacaoIAScreen extends StatefulWidget {
  const ClassificacaoIAScreen({Key? key}) : super(key: key);

  @override
  State<ClassificacaoIAScreen> createState() => _ClassificacaoIAScreenState();
}

class _ClassificacaoIAScreenState extends State<ClassificacaoIAScreen> {
  File? _image;
  bool _analisando = false;
  String? _resultado;

  final ImagePicker _picker = ImagePicker();

  Future<void> _tirarFoto() async {
    final XFile? f = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (f == null) return;
    setState(() => _image = File(f.path));
  }

  Future<void> _analisar() async {
    if (_image == null) return;
    setState(() { _analisando = true; _resultado = null; });
    try {
      final laudo = await LaudoService.generateFromImage(_image!);
      setState(() { _analisando = false; _resultado = laudo.conteudo; });
      if (!mounted) return;
      // Mostrar laudo e permitir usar resultado
      await Navigator.push(context, MaterialPageRoute(builder: (_) => LaudoScreen(id: laudo.id, conteudo: laudo.conteudo)));
    } catch (e) {
      setState(() { _analisando = false; _resultado = 'Erro: ${e.toString()}'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classificação por IA')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Expanded(
            child: Center(
              child: _image == null
                  ? const Text('Nenhuma foto. Use a câmera para analisar.')
                  : Image.file(_image!),
            ),
          ),
          if (_resultado != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Resultado: $_resultado', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _tirarFoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tirar foto'),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: (_image != null && !_analisando) ? _analisar : null,
              child: _analisando ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Analisar IA'),
            ),
          ]),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _resultado == null ? null : () => Navigator.pop(context, _resultado),
            child: const Text('Usar resultado'),
          )
        ]),
      ),
    );
  }
}
