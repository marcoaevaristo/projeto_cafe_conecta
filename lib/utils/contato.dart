// lib/utils/contato.dart — contato do responsável pelo Café Conecta (ajuda e relato de erros)
import 'package:url_launcher/url_launcher.dart';

const contatoWhatsappExibicao = '(35) 99750-0438';
const contatoWhatsappNumero = '5535997500438'; // DDI + DDD + número, sem símbolos
const contatoEmail = 'marcoaevaristo@hotmail.com';

Future<bool> abrirWhatsapp(String mensagem) => launchUrl(
      Uri.parse('https://wa.me/$contatoWhatsappNumero?text=${Uri.encodeComponent(mensagem)}'),
      mode: LaunchMode.externalApplication,
    );

Future<bool> abrirEmail(String assunto, String mensagem) => launchUrl(Uri(
      scheme: 'mailto',
      path: contatoEmail,
      // Uri(queryParameters) troca espaço por "+", que alguns apps de e-mail mostram literalmente
      query: 'subject=${Uri.encodeComponent(assunto)}&body=${Uri.encodeComponent(mensagem)}',
    ));
