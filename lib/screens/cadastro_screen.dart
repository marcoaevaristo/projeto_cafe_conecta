// lib/screens/cadastro_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/theme.dart';
import 'main_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});
  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _empresaCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  String _tipo = 'comprador';
  String? _regiao;
  bool _loading = false;
  String? _erro;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _secao('Tipo de Conta'),
            Row(
              children: [
                _TipoBtn(
                    label: '🛒 Comprador',
                    valor: 'comprador',
                    selecionado: _tipo,
                    onTap: (v) => setState(() => _tipo = v)),
                const SizedBox(width: 10),
                _TipoBtn(
                    label: '🤝 Corretor',
                    valor: 'corretor',
                    selecionado: _tipo,
                    onTap: (v) => setState(() => _tipo = v)),
              ],
            ),
            const SizedBox(height: 20),
            _secao('Seus Dados'),
            _campo(_nomeCtrl, 'Nome completo', Icons.person_outline),
            _campo(_emailCtrl, 'E-mail', Icons.email_outlined,
                tipo: TextInputType.emailAddress),
            _campo(_senhaCtrl, 'Senha', Icons.lock_outline, senha: true),
            _campo(_empresaCtrl, 'Empresa / Razão Social',
                Icons.business_outlined),
            _campo(_telCtrl, 'Telefone / WhatsApp', Icons.phone_outlined,
                tipo: TextInputType.phone),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _regiao,
              decoration: const InputDecoration(
                labelText: 'Região de atuação',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              items: regioesCafe
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _regiao = v),
            ),
            const SizedBox(height: 20),
            if (_erro != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CafeColors.redAlert.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: CafeColors.redAlert.withValues(alpha: 0.3)),
                ),
                child: Text(_erro!,
                    style: GoogleFonts.dmSans(color: CafeColors.redAlert)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _cadastrar,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Criar Conta'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secao(String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(titulo,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CafeColors.darkRoast,
              )),
        ),
      );

  Widget _campo(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType tipo = TextInputType.text,
    bool senha = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: tipo,
        obscureText: senha,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }

  Future<void> _cadastrar() async {
    final nome = _nomeCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final senha = _senhaCtrl.text;
    if (nome.isEmpty || email.isEmpty || senha.length < 6) {
      setState(
          () => _erro = 'Preencha nome, e-mail e senha (mín. 6 caracteres).');
      return;
    }
    setState(() {
      _loading = true;
      _erro = null;
    });
    final ok = await context.read<AppState>().cadastrar(
          nome: nome,
          email: email,
          senha: senha,
          tipo: _tipo,
          empresa: _empresaCtrl.text.trim().isEmpty
              ? null
              : _empresaCtrl.text.trim(),
          telefone: _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
          regiao: _regiao,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainScreen()));
    } else {
      setState(() => _erro = 'E-mail já cadastrado ou erro interno.');
    }
  }
}

class _TipoBtn extends StatelessWidget {
  final String label;
  final String valor;
  final String selecionado;
  final void Function(String) onTap;
  const _TipoBtn(
      {required this.label,
      required this.valor,
      required this.selecionado,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = selecionado == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(valor),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: sel ? CafeColors.caramel : Colors.white,
            border: Border.all(
              color: sel
                  ? CafeColors.caramel
                  : CafeColors.lightRoast.withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                color: sel ? CafeColors.espresso : CafeColors.lightRoast,
                fontSize: 14,
              )),
        ),
      ),
    );
  }
}
