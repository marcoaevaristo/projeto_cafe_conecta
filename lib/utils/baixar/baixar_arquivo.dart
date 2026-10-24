// lib/utils/baixar/baixar_arquivo.dart — baixa um arquivo gerado no app.
// Na web cria o download pelo navegador; fora da web ainda não é suportado.
export 'baixar_stub.dart' if (dart.library.js_interop) 'baixar_web.dart';
