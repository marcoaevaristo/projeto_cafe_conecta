// lib/services/app_state.dart — v3
import 'package:flutter/material.dart';
import '../models/cafe_model.dart';
import 'database_service.dart';
import 'planos_service.dart';

class AppState extends ChangeNotifier {
  UsuarioModel? _usuario;
  int _msgNaoLidas = 0;
  int _propostasNaoLidas = 0;

  UsuarioModel? get usuario => _usuario;
  bool get logado => _usuario != null;
  int get msgNaoLidas => _msgNaoLidas;
  int get propostasNaoLidas => _propostasNaoLidas;

  Future<bool> login(String email, String senha) async {
    final u = await DatabaseService.login(email, senha);
    if (u != null) {
      _usuario = u;
      await refresh();
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _usuario = null;
    _msgNaoLidas = 0;
    _propostasNaoLidas = 0;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_usuario?.id != null) {
      _msgNaoLidas = await DatabaseService.countNaoLidas(_usuario!.id!);
      final propostas = await DatabaseService.getPropostas(_usuario!.id!);
      _propostasNaoLidas = propostas.where((p) =>
        p.status == 'aguardando' && p.paraUsuarioId == _usuario!.id).length;
      notifyListeners();
    }
  }

  Future<bool> cadastrar({
    required String nome, required String email,
    required String senha, required String tipo,
    String? empresa, String? telefone, String? regiao,
  }) async {
    try {
      final id = await DatabaseService.cadastrarUsuario({
        'nome': nome, 'email': email, 'senha': senha, 'tipo': tipo,
        'empresa': empresa, 'telefone': telefone, 'regiao': regiao,
      });
      _usuario = await DatabaseService.getUsuario(id);
      notifyListeners();
      return true;
    } catch (_) { return false; }
  }

  // Planos
  Plan? _plano;
  Plan? get plano => _plano;
  int get planoTier => _plano?.tier ?? 0;

  bool hasAccessForTier(int requiredTier) => planoTier >= requiredTier;

  void upgradePlan(Plan p) {
    _plano = p;
    notifyListeners();
  }
}
