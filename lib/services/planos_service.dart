// lib/services/planos_service.dart

class Plan {
  final String id;
  final String nome;
  final double preco;
  final int tier; // maior = mais privilégios
  final List<String> features;

  const Plan({required this.id, required this.nome, required this.preco, required this.tier, this.features = const []});
}

class PlanosService {
  static const List<Plan> planos = [
    Plan(id: 'free', nome: 'Grátis', preco: 0.0, tier: 0, features: ['Publicar anúncios', 'Ver anúncios']),
    Plan(id: 'pro', nome: 'Pro', preco: 9.99, tier: 1, features: ['IA de classificação', 'Relatórios digitais', 'Suporte prioritário']),
    Plan(id: 'business', nome: 'Business', preco: 29.99, tier: 2, features: ['Tudo do Pro', 'Integrações', 'Acesso avançado']),
  ];

  static Plan? getById(String id) => planos.firstWhere((p) => p.id == id, orElse: () => planos[0]);
}
