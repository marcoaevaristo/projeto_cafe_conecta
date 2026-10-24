// lib/utils/erros.dart
// Mostra erros da API de forma legível. Se o erro for limite do plano,
// a mensagem vem com um botão que abre a tela de planos.
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/planos_screen.dart';

String mensagemDeErro(Object e) {
  if (e is ApiException) return e.message;
  if (e is String) return e; // mensagens de validação da própria tela
  return 'Não foi possível concluir. Verifique sua conexão e tente novamente.';
}

void mostrarErro(BuildContext context, Object e) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final navigator = Navigator.of(context, rootNavigator: true);
  final limite = e is ApiException && e.limiteDoPlano;
  messenger.showSnackBar(SnackBar(
    content: Text(mensagemDeErro(e)),
    duration: Duration(seconds: limite ? 8 : 4),
    action: limite
        ? SnackBarAction(
            label: 'Ver planos',
            onPressed: () => navigator.push(
                MaterialPageRoute(builder: (_) => const PlanosScreen())),
          )
        : null,
  ));
}
