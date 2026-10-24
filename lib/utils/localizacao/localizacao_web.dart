import 'dart:js_interop';

@JS('cafeLocal')
external JSPromise<JSString> _cafeLocal();

/// Devolve (latitude, longitude) do aparelho.
Future<(double, double)> minhaLocalizacao() async {
  try {
    final t = (await _cafeLocal().toDart).toDart.split(',');
    return (double.parse(t[0]), double.parse(t[1]));
  } catch (e) {
    throw '$e'.contains('negada')
        ? 'A localização está bloqueada para este site. Libere no navegador ou digite a distância.'
        : 'Não foi possível obter sua localização. Digite a distância.';
  }
}
