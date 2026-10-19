// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cafe_model.dart';

const _base = 'https://cafe-conecta-backend.vercel.app';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  /// Ex.: 'LIMITE_PLANO' quando o plano do usuário não permite a ação.
  final String? codigo;
  final String? planoNecessario;
  ApiException(this.statusCode, this.message, {this.codigo, this.planoNecessario});

  bool get limiteDoPlano => codigo == 'LIMITE_PLANO';
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
      throw ApiException(res.statusCode, body['error'] ?? 'Erro desconhecido',
          codigo: body['codigo'], planoNecessario: body['plano_necessario']);
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

  static Future<Map<String, dynamic>> esqueciSenha(String email) async {
    final res = await http.post(
      Uri.parse('$_base/auth/esqueci-senha'),
      headers: _headers(),
      body: jsonEncode({'email': email}),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> resetarSenha(
      String email, String codigo, String novaSenha) async {
    final res = await http.post(
      Uri.parse('$_base/auth/resetar-senha'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'codigo': codigo, 'nova_senha': novaSenha}),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> getMe() async {
    final h = await _authHeaders();
    final res = await http.get(Uri.parse('$_base/auth/me'), headers: h);
    return _decode(res);
  }

  // ── Cafés ────────────────────────────────────────────────────────────
  static Future<List<CafeModel>> getCafes({
    String? usuarioId,
    String? tipo,
    String? classificacao,
    int? scoreMinimo,
    String? status,
  }) async {
    final params = <String, String>{};
    if (usuarioId != null) params['usuario_id'] = usuarioId;
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

  /// Cria o lote e devolve o id gerado (usado para enviar as fotos em seguida).
  static Future<String?> inserirCafe(CafeModel cafe) async {
    final h = await _authHeaders();
    final res = await http.post(
      Uri.parse('$_base/cafes'),
      headers: h,
      body: jsonEncode(cafe.toMap()),
    );
    return _decode(res)['id']?.toString();
  }

  /// Envia uma foto para o lote. A imagem vai em base64 para o backend,
  /// que guarda no Supabase Storage e respeita o limite de fotos do plano.
  static Future<void> adicionarFotoCafe(
      String cafeId, List<int> bytes, String contentType) async {
    final h = await _authHeaders();
    final res = await http.post(
      Uri.parse('$_base/cafes/$cafeId/fotos'),
      headers: h,
      body: jsonEncode({'imagem': base64Encode(bytes), 'content_type': contentType}),
    );
    _decode(res);
  }

  /// Classificação por IA: devolve tipo, classificacao, peneira, bebida, score,
  /// defeitos_300g, observacoes, confianca, texto, id e url (página pública do laudo).
  static Future<Map<String, dynamic>> gerarLaudoIA(
      List<int> bytes, String contentType, {String? cafeId}) async {
    final h = await _authHeaders();
    final res = await http.post(
      Uri.parse('$_base/ia/laudo'),
      headers: h,
      body: jsonEncode({
        'imagem': base64Encode(bytes),
        'content_type': contentType,
        if (cafeId != null) 'cafe_id': cafeId,
      }),
    );
    return _decode(res);
  }

  static Future<void> atualizarStatusCafe(String cafeId, String status) async {
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
  static Future<bool> isFavorito(String cafeId) async {
    try {
      final favs = await getFavoritos();
      return favs.any((c) => c.id == cafeId);
    } catch (_) {
      return false;
    }
  }

  static Future<void> toggleFavorito(String cafeId) async {
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

  static Future<List<MensagemModel>> getMensagensConversa(String contatoId) async {
    final h = await _authHeaders();
    final res = await http.get(Uri.parse('$_base/mensagens/$contatoId'), headers: h);
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiException(res.statusCode, (data as Map)['error'] ?? 'Erro');
    return (data as List).map((e) => MensagemModel.fromMap(e)).toList();
  }

  static Future<void> enviarMensagem(String paraId, String texto) async {
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
    return (data['count'] ?? data['total'] ?? 0) as int;
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

  static Future<void> toggleAlerta(String alertaId, bool ativo) async {
    final h = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$_base/alertas/$alertaId'),
      headers: h,
      body: jsonEncode({'ativo': ativo}),
    );
    _decode(res);
  }

  static Future<void> excluirAlerta(String alertaId) async {
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

  static Future<void> inserirProposta(PropostaModel proposta,
      {String? contrapropostaDe}) async {
    final h = await _authHeaders();
    final res = await http.post(
      Uri.parse('$_base/propostas'),
      headers: h,
      body: jsonEncode({
        ...proposta.toMap(),
        if (contrapropostaDe != null) 'contraproposta_de': contrapropostaDe,
      }),
    );
    _decode(res);
  }

  static Future<void> atualizarStatusProposta(String propostaId, String status) async {
    final h = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$_base/propostas/$propostaId/status'),
      headers: h,
      body: jsonEncode({'status': status}),
    );
    _decode(res);
  }

  static Future<bool> jaAvaliou(String propostaId) async {
    final h = await _authHeaders();
    final res = await http.get(Uri.parse('$_base/avaliacoes/ja-avaliou/$propostaId'), headers: h);
    final data = _decode(res);
    return data['jaAvaliou'] == true;
  }

  // ── Avaliações ───────────────────────────────────────────────────────
  static Future<List<AvaliacaoModel>> getAvaliacoes(String usuarioId) async {
    final h = await _authHeaders();
    final res = await http.get(Uri.parse('$_base/avaliacoes/$usuarioId'), headers: h);
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiException(res.statusCode, (data as Map)['error'] ?? 'Erro');
    return (data as List).map((e) => AvaliacaoModel.fromMap(e)).toList();
  }

  static Future<Map<String, dynamic>> getResumoAvaliacoes(String usuarioId) async {
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

  // ── Assinatura (PagBank) ─────────────────────────────────────────────
  /// Cria o pedido no PagBank para o usuário logado.
  static Future<Map<String, dynamic>> criarAssinatura(Map<String, dynamic> dados) async {
    final h = await _authHeaders();
    final res = await http.post(Uri.parse('$_base/pagbank/criar-assinatura'),
        headers: h, body: jsonEncode(dados));
    return _decode(res);
  }

  /// Confirma no PagBank se o pedido já foi pago e, se sim, libera o plano.
  /// Retorna { situacao: 'pago' | 'pendente' | 'recusado', plano, valido_ate }.
  static Future<Map<String, dynamic>> verificarPagamento(String orderId) async {
    final h = await _authHeaders();
    final res = await http.get(Uri.parse('$_base/pagbank/verificar/$orderId'), headers: h);
    return _decode(res);
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
