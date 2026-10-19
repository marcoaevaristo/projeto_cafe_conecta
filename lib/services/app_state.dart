// lib/services/app_state.dart
import 'package:flutter/material.dart';
import '../models/cafe_model.dart';
import 'api_service.dart';
import 'planos_service.dart';

class AppState extends ChangeNotifier {
  UsuarioModel? _usuario;
  int _msgNaoLidas = 0;
  int _propostasNaoLidas = 0;

  UsuarioModel? get usuario => _usuario;
  bool get logado => _usuario != null;
  int get msgNaoLidas => _msgNaoLidas;
  int get propostasNaoLidas => _propostasNaoLidas;

  /// Chamado na inicialização do app para restaurar sessão via JWT salvo.
  Future<void> tryRestoreSession() async {
    try {
      final me = await ApiService.getMe();
      _usuario = UsuarioModel.fromMap(me);
      _planoAtual = _planoParaPlano(_usuario!.plano);
      await refresh();
      notifyListeners();
    } catch (_) {
      // Token expirado ou ausente — fica deslogado
    }
  }

  Future<bool> login(String email, String senha) async {
    try {
      final data = await ApiService.login(email, senha);
      final me = await ApiService.getMe();
      _usuario = UsuarioModel.fromMap(me);
      _planoAtual = _planoParaPlano(_usuario!.plano);
      await refresh();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Busca os dados do usuário de novo (ex.: depois de pagar um plano ou editar o perfil).
  Future<void> recarregarUsuario() async {
    final me = await ApiService.getMe();
    _usuario = UsuarioModel.fromMap(me);
    _planoAtual = _planoParaPlano(_usuario!.plano);
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _usuario = null;
    _msgNaoLidas = 0;
    _propostasNaoLidas = 0;
    _planoAtual = PlanoTipo.gratuito;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_usuario != null) {
      try {
        _msgNaoLidas = await ApiService.countNaoLidas();
        final propostas = await ApiService.getPropostas();
        _propostasNaoLidas = propostas
            .where((p) => p.status == 'aguardando' && p.paraUsuarioId == _usuario!.id)
            .length;
      } catch (_) {}
      notifyListeners();
    }
  }

  Future<bool> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String tipo,
    String? empresa,
    String? telefone,
    String? regiao,
  }) async {
    try {
      await ApiService.cadastrar({
        'nome': nome,
        'email': email,
        'senha': senha,
        'tipo': tipo,
        'empresa': empresa,
        'telefone': telefone,
        'regiao': regiao,
      });
      final me = await ApiService.getMe();
      _usuario = UsuarioModel.fromMap(me);
      _planoAtual = _planoParaPlano(_usuario!.plano);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Planos ──────────────────────────────────────────────────────────
  PlanoTipo _planoAtual = PlanoTipo.gratuito;
  PlanoTipo get planoAtual => _planoAtual;

  Plan get plano => PlanosService.getByTipo(_planoAtual);

  int get planoTier => _planoAtual.index;

  bool hasAccessForTier(int requiredTier) => planoTier >= requiredTier;

  bool temAcesso(String recurso) => PlanosService.temAcesso(_planoAtual, recurso);

  void upgradePlan(PlanoTipo tipo) {
    _planoAtual = tipo;
    notifyListeners();
  }

  /// Mapeia o campo `plano` retornado pela API para o enum PlanoTipo.
  PlanoTipo _planoParaPlano(String? plano) {
    switch (plano) {
      case 'basico': return PlanoTipo.basico;
      case 'profissional': return PlanoTipo.profissional;
      case 'premium': return PlanoTipo.premium;
      default: return PlanoTipo.gratuito;
    }
  }
}
