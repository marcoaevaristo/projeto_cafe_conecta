// ============================================================
// Café Conecta — Tela de Checkout
// lib/screens/checkout_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../utils/erros.dart';

class CheckoutScreen extends StatefulWidget {
  final String plano;
  final double valor;

  const CheckoutScreen({super.key, required this.plano, required this.valor});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Cartão
  final _nomeCtrl    = TextEditingController();
  final _numeroCtrl  = TextEditingController();
  final _validadeCtrl = TextEditingController();
  final _cvvCtrl     = TextEditingController();
  final _cpfCtrl     = TextEditingController();

  bool _carregando  = false;
  String? _erro;

  // Resultado PIX
  String? _pixCode;
  String? _pixQrUrl;
  bool _pixPago = false;
  String? _orderId;
  bool _verificando = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nomeCtrl.dispose();
    _numeroCtrl.dispose();
    _validadeCtrl.dispose();
    _cvvCtrl.dispose();
    _cpfCtrl.dispose();
    super.dispose();
  }

  String get _nomePlano {
    const nomes = {
      'basico': 'Básico',
      'profissional': 'Profissional',
      'premium': 'Premium',
    };
    return nomes[widget.plano] ?? widget.plano;
  }

  // ── Pagamento PIX ────────────────────────────────────────
  Future<void> _pagarPix() async {
    setState(() { _carregando = true; _erro = null; });

    try {
      final data = await ApiService.criarAssinatura({
        'plano':  widget.plano,
        'metodo': 'pix',
        'cpf':    _cpfCtrl.text.replaceAll(RegExp(r'\D'), ''),
      });

      setState(() {
        _orderId    = data['order_id']?.toString();
        _pixCode    = data['pix_code'];
        _pixQrUrl   = data['pix_qrcode'];
        _carregando = false;
      });
    } catch (e) {
      setState(() { _erro = mensagemDeErro(e); _carregando = false; });
    }
  }

  // Pergunta ao backend, que consulta o PagBank, se o PIX já caiu
  Future<void> _verificarPix() async {
    if (_orderId == null) return;
    setState(() { _verificando = true; _erro = null; });
    try {
      final r = await ApiService.verificarPagamento(_orderId!);
      if (!mounted) return;
      if (r['situacao'] == 'pago') {
        await context.read<AppState>().recarregarUsuario();
        setState(() { _pixPago = true; _verificando = false; });
        if (mounted) _mostrarSucesso();
      } else {
        setState(() {
          _verificando = false;
          _erro = r['situacao'] == 'recusado'
              ? 'O pagamento foi recusado. Gere um novo código PIX.'
              : 'Ainda não recebemos o pagamento. Se já pagou, aguarde alguns segundos e tente de novo.';
        });
      }
    } catch (e) {
      if (mounted) setState(() { _verificando = false; _erro = mensagemDeErro(e); });
    }
  }

  // ── Pagamento Cartão ─────────────────────────────────────
  Future<void> _pagarCartao() async {
    if (_nomeCtrl.text.isEmpty    ||
        _numeroCtrl.text.isEmpty  ||
        _validadeCtrl.text.isEmpty ||
        _cvvCtrl.text.isEmpty     ||
        _cpfCtrl.text.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos do cartão');
      return;
    }

    setState(() { _carregando = true; _erro = null; });

    try {
      // ATENÇÃO: em produção, criptografe o cartão no navegador com o SDK do PagBank
      // e envie só o token. Aqui segue o valor de exemplo do sandbox.
      final data = await ApiService.criarAssinatura({
        'nome':   _nomeCtrl.text,
        'plano':  widget.plano,
        'metodo': 'cartao',
        'cpf':    _cpfCtrl.text.replaceAll(RegExp(r'\D'), ''),
        'cartao': {
          'encrypted':    'ENCRYPTED_CARD_TOKEN', // substituir pelo SDK
          'nome_titular': _nomeCtrl.text,
        },
      });

      if (data['plano_liberado'] == true) {
        if (mounted) await context.read<AppState>().recarregarUsuario();
        if (mounted) _mostrarSucesso();
      } else {
        setState(() {
          _erro = 'Pagamento não aprovado. Status: ${data['charge_status']}';
          _carregando = false;
        });
      }
    } catch (e) {
      setState(() { _erro = mensagemDeErro(e); _carregando = false; });
    }
  }

  void _mostrarSucesso() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF3D5A2A), size: 64),
            const SizedBox(height: 16),
            Text('Plano $_nomePlano ativado!',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Seu acesso já está liberado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Ir para o app'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        title: Text('Assinar Plano $_nomePlano'),
        backgroundColor: const Color(0xFF3D5A2A),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFFE8C84A),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.pix), text: 'PIX'),
            Tab(icon: Icon(Icons.credit_card), text: 'Cartão'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Resumo do valor
          Container(
            width: double.infinity,
            color: const Color(0xFF3D5A2A).withOpacity(0.08),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Plano $_nomePlano',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  'R\$ ${widget.valor.toStringAsFixed(2).replaceAll('.', ',')}/mês',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D5A2A),
                      fontSize: 16),
                ),
              ],
            ),
          ),

          if (_erro != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(_erro!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _PixTab(
                  cpfCtrl:    _cpfCtrl,
                  carregando: _carregando,
                  pixCode:    _pixCode,
                  pixQrUrl:   _pixQrUrl,
                  pixPago:    _pixPago,
                  verificando: _verificando,
                  onVerificar: _verificarPix,
                  onPagar:    _pagarPix,
                  onCopiado:  () {
                    if (_pixCode != null) {
                      Clipboard.setData(ClipboardData(text: _pixCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código PIX copiado!')),
                      );
                    }
                  },
                ),
                _CartaoTab(
                  nomeCtrl:     _nomeCtrl,
                  numeroCtrl:   _numeroCtrl,
                  validadeCtrl: _validadeCtrl,
                  cvvCtrl:      _cvvCtrl,
                  cpfCtrl:      _cpfCtrl,
                  carregando:   _carregando,
                  onPagar:      _pagarCartao,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Aba PIX ───────────────────────────────────────────────
class _PixTab extends StatelessWidget {
  final TextEditingController cpfCtrl;
  final bool carregando;
  final String? pixCode;
  final String? pixQrUrl;
  final bool pixPago;
  final bool verificando;
  final VoidCallback onVerificar;
  final VoidCallback onPagar;
  final VoidCallback onCopiado;

  const _PixTab({
    required this.cpfCtrl,
    required this.carregando,
    required this.pixCode,
    required this.pixQrUrl,
    required this.pixPago,
    required this.verificando,
    required this.onVerificar,
    required this.onPagar,
    required this.onCopiado,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (pixCode == null) ...[
            const Text(
              'Gere o código PIX e pague pelo app do seu banco. '
              'O acesso é liberado em segundos após a confirmação.',
              style: TextStyle(color: Color(0xFF6B5E4A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: cpfCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: _inputDeco('CPF (somente números)', Icons.person),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: carregando ? null : onPagar,
                icon: carregando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.pix),
                label: Text(carregando ? 'Gerando PIX...' : 'Gerar código PIX'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D5A2A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ] else ...[
            const Icon(Icons.pix, color: Color(0xFF3D5A2A), size: 48),
            const SizedBox(height: 8),
            const Text('Pague com PIX',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            const Text('Válido por 30 minutos',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            if (pixQrUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(pixQrUrl!, width: 200, height: 200,
                    errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                pixCode!,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCopiado,
                icon: const Icon(Icons.copy),
                label: const Text('Copiar código PIX'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3D5A2A),
                  side: const BorderSide(color: Color(0xFF3D5A2A)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: verificando || pixPago ? null : onVerificar,
                icon: verificando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: Text(verificando ? 'Verificando…' : 'Já paguei'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D5A2A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'O acesso também é liberado sozinho quando o PagBank confirmar o pagamento.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Aba Cartão ────────────────────────────────────────────
class _CartaoTab extends StatelessWidget {
  final TextEditingController nomeCtrl;
  final TextEditingController numeroCtrl;
  final TextEditingController validadeCtrl;
  final TextEditingController cvvCtrl;
  final TextEditingController cpfCtrl;
  final bool carregando;
  final VoidCallback onPagar;

  const _CartaoTab({
    required this.nomeCtrl,
    required this.numeroCtrl,
    required this.validadeCtrl,
    required this.cvvCtrl,
    required this.cpfCtrl,
    required this.carregando,
    required this.onPagar,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: nomeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: _inputDeco('Nome no cartão', Icons.person),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: numeroCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            decoration: _inputDeco('Número do cartão', Icons.credit_card),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: validadeCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: _inputDeco('Validade (MMAA)', Icons.date_range),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: cvvCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: _inputDeco('CVV', Icons.lock),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: cpfCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            decoration: _inputDeco('CPF do titular', Icons.badge),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Em produção, os dados do cartão são criptografados '
                    'pelo SDK PagBank antes de chegar ao servidor.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6B5000)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: carregando ? null : onPagar,
              icon: carregando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lock),
              label: Text(carregando ? 'Processando...' : 'Pagar com cartão'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D5A2A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF3D5A2A)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF3D5A2A), width: 2),
      ),
    );
