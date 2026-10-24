import 'package:flutter/material.dart';

class BotaoGoogle extends StatelessWidget {
  final String clientId;
  final void Function(String credencial) aoEntrar;
  const BotaoGoogle({super.key, required this.clientId, required this.aoEntrar});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
