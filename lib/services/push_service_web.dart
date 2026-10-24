import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'api_service.dart';

JSObject? get _cafePush => globalContext['cafePush'] as JSObject?;

class PushService {
  static bool get suportado {
    try {
      return (_cafePush?.callMethod<JSBoolean>('suportado'.toJS))?.toDart ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Este navegador já está inscrito?
  static Future<bool> ativo() async {
    if (!suportado) return false;
    try {
      return (await _cafePush!.callMethod<JSPromise<JSString>>('atual'.toJS).toDart).toDart.isNotEmpty;
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
      json = (await _cafePush!.callMethod<JSPromise<JSString>>('ativar'.toJS, chave.toJS).toDart).toDart;
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
    final endpoint = (await _cafePush!.callMethod<JSPromise<JSString>>('desativar'.toJS).toDart).toDart;
    if (endpoint.isNotEmpty) await ApiService.cancelarPush(endpoint);
  }
}
