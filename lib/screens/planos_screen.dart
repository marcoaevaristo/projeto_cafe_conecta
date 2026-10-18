// ============================================================
// Café Conecta — Tela de Planos
// lib/screens/planos_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'checkout_screen.dart';

class PlanosScreen extends StatelessWidget {
  const PlanosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        title: const Text('Escolha seu Plano'),
        backgroundColor: const Color(0xFF3D5A2A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Comece grátis e faça upgrade quando quiser',
              style: TextStyle(color: Color(0xFF6B5E4A), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _PlanoCard(
              nome: 'Gratuito',
              preco: 'R\$ 0',
              periodo: '/mês',
              cor: const Color(0xFF8D9E7A),
              destaque: false,
              recursos: const [
                '2 lotes ativos',
                '3 propostas por mês',
                '1 alerta de preço',
                'Chat com corretores',
              ],
              limitacoes: const [
                'Sem fotos nos anúncios',
                'Sem dashboard analítico',
              ],
              onAssinar: null, // plano atual ou sem ação
            ),
            const SizedBox(height: 12),
            _PlanoCard(
              nome: 'Básico',
              preco: 'R\$ 29',
              periodo: '/mês',
              cor: const Color(0xFF5A8A3A),
              destaque: false,
              recursos: const [
                '5 lotes ativos',
                '3 fotos por lote',
                '10 propostas por mês',
                'Histórico 3 meses',
                'Dashboard básico',
                'Suporte WhatsApp',
              ],
              limitacoes: const [
                'Sem IA de classificação',
                'Sem laudo digital',
              ],
              onAssinar: () => _irParaCheckout(context, 'basico', 29.0),
            ),
            const SizedBox(height: 12),
            _PlanoCard(
              nome: 'Profissional',
              preco: 'R\$ 79',
              periodo: '/mês',
              cor: const Color(0xFF3D5A2A),
              destaque: true,
              badge: 'MAIS POPULAR',
              recursos: const [
                'Lotes ilimitados',
                '10 fotos por lote',
                'Propostas ilimitadas',
                'IA: 10 análises/mês',
                'Laudo digital PDF',
                'QR Code rastreável',
                'Mapa de disponibilidade',
                'Dashboard completo',
                'Suporte prioritário',
              ],
              limitacoes: const [],
              onAssinar: () => _irParaCheckout(context, 'profissional', 79.0),
            ),
            const SizedBox(height: 12),
            _PlanoCard(
              nome: 'Premium',
              preco: 'R\$ 149',
              periodo: '/mês',
              cor: const Color(0xFF2A3D1A),
              destaque: false,
              recursos: const [
                'Tudo do Profissional',
                'IA ilimitada',
                'Fotos ilimitadas',
                'Histórico 12 meses',
                'Destaque na busca',
                'Acesso à API',
                'Rede de exportadores',
                'Suporte 24h dedicado',
              ],
              limitacoes: const [],
              onAssinar: () => _irParaCheckout(context, 'premium', 149.0),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _irParaCheckout(BuildContext context, String plano, double valor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(plano: plano, valor: valor),
      ),
    );
  }
}

// ── Card de plano ─────────────────────────────────────────
class _PlanoCard extends StatelessWidget {
  final String nome;
  final String preco;
  final String periodo;
  final Color cor;
  final bool destaque;
  final String? badge;
  final List<String> recursos;
  final List<String> limitacoes;
  final VoidCallback? onAssinar;

  const _PlanoCard({
    required this.nome,
    required this.preco,
    required this.periodo,
    required this.cor,
    required this.destaque,
    this.badge,
    required this.recursos,
    required this.limitacoes,
    required this.onAssinar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: destaque
            ? Border.all(color: cor, width: 2.5)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: cor.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cabeçalho
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: cor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(preco,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900)),
                        Text(periodo,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8C84A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badge!,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2A00))),
                  ),
              ],
            ),
          ),

          // Recursos
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...recursos.map((r) => _Item(texto: r, check: true)),
                if (limitacoes.isNotEmpty) ...[
                  const Divider(height: 16),
                  ...limitacoes.map((l) => _Item(texto: l, check: false)),
                ],
                const SizedBox(height: 12),
                if (onAssinar != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAssinar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Assinar $nome',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Plano atual',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String texto;
  final bool check;
  const _Item({required this.texto, required this.check});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            check ? Icons.check_circle : Icons.cancel_outlined,
            size: 16,
            color: check ? const Color(0xFF3D5A2A) : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto,
                style: TextStyle(
                    fontSize: 13,
                    color:
                        check ? const Color(0xFF3D2A10) : Colors.grey.shade500)),
          ),
        ],
      ),
    );
  }
}
