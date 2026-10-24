// lib/utils/compartilhar.dart — compartilhar um lote (WhatsApp ou link copiado)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/cafe_model.dart';
import '../services/api_service.dart';
import 'theme.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

/// Link público do lote (página com prévia para WhatsApp/redes, abre o lote no app).
String linkDoLote(String id) => '${ApiService.baseUrl}/l/$id';

String textoDoLote(CafeModel c) {
  final partes = [
    '☕ ${c.tipo} ${c.classificacao}',
    if (c.bebida != null && c.bebida!.isNotEmpty) 'bebida ${c.bebida}',
    if (c.peneira != null && c.peneira!.isNotEmpty) 'peneira ${c.peneira}',
  ].join(' · ');
  final preco = c.precoSaca != null ? ' a ${_brl.format(c.precoSaca)}/saca' : '';
  return '$partes\n${c.quantidade} sacas$preco · ${c.cidade}${c.regiao.isNotEmpty ? ' (${c.regiao})' : ''}\n'
      'Veja no Café Conecta: ${linkDoLote(c.id!)}';
}

Future<void> compartilharLote(BuildContext context, CafeModel cafe) async {
  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text('Compartilhar lote',
              style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        ListTile(
          leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
          title: const Text('Enviar no WhatsApp'),
          subtitle: const Text('Escolha o contato ou grupo'),
          onTap: () async {
            Navigator.pop(ctx);
            await launchUrl(
              Uri.parse('https://wa.me/?text=${Uri.encodeComponent(textoDoLote(cafe))}'),
              mode: LaunchMode.externalApplication,
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.link, color: CafeColors.caramel),
          title: const Text('Copiar link'),
          subtitle: Text(linkDoLote(cafe.id!), maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: textoDoLote(cafe)));
            if (ctx.mounted) Navigator.pop(ctx);
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Link do lote copiado')));
            }
          },
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );
}
