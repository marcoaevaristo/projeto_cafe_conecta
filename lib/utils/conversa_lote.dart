// lib/utils/conversa_lote.dart — abre a conversa com quem anunciou um lote
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cafe_model.dart';
import '../screens/conversa_screen.dart';

void abrirConversaSobreLote(BuildContext context, CafeModel cafe) {
  final qtd = NumberFormat('#,###', 'pt_BR').format(cafe.quantidade);
  final local = [cafe.fazenda, cafe.cidade].where((x) => x != null && x.isNotEmpty).join(', ');
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ConversaScreen(
        contatoId: cafe.usuarioId,
        contatoNome: cafe.corretorNome ?? 'Anunciante',
        contatoEmpresa: cafe.corretorEmpresa,
        mensagemInicial: 'Olá! Tenho interesse no seu lote ${cafe.nomeCurto} '
            '($qtd sacas${local.isEmpty ? '' : ', $local'}). Ainda está disponível?',
      ),
    ),
  );
}
