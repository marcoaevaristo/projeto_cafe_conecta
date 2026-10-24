class PushService {
  static bool get suportado => false;
  static Future<bool> ativo() async => false;
  static Future<void> ativar() async => throw UnsupportedError('Notificações disponíveis só na versão web por enquanto');
  static Future<void> desativar() async {}
}
