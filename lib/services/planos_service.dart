// lib/services/planos_service.dart

enum PlanoTipo { gratuito, basico, profissional, premium }

class Plan {
  final String id;
  final String nome;
  final double preco;
  final PlanoTipo tipo;
  final List<String> features;

  const Plan({
    required this.id,
    required this.nome,
    required this.preco,
    required this.tipo,
    this.features = const [],
  });
}

class PlanosService {
  static const List<Plan> planos = [
    Plan(
      id: 'gratuito',
      nome: 'Grátis',
      preco: 0.0,
      tipo: PlanoTipo.gratuito,
      features: ['Publicar até 3 anúncios', 'Ver catálogo', 'Enviar propostas'],
    ),
    Plan(
      id: 'basico',
      nome: 'Básico',
      preco: 29.0,
      tipo: PlanoTipo.basico,
      features: [
        'Até 10 anúncios',
        'Cotações em tempo real',
        'Alertas de preço',
        'Histórico 30 dias',
      ],
    ),
    Plan(
      id: 'profissional',
      nome: 'Profissional',
      preco: 79.0,
      tipo: PlanoTipo.profissional,
      features: [
        'Anúncios ilimitados',
        'IA de classificação',
        'Laudo digital + QR Code',
        'Dashboard avançado',
        'Suporte prioritário',
      ],
    ),
    Plan(
      id: 'premium',
      nome: 'Premium',
      preco: 149.0,
      tipo: PlanoTipo.premium,
      features: [
        'Tudo do Profissional',
        'API de integração',
        'Relatórios personalizados',
        'Gerente de conta dedicado',
        'Selo verificado',
      ],
    ),
  ];

  static Plan? getById(String id) =>
      planos.firstWhere((p) => p.id == id, orElse: () => planos[0]);

  static Plan getByTipo(PlanoTipo tipo) =>
      planos.firstWhere((p) => p.tipo == tipo, orElse: () => planos[0]);

  /// Verifica se o plano tem acesso a um recurso
  static bool temAcesso(PlanoTipo planoUsuario, String recurso) {
    final tier = planoUsuario.index; // 0=grátis, 1=básico, 2=profissional, 3=premium

    switch (recurso) {
      // Gratuito (tier >= 0)
      case 'publicar_anuncio':
      case 'ver_catalogo':
      case 'enviar_proposta':
        return true;

      // Básico (tier >= 1)
      case 'cotacoes_tempo_real':
      case 'alertas_preco':
      case 'historico_precos':
        return tier >= 1;

      // Profissional (tier >= 2)
      case 'classificacao_ia':
      case 'laudo_digital':
      case 'qr_code':
      case 'dashboard_avancado':
        return tier >= 2;

      // Premium (tier >= 3)
      case 'api_integracao':
      case 'relatorios_personalizados':
      case 'gerente_conta':
      case 'selo_verificado':
        return tier >= 3;

      default:
        return false;
    }
  }

  /// Retorna o limite do recurso para o plano
  static int getLimite(PlanoTipo planoUsuario, String recurso) {
    switch (recurso) {
      case 'anuncios':
        switch (planoUsuario) {
          case PlanoTipo.gratuito:
            return 3;
          case PlanoTipo.basico:
            return 10;
          case PlanoTipo.profissional:
          case PlanoTipo.premium:
            return 9999; // ilimitado
        }
      case 'historico_dias':
        switch (planoUsuario) {
          case PlanoTipo.gratuito:
            return 0;
          case PlanoTipo.basico:
            return 30;
          case PlanoTipo.profissional:
            return 90;
          case PlanoTipo.premium:
            return 365;
        }
      default:
        return 0;
    }
  }

  /// Retorna o plano mínimo necessário para um recurso
  static PlanoTipo planoNecessario(String recurso) {
    if (temAcesso(PlanoTipo.gratuito, recurso)) return PlanoTipo.gratuito;
    if (temAcesso(PlanoTipo.basico, recurso)) return PlanoTipo.basico;
    if (temAcesso(PlanoTipo.profissional, recurso)) return PlanoTipo.profissional;
    return PlanoTipo.premium;
  }
}
