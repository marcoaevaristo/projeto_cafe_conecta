// lib/services/laudo_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class LaudoResult {
  final String id;
  final String conteudo;
  LaudoResult({required this.id, required this.conteudo});

  factory LaudoResult.fromJson(Map<String, dynamic> j) => LaudoResult(
    id: j['id'] ?? '', conteudo: j['conteudo'] ?? j['content'] ?? '',
  );
}

class LaudoService {
  static const _apiKey = String.fromEnvironment('AI_API_KEY', defaultValue: '');
  static const _baseUrl = String.fromEnvironment('AI_API_URL', defaultValue: 'https://example.com');

  static Future<LaudoResult> generateFromImage(File image) async {
    if (_apiKey.isEmpty) throw Exception('AI API key not provided. Use --dart-define=AI_API_KEY=YOUR_KEY');

    final uri = Uri.parse('$_baseUrl/generate_laudo');
    final req = http.MultipartRequest('POST', uri);
    req.headers['Authorization'] = 'Bearer $_apiKey';
    req.files.add(await http.MultipartFile.fromPath('file', image.path));

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final j = json.decode(resp.body) as Map<String, dynamic>;
      return LaudoResult.fromJson(j);
    }
    throw Exception('Laudo API error: ${resp.statusCode} ${resp.body}');
  }
}
