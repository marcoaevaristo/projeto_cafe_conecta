// lib/widgets/tradingview/tradingview_widget.dart
// Widgets gratuitos do TradingView (cotações com o crédito "por TradingView").
// Na web o widget roda dentro de um iframe; fora da web mostra um link.
export 'tradingview_stub.dart' if (dart.library.js_interop) 'tradingview_web.dart';
