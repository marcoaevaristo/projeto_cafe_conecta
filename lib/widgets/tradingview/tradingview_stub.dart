// lib/widgets/tradingview/tradingview_stub.dart — fora da web: link para a cotação
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: () =>
            launchUrl(Uri.parse(linkUrl), mode: LaunchMode.externalApplication),
        icon: const Icon(Icons.open_in_new),
        label: const Text('Ver cotação no TradingView'),
      );
}
