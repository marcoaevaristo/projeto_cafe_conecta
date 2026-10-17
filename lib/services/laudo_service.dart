// lib/services/laudo_service.dart
// Classificação IA via Claude Vision API (Anthropic)
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class LaudoResult {
  final String id;
  final String conteudo;

  LaudoResult({required this.id, required this.conteudo});

  factory LaudoResult.fromJson(Map<String, dynamic> j) => LaudoResult(
        id: j['id'] ?? '',
        conteudo: j['conteudo'] ?? j['content'] ?? '',
      );
}

class LaudoService {
  static const _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');

  static Future<LaudoResult> generateFromImage(File image) async {
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Determina o tipo de imagem
    final ext = image.path.split('.').last.toLowerCase();
    final mediaType = ext == 'png'
        ? 'image/png'
        : ext == 'webp'
            ? 'image/webp'
            : 'image/jpeg';

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-opus-4-5',
        'max_tokens': 1024,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': mediaType,
                  'data': base64Image,
                },
              },
              {
                'type': 'text',
                'text': '''Você é um especialista em classificação de grãos de café.
Analise a imagem e forneça um laudo técnico com:
- Tipo: Arábica ou Conilon/Robusta
- Classificação: Tipo 2, 3, 4, 5, 6 ou 7 (ABIC)
- Peneira: número estimado
- Bebida: Estritamente Mole, Mole, Apenas Mole, Dura, Riada ou Rio
- Score de qualidade: 0 a 100 pontos
- Defeitos estimados: por 300g
- Observações: características visuais relevantes
- Confiança da análise: Alta, Média ou Baixa

Formate o laudo de forma clara e profissional em português.''',
              }
            ],
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final conteudo = data['content'][0]['text'] as String;

      // Gera um ID único baseado no hash da imagem + timestamp
      final hash = sha256
          .convert(bytes.sublist(0, bytes.length < 100 ? bytes.length : 100))
          .toString()
          .substring(0, 8);
      final id = '${DateTime.now().millisecondsSinceEpoch}-$hash';

      return LaudoResult(id: id, conteudo: conteudo);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(
          'Erro na API Claude: ${response.statusCode} - ${err['error']?['message'] ?? response.body}');
    }
  }
}
