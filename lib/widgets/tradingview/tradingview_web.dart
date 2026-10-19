// lib/widgets/tradingview/tradingview_web.dart — versão web (iframe com o widget)
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'tradingview_html.dart';

class TradingViewWidget extends StatelessWidget {
  final String script;
  final Map<String, dynamic> config;
  final double altura;
  final String linkUrl;

  const TradingViewWidget({
    super.key,
    required this.script,
    required this.config,
    required this.altura,
    required this.linkUrl,
  });

  @override
  Widget build(BuildContext context) {
    final html = htmlWidgetTradingView(script, config);
    return SizedBox(
      height: altura,
      child: HtmlElementView.fromTagName(
        // a chave muda com a configuração para recriar o iframe quando ela mudar
        key: ValueKey(html.hashCode),
        tagName: 'iframe',
        onElementCreated: (Object el) {
          final iframe = el as web.HTMLIFrameElement;
          iframe.style
            ..border = 'none'
            ..width = '100%'
            ..height = '100%'
            ..backgroundColor = 'transparent';
          // srcdoc via propriedade direta: funciona em qualquer versão do pacote web
          (iframe as JSObject).setProperty('srcdoc'.toJS, html.toJS);
        },
      ),
    );
  }
}
