// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cafe_model.dart';

const _base = 'https://cafe-conecta-backend.vercel.app';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  // ── Token ───────────────────────────────────────────────────────────
  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Map<String, String> _headers({bool auth = false, String? token}) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (auth && token != null) 'Authorization': 'Bearer $token',
  };

  static Future<Map<String, String>> _authHeaders() async {
    final t = await _token();
    return _headers(auth: true, token: t);
  }

  static Map<String, dynamic> _decode(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, body['error'] ?? 'Erro desconhecido');
    }
    return body as Map<String, dynamic>;
  }

  // ── Auth ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String email, String senha) async {
    final res = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'senha': senha}),
    );
    final data = _decode(res);
    if (data['token'] != null) await saveToken(data['token']);
    return data;
  }

  static Future<Map<String, dynamic>> cadastrar(Map<String, dynamic> dados) async {
    final res = await http.post(
      Uri.parse('$_base/auth/cadastro'),
      headers: _headers(),
      body: jsonEncode(dados),
    );
    final data = _decode(res);
    if (data['token'] != null) await saveToken(data['token']);
    return data;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final h = await _authHeaders();
    final res = await http.get(Uri.parse('$_base/auth/me'), headers: h);
    return _decode(res);
  }

  // ── Cafés ────────────────────────────────────────────────────────────
  static Future<List<CafeModel>> getCafes({
    int? usuarioId,
    String? tipo,
    String? classificacao,
    int? scoreMinimo,
    String? status,
  }) async {
    final params = <String, String>{};
    if (usuarioId != null) params['usuario_id'] = usuarioId.toString();
    if (tipo != null) params['tipo'] = tipo;
    if (classificacao != null) params['classificacao'] = classificacao;
    if (scoreMinimo != null) params['score_minimo'] = scoreMinimo.toString();
    if (status != null) params['status'] = status;

    final h = await _authHeaders();
    final uri = Uri.parse('$_base/cafes').replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri, headers: h);
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiException(res.statusCode, (data as Map)['error'] ?? 'Erro');
    return (data as List).map((e) => CafeModel.fromMap(e)).toList();
  }

  static Future<void> inserirCafe(CafeModel cafe) async {
    final h = await _authHeaders();
    final res = await http.post(
      Uri.parse('$_base/cafes'),
      headers: h,
      body: jsonEncode(cafe.toMap()),
    );
    _decode(res);
  }

  static Future<void> atualizarStatusCafe(int cafeId, String status) async {
    final h = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$_base/cafes/$cafeId/status'),
      headers: h,
      body: jsonEncode({'status': status}),
    );
    _decode(res);
  }

  // ── Favoritos ────────────────────────────────────────────────────────
  static Future<List<CafeModel>> getFavoritos() async {
    final h = await _authHeaders();
    final res = await http.get(Uri.parse('$_base/favoritos'), headers: h);
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiException(res.statusCode, (data as Map)['error'] ?? 'Erro');
    return (data as List).map((e) => CafeModel.fromMap(e)).toList();
  }

  /// Verifica se um café está nos favoritos do usuário (busca lista local).
  static Future<bool> isFavorito(int cafeId) async {
    try {
      final favs = await getFavoritos();
      return favs.any((c) => c.id == cafeId);
    } catch (_) {
      return false;
    }
  }

  static Future<void> toggleFavorito(int cafeId) async {
    final h = await _authHeaders();
    await http.post(
      Uri.parse('$_base/favoritos/$cafeId'),
      headers: h,
    );
  }

  // ── Mensagens / Conversas ────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getConversas() async {
    final h = await _authHeaders();
    final res = await http.get(Uri.parse('$_base/mensagens/conversas'), headers: h);
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiException(res.statusCode, (data as Map)['error'] ?? 'Erro');
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<List<MensagemModel>> getMensagensConversa(int contatoId) async {
    final h = await _authHeaders();
    final res = await http.get(Uri.parse('$_base/mensagens/$contatoId'), headers: h);
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiException(res.statusCode, (data as Map)['error'] ?? 'Erro');
    return (data as List).map((e) => MensagemModel.fromMap(e)).toList();
  }

  static Future<void> enviarMensagem(int paraId, String texto) async {
    final h = await _authHeaders();
    final res = await http.post(
      Uri.parse('$_base/mensagens'),
      headers: h,
      body: jsonEncode({'para_usuario_id': paraId, 'texto': texto}),
    );
    _decode(res);
  }

  static Future<int> countNaoLidas() async {
    final h = await _authHeaders();
    final res = await http.get(Uri.parse('$_base/mensagens/nao-lidas'), headers: h);
    final data = _decode(res);
    return data['count'] ?? 0;
  }

  // ── Alertas ──────────────────────────────────────────────────────────
  static Future<List<AlertaModel>> getAlertas() async {
    final h = await _authHeaders();
    final res = await http.get(Uri.parse('$_base/alertas'), headers: h);
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiException(res.statusCode, (data as Map)['error'] ?? 'Erro');
    return (data as List).map((e) => AlertaModel.fromMap(e)).toList();
  }

  static Future<void> inserirAlerta(AlertaModel alerta) async {
    final h = await _authHeaders();
    final res = await http.post(
      Uri.parse('$_base/alertas'),
      headers: h,
      body: jsonEncode(alerta.toMap()),
    );
    _decode(res);
  }

  static Future<void> toggleAlerta(int alertaId, bool ativo) async {
    final h = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$_base/alertas/$alertaId'),
      headers: h,
      body: jsonEncode({'ativo': ativo}),
    );
    _decode(res);
  }

  static Future<void> excluirAlerta(int alertaId) async {
    final h = await _authHeaders();
    final res = await http.delete(Uri.parse('$_base/alertas/$alertaId'), headers: h);
    _decode(res);
  }

  // ── Propostas ────────────────────────────────────────────────────────
  static Future<List<PropostaModel>> getPropostas() async {
    final h = await _authHeaders();
    final res = await http.get(Uri.parse('$_base/propostas'), headers: h);
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiException(res.statusCode, (data as Map)['error'] ?? 'Erro');
    return (data as List).map((e) => PropostaModel.fromMap(e)).toList();
  }

  static Future<void> inserirProposta(PropostaModel proposta) async {
    final h = await _authHeaders();
    final res = await http.post(
      Uri.parse('$_base/propostas'),
      headers: h,
      body: jsonEncode(proposta.toMap()),
    );
    _decode(res);
  }

  static Future<void> atualizarStatusProposta(int propostaId, String status) async {
    final h = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$_base/propostas/$propostaId/status'),
      headers: h,
      body: jsonEncode({'status': status}),
    );
    _decode(res);
  }

  static Future<bool> jaAvaliou(int propostaId) async {
    final h = await _authHeaders();
    final res = await http.get(Uri.parse('$_base/avaliacoes/ja-avaliou/$propostaId'), headers: h);
    final data = _decode(res);
    return data['jaAvaliou'] == true;
  }

  // ── Avaliações ───────────────────────────────────────────────────────
  static Future<List<AvaliacaoModel>> getAvaliacoes(int usuarioId) async {
    final h = await _authHeaders();
    final res = await http.get(Uri.parse('$_base/avaliacoes/$usuarioId'), headers: h);
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiException(res.statusCode, (data as Map)['error'] ?? 'Erro');
    return (data as List).map((e) => AvaliacaoModel.fromMap(e)).toList();
  }

  static Future<Map<String, dynamic>> getResumoAvaliacoes(int usuarioId) async {
    final h = await _authHeaders();
    final res = await http.get(Uri.parse('$_base/avaliacoes/$usuarioId/resumo'), headers: h);
    return _decode(res);
  }

  static Future<void> inserirAvaliacao(AvaliacaoModel avaliacao) async {
    final h = await _authHeaders();
    final res = await http.post(
      Uri.parse('$_base/avaliacoes'),
      headers: h,
      body: jsonEncode(avaliacao.toMap()),
    );
    _decode(res);
  }

  // ── Dashboard ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboard() async {
    final h = await _authHeaders();
    final res = await http.get(Uri.parse('$_base/dashboard'), headers: h);
    return _decode(res);
  }

  static Future<List<HistoricoPrecoModel>> getHistoricoPrecos() async {
    final h = await _authHeaders();
    final res = await http.get(Uri.parse('$_base/historico-precos'), headers: h);
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiException(res.statusCode, (data as Map)['error'] ?? 'Erro');
    return (data as List).map((e) => HistoricoPrecoModel.fromMap(e)).toList();
  }
}
