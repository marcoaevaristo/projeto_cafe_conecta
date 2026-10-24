import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

@JS('cafeGoogle')
external _CafeGoogle? get _cafeGoogle;

extension type _CafeGoogle._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> botao(web.HTMLElement elemento, String clientId, int largura, JSFunction aoEntrar);
}

class BotaoGoogle extends StatelessWidget {
  final String clientId;
  final void Function(String credencial) aoEntrar;
  const BotaoGoogle({super.key, required this.clientId, required this.aoEntrar});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final largura = c.maxWidth.isFinite ? c.maxWidth.clamp(200, 400).toInt() : 320;
      return SizedBox(
        height: 46,
        child: HtmlElementView.fromTagName(
          key: ValueKey('google-$largura'),
          tagName: 'div',
          onElementCreated: (Object el) {
            final div = el as web.HTMLElement;
            div.style
              ..display = 'flex'
              ..justifyContent = 'center'
              ..alignItems = 'center';
            final cb = ((JSString cred) => aoEntrar(cred.toDart)).toJS;
            _cafeGoogle?.botao(div, clientId, largura, cb);
          },
        ),
      );
    });
  }
}
