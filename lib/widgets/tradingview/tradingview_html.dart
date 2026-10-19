// lib/widgets/tradingview/tradingview_html.dart
import 'dart:convert';

/// Monta o HTML de um widget oficial do TradingView ([script] é o nome do
/// arquivo embed-widget-*.js e [config] a configuração JSON do widget).
String htmlWidgetTradingView(String script, Map<String, dynamic> config) {
  // o JSON vai cru dentro do <script>; só impede que feche a tag antes da hora
  final cfg = jsonEncode(config).replaceAll('</', r'<\/');
  return '''<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>html,body{margin:0;height:100%;background:transparent;overflow:hidden;font-family:sans-serif}
.tradingview-widget-container{height:100%;width:100%;display:flex;flex-direction:column}
.tradingview-widget-container__widget{flex:1;min-height:0}
.tradingview-widget-copyright{font-size:11px;line-height:20px;text-align:right;color:#8B5E3C}
.tradingview-widget-copyright a{color:#C4863A;text-decoration:none}</style></head><body>
<div class="tradingview-widget-container">
<div class="tradingview-widget-container__widget"></div>
<div class="tradingview-widget-copyright"><a href="https://br.tradingview.com/" rel="noopener nofollow" target="_blank">Cotações por TradingView</a></div>
<script type="text/javascript" src="https://s3.tradingview.com/external-embedding/$script" async>$cfg</script>
</div></body></html>''';
}
