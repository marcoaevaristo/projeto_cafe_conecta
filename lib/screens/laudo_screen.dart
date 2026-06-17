// lib/screens/laudo_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LaudoScreen extends StatelessWidget {
  final String id;
  final String conteudo;

  const LaudoScreen({Key? key, required this.id, required this.conteudo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final qrData = 'laudo://$id';
    return Scaffold(
      appBar: AppBar(title: const Text('Laudo Digital')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Expanded(child: SingleChildScrollView(child: Text(conteudo))),
          const SizedBox(height: 12),
          QrImage(
            data: qrData,
            version: QrVersions.auto,
            size: 200.0,
          ),
          const SizedBox(height: 8),
          Text('ID do laudo: $id'),
        ]),
      ),
    );
  }
}
