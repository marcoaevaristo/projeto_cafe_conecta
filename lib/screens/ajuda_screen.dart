// lib/screens/ajuda_screen.dart — perguntas frequentes
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/contato.dart';
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
    ('Encontrei um erro. Como aviso?',
        'Use "Relatar um erro" nesta tela: descreva o que aconteceu e envie por WhatsApp ou e-mail. '
            'A mensagem já leva os dados da sua conta para facilitar a análise.'),
    ('Como altero meus dados ou excluo minha conta?',
        'Em Perfil → Configurações você edita nome, telefone, cidade e estado, troca a senha '
            'e, se quiser, exclui a conta com todos os seus dados.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajuda e contato')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        const _Contato(),
        const SizedBox(height: 8),
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


// ── Contato e relato de erros ─────────────────────────────────────────
class _Contato extends StatefulWidget {
  const _Contato();
  @override
  State<_Contato> createState() => _ContatoState();
}

class _ContatoState extends State<_Contato> {
  final _descricao = TextEditingController();

  @override
  void dispose() {
    _descricao.dispose();
    super.dispose();
  }

  // Dados que ajudam a investigar o problema (nada de senha ou pagamento)
  String _diagnostico() {
    final estado = context.read<AppState>();
    final u = estado.usuario;
    final agora = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    return [
      '— Dados para análise —',
      if (u != null) 'Conta: ${u.email} (${u.tipo})',
      if (u != null) 'Plano: ${estado.plano.nome}',
      'Data: $agora',
    ].join('\n');
  }

  String _mensagemErro() {
    final texto = _descricao.text.trim();
    return 'Olá! Encontrei um erro no Café Conecta.\n\n'
        'O que aconteceu: ${texto.isEmpty ? '(descreva aqui)' : texto}\n\n'
        '${_diagnostico()}';
  }

  Future<void> _abrir(Future<bool> Function() acao, String alternativa) async {
    var abriu = false;
    try {
      abriu = await acao();
    } catch (_) {}
    if (!abriu && mounted) {
      // Sem app de WhatsApp/e-mail: copia o contato para a pessoa usar onde preferir
      await Clipboard.setData(ClipboardData(text: alternativa));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Não foi possível abrir o aplicativo. Copiado: $alternativa')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Fale com a gente',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
          const SizedBox(height: 4),
          Text('Dúvidas, sugestões ou algo que não funcionou.',
              style: GoogleFonts.dmSans(fontSize: 13, color: CafeColors.lightRoast)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                onPressed: () => _abrir(
                    () => abrirWhatsapp('Olá! Preciso de ajuda com o Café Conecta.\n\n${_diagnostico()}'),
                    contatoWhatsappExibicao),
                icon: const Icon(Icons.chat),
                label: const Text('WhatsApp'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _abrir(
                    () => abrirEmail('Ajuda — Café Conecta',
                        'Olá! Preciso de ajuda com o Café Conecta.\n\n${_diagnostico()}'),
                    contatoEmail),
                icon: const Icon(Icons.email_outlined),
                label: const Text('E-mail'),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          SelectableText('$contatoWhatsappExibicao · $contatoEmail',
              style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
          const Divider(height: 28),
          Text('Relatar um erro',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
          const SizedBox(height: 8),
          TextField(
            controller: _descricao,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'O que você estava fazendo e o que aconteceu? Ex.: "Ao publicar um anúncio com foto, apareceu erro."',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _abrir(() => abrirWhatsapp(_mensagemErro()), contatoWhatsappExibicao),
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Enviar por WhatsApp'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _abrir(
                    () => abrirEmail('Erro no Café Conecta', _mensagemErro()), contatoEmail),
                icon: const Icon(Icons.email_outlined),
                label: const Text('Enviar por e-mail'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
