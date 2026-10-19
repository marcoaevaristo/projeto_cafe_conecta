// lib/screens/ajuda_screen.dart — perguntas frequentes
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';

class AjudaScreen extends StatelessWidget {
  const AjudaScreen({super.key});

  static const _perguntas = <(String, String)>[
    ('Como anuncio um lote?',
        'Vá em Perfil → Meus Anúncios → Novo Anúncio. Preencha tipo, classificação, quantidade, '
            'região e cidade. A partir do plano Básico você também pode adicionar fotos.'),
    ('Quem pode comprar e quem pode vender?',
        'Todas as contas podem anunciar e vender. Compradores e corretores também podem fazer '
            'propostas de compra. Produtores só anunciam e vendem.'),
    ('Como funciona uma proposta?',
        'No catálogo, toque em Proposta no lote desejado e informe valor, quantidade e condições. '
            'Quem anunciou pode aceitar, recusar ou responder com uma contraproposta, '
            'que fica aguardando a sua resposta.'),
    ('O que muda em cada plano?',
        'Gratuito: 2 lotes ativos, 3 propostas por mês e 1 alerta. Básico: 5 lotes, 3 fotos por lote, '
            '10 propostas e histórico de 3 meses. Profissional: lotes e propostas ilimitados, 10 fotos, '
            'mapa, IA (10 análises/mês) e laudo em PDF. Premium: tudo isso sem limites, histórico de '
            '12 meses e destaque na busca.'),
    ('Como pago a assinatura?',
        'Em Perfil → Assinatura escolha o plano e pague com PIX. Depois de pagar, toque em '
            '"Já paguei" para liberar na hora; o plano também é liberado sozinho quando o '
            'PagBank confirma. Cada pagamento vale 1 mês e não há renovação automática.'),
    ('Como funciona a classificação por IA?',
        'Disponível nos planos Profissional e Premium. Envie uma foto nítida da amostra de grãos, '
            'com boa luz. A IA estima tipo, peneira, defeitos e score e gera um laudo com QR Code. '
            'É uma análise visual: não substitui a classificação oficial nem a prova de xícara.'),
    ('Esqueci minha senha. E agora?',
        'Na tela de login, toque em "Esqueci minha senha". Você recebe um código de 6 dígitos '
            'por e-mail, válido por 15 minutos.'),
    ('Como altero meus dados ou excluo minha conta?',
        'Em Perfil → Configurações você edita nome, telefone, cidade e estado, troca a senha '
            'e, se quiser, exclui a conta com todos os seus dados.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajuda')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Text('Perguntas frequentes',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
        ),
        for (final (pergunta, resposta) in _perguntas)
          Card(
            child: ExpansionTile(
              title: Text(pergunta,
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resposta,
                    style: GoogleFonts.dmSans(
                        fontSize: 13, height: 1.5, color: CafeColors.darkRoast)),
              ],
            ),
          ),
      ]),
    );
  }
}
