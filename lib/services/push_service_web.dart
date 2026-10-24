import 'dart:convert';
import 'dart:js_interop';

import 'api_service.dart';

@JS('cafePush')
external _CafePush? get _cafePush;

extension type _CafePush._(JSObject _) implements JSObject {
  external bool suportado();
  external JSPromise<JSString> ativar(String chavePublica);
  external JSPromise<JSString> atual();
  external JSPromise<JSString> desativar();
}

class PushService {
  static bool get suportado {
    try {
      return _cafePush?.suportado() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Este navegador já está inscrito?
  static Future<bool> ativo() async {
    if (!suportado) return false;
    try {
      return (await _cafePush!.atual().toDart).toDart.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> ativar() async {
    if (!suportado) {
      throw 'Este navegador não aceita notificações. No iPhone, adicione o app à Tela de Início e abra por lá.';
    }
    final chave = await ApiService.getChavePush();
    if (chave == null) throw 'Notificações indisponíveis no servidor agora. Tente mais tarde.';
    String json;
    try {
      json = (await _cafePush!.ativar(chave).toDart).toDart;
    } catch (e) {
      final t = '$e';
      throw t.contains('negada')
          ? 'As notificações estão bloqueadas para este site. Libere nas configurações do navegador e tente de novo.'
          : 'Não foi possível ligar as notificações neste navegador.';
    }
    await ApiService.inscreverPush(jsonDecode(json) as Map<String, dynamic>);
  }

  static Future<void> desativar() async {
    if (!suportado) return;
    final endpoint = (await _cafePush!.desativar().toDart).toDart;
    if (endpoint.isNotEmpty) await ApiService.cancelarPush(endpoint);
  }
}
