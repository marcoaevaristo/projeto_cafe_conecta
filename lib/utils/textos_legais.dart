// lib/utils/textos_legais.dart — Termos de uso e Política de privacidade.
// Ao mudar o conteúdo, atualize [versaoTermos] (o cadastro registra a versão aceita).

const versaoTermos = '2026-10-24';
const dataTermos = '24 de outubro de 2026';
const responsavelApp = 'Marco Antônio Evaristo';
const contatoPrivacidade = 'cafeconecta5@gmail.com';

typedef SecaoLegal = ({String titulo, List<String> paragrafos});

const List<SecaoLegal> termosDeUso = [
  (titulo: '1. O que é o Café Conecta', paragrafos: [
    'O Café Conecta é uma plataforma on-line que aproxima produtores, corretores e compradores de café. Pelo app é possível anunciar lotes, consultar o catálogo, enviar propostas e contrapropostas, conversar por mensagens, acompanhar cotações e criar alertas de preço.',
    'O Café Conecta é mantido por $responsavelApp. Ao criar uma conta ou usar o app, você concorda com estes Termos e com a Política de privacidade.',
  ]),
  (titulo: '2. O papel do Café Conecta nas negociações', paragrafos: [
    'O Café Conecta não compra, não vende, não armazena, não transporta e não intermedeia financeiramente o café anunciado. As negociações, os pagamentos, a entrega e a qualidade do produto são combinados e cumpridos diretamente entre comprador e vendedor, que respondem por eles.',
    'Uma proposta aceita no app registra a intenção das partes. Recomendamos formalizar o negócio por escrito e conferir amostra, classificação e documentação antes de fechar.',
  ]),
  (titulo: '3. Sua conta', paragrafos: [
    'Você deve informar dados verdadeiros e mantê-los atualizados. A conta é pessoal: guarde sua senha e avise-nos se suspeitar de uso indevido.',
    'Contas de produtor anunciam e vendem; contas de comprador e de corretor também podem fazer propostas de compra.',
    'Você pode excluir sua conta a qualquer momento em Configurações. A exclusão apaga seus anúncios, propostas, mensagens e fotos.',
  ]),
  (titulo: '4. Anúncios e conteúdo', paragrafos: [
    'Quem anuncia é responsável pelas informações do lote (tipo, classificação, bebida, peneira, quantidade, preço, fotos e localização) e garante que tem o direito de vendê-lo.',
    'Não é permitido anunciar produto inexistente ou de terceiros sem autorização, publicar conteúdo falso, ofensivo ou ilegal, usar o app para fraudes, enviar mensagens em massa ou tentar acessar contas e dados de outras pessoas.',
    'Podemos remover anúncios e suspender contas que descumpram estes Termos.',
  ]),
  (titulo: '5. Cotações, índices e classificação por IA', paragrafos: [
    'As cotações exibidas vêm de fontes de terceiros (Banco Central do Brasil, TradingView e os sites indicados no app) e podem ter atraso. O Índice Café Conecta é calculado com os lotes anunciados e os negócios informados no próprio app.',
    'A classificação do café por inteligência artificial é uma estimativa feita a partir de uma foto e não substitui a classificação oficial por um profissional habilitado.',
    'Essas informações servem de referência e não são recomendação de compra, venda ou investimento.',
  ]),
  (titulo: '6. Planos e pagamentos', paragrafos: [
    'Alguns recursos dependem de um plano pago. Os preços e o que cada plano inclui aparecem na tela de Assinatura.',
    'Os pagamentos são processados pelo PagBank. O Café Conecta não recebe nem guarda os dados completos do seu cartão.',
    'Cada pagamento libera o plano por um mês, sem renovação automática. Ao fim do período, a conta volta ao plano Gratuito.',
    'Você pode desistir da contratação em até 7 dias após o pagamento, conforme o Código de Defesa do Consumidor, pedindo pelo contato abaixo.',
  ]),
  (titulo: '7. Disponibilidade e limitações', paragrafos: [
    'Trabalhamos para manter o app no ar e funcionando, mas ele pode ter interrupções, falhas ou mudanças. Na medida permitida pela lei, o Café Conecta não responde por prejuízos de negociações feitas entre usuários.',
  ]),
  (titulo: '8. Mudanças nestes Termos', paragrafos: [
    'Podemos atualizar estes Termos. Mudanças importantes serão avisadas no app ou por e-mail. Continuar usando o app depois do aviso significa concordar com a nova versão.',
  ]),
  (titulo: '9. Lei aplicável e contato', paragrafos: [
    'Estes Termos seguem as leis do Brasil. Dúvidas, reclamações e pedidos podem ser enviados para $contatoPrivacidade.',
  ]),
];

const List<SecaoLegal> politicaDePrivacidade = [
  (titulo: '1. Quem cuida dos seus dados', paragrafos: [
    'O controlador dos dados pessoais tratados no Café Conecta é $responsavelApp, responsável pelo app. Contato para assuntos de privacidade e para exercer seus direitos: $contatoPrivacidade.',
  ]),
  (titulo: '2. Quais dados coletamos', paragrafos: [
    'Dados de cadastro: nome, e-mail, telefone, cidade, estado, tipo de conta (produtor, comprador ou corretor) e senha (guardada apenas de forma criptografada).',
    'Dados de uso do app: anúncios e fotos dos lotes, propostas, mensagens, avaliações, favoritos e alertas de preço.',
    'Dados de pagamento: plano contratado, valor, data e situação do pagamento. Os dados do cartão ficam com o PagBank.',
    'Dados técnicos e de segurança: data dos acessos, visualizações de anúncios e tentativas de login. O endereço IP é guardado apenas em forma embaralhada (hash), usada para contar visitas e bloquear tentativas abusivas.',
  ]),
  (titulo: '3. Para que usamos', paragrafos: [
    'Para criar e manter sua conta e permitir anunciar, negociar e conversar com outros usuários (execução do contrato).',
    'Para mostrar seus anúncios no catálogo. Seu nome, cidade e os dados do lote ficam visíveis para quem acessa o app; o telefone aparece só para usuários logados.',
    'Quando uma proposta é aceita, nome, cidade, telefone e e-mail das duas partes aparecem no contrato do negócio, disponível apenas para elas.',
    'Para enviar avisos por e-mail sobre propostas, mensagens e alertas de preço. Você pode desligar esses avisos em Configurações.',
    'Para processar pagamentos de planos, prevenir fraudes, proteger as contas e cumprir obrigações legais.',
    'Para calcular estatísticas e o Índice Café Conecta, sempre de forma agregada, sem identificar quem negociou.',
  ]),
  (titulo: '4. Com quem compartilhamos', paragrafos: [
    'Usamos prestadores de serviço que tratam dados em nosso nome: Supabase (banco de dados e armazenamento de fotos), Vercel (hospedagem), PagBank (pagamentos), Google (envio dos e-mails) e Anthropic (análise da foto na classificação por IA, apenas quando você usa esse recurso).',
    'Os quadros de cotação são carregados do TradingView, que pode coletar dados técnicos de navegação conforme a política dele.',
    'Alguns desses serviços ficam fora do Brasil; nesses casos a transferência segue as regras da LGPD.',
    'Não vendemos seus dados. Podemos compartilhá-los com autoridades quando a lei exigir.',
  ]),
  (titulo: '5. Por quanto tempo guardamos', paragrafos: [
    'Mantemos os dados enquanto sua conta existir. Ao excluir a conta, apagamos seus anúncios, propostas, mensagens e fotos. Registros de pagamento e de acesso podem ser guardados pelo prazo exigido por lei.',
  ]),
  (titulo: '6. Seus direitos', paragrafos: [
    'Pela Lei Geral de Proteção de Dados (Lei 13.709/2018), você pode pedir: confirmação de que tratamos seus dados, acesso, correção, anonimização ou eliminação de dados desnecessários, portabilidade, informação sobre compartilhamento, e revogar consentimentos.',
    'Parte disso você faz no próprio app (editar dados, desligar avisos, excluir a conta). Para o restante, escreva para $contatoPrivacidade. Você também pode reclamar à Autoridade Nacional de Proteção de Dados (ANPD).',
  ]),
  (titulo: '7. Segurança', paragrafos: [
    'Usamos conexão criptografada, senhas protegidas por hash, limite de tentativas de login e acesso restrito ao banco de dados. Nenhum sistema é totalmente imune a falhas; se houver um incidente relevante, avisaremos os afetados e a ANPD conforme a lei.',
  ]),
  (titulo: '8. Cookies e armazenamento no aparelho', paragrafos: [
    'O app guarda no seu navegador apenas o necessário para manter você conectado. Não usamos cookies de publicidade.',
  ]),
  (titulo: '9. Menores de idade', paragrafos: [
    'O Café Conecta é destinado a maiores de 18 anos.',
  ]),
  (titulo: '10. Mudanças nesta Política', paragrafos: [
    'Podemos atualizar esta Política. A data da versão atual aparece no topo. Mudanças importantes serão avisadas no app ou por e-mail.',
  ]),
];
