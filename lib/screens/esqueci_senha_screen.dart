// lib/screens/esqueci_senha_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({super.key});
  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  // Passo 1: pedir e-mail → passo 2: inserir código + nova senha
  int _passo = 1;
  bool _loading = false;
  String? _erro;
  String? _sucesso;

  final _emailCtrl    = TextEditingController();
  final _codigoCtrl   = TextEditingController();
  final _senhaCtrl    = TextEditingController();
  final _confirmaCtrl = TextEditingController();
  bool _verSenha = false;

  String? _emailEnviado; // e-mail usado para solicitar o código

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codigoCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background igual ao login
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [CafeColors.espresso, CafeColors.darkRoast, CafeColors.mediumRoast],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Opacity(
            opacity: 0.06,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10, mainAxisSpacing: 30, crossAxisSpacing: 30),
              itemBuilder: (_, __) =>
                  const CircleAvatar(radius: 2, backgroundColor: CafeColors.caramel),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  // Logo
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: CafeColors.caramel.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: CafeColors.gold.withValues(alpha: 0.5), width: 2),
                    ),
                    child: const Center(child: Text('🔑', style: TextStyle(fontSize: 36))),
                  ),
                  const SizedBox(height: 20),
                  Text('CAFÉ CONECTA',
                      style: GoogleFonts.playfairDisplay(
                          color: CafeColors.gold, fontSize: 24,
                          fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Text('Recuperação de senha',
                      style: GoogleFonts.dmSans(
                          color: CafeColors.cream.withValues(alpha: 0.7),
                          fontSize: 14, fontWeight: FontWeight.w300)),
                  const SizedBox(height: 40),

                  // Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 30, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: _passo == 1 ? _buildPasso1() : _buildPasso2(),
                  ),

                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('← Voltar ao login',
                        style: GoogleFonts.dmSans(
                            color: CafeColors.gold,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: CafeColors.gold)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Passo 1: solicitar código ────────────────────────────────────────

  Widget _buildPasso1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Esqueci minha senha',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: CafeColors.darkRoast)),
        const SizedBox(height: 8),
        Text('Digite seu e-mail cadastrado e enviaremos um código de verificação.',
            style: GoogleFonts.dmSans(
                fontSize: 13, color: CafeColors.lightRoast)),
        const SizedBox(height: 20),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined)),
        ),
        if (_erro != null) _buildErro(_erro!),
        if (_sucesso != null) _buildSucesso(_sucesso!),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : _solicitarCodigo,
          child: _loading
              ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Enviar código'),
        ),
      ],
    );
  }

  // ── Passo 2: inserir código + nova senha ─────────────────────────────

  Widget _buildPasso2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Redefinir senha',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: CafeColors.darkRoast)),
        const SizedBox(height: 8),
        Text('Insira o código enviado para $_emailEnviado e escolha uma nova senha.',
            style: GoogleFonts.dmSans(
                fontSize: 13, color: CafeColors.lightRoast)),
        const SizedBox(height: 20),
        TextField(
          controller: _codigoCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Código de 6 dígitos',
            prefixIcon: Icon(Icons.pin_outlined),
            counterText: '',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _senhaCtrl,
          obscureText: !_verSenha,
          decoration: InputDecoration(
            labelText: 'Nova senha',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_verSenha
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () => setState(() => _verSenha = !_verSenha),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _confirmaCtrl,
          obscureText: !_verSenha,
          decoration: const InputDecoration(
            labelText: 'Confirmar nova senha',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        if (_erro != null) _buildErro(_erro!),
        if (_sucesso != null) _buildSucesso(_sucesso!),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : _redefinirSenha,
          child: _loading
              ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Redefinir senha'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _loading ? null : () => setState(() {
            _passo = 1; _erro = null; _sucesso = null;
            _codigoCtrl.clear(); _senhaCtrl.clear(); _confirmaCtrl.clear();
          }),
          child: Text('Não recebi o código — tentar novamente',
              style: GoogleFonts.dmSans(color: CafeColors.caramel, fontSize: 13)),
        ),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  Widget _buildErro(String msg) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CafeColors.redAlert.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CafeColors.redAlert.withValues(alpha: 0.3)),
      ),
      child: Text(msg, style: GoogleFonts.dmSans(color: CafeColors.redAlert, fontSize: 13)),
    ),
  );

  Widget _buildSucesso(String msg) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CafeColors.greenOk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CafeColors.greenOk.withValues(alpha: 0.3)),
      ),
      child: Text(msg, style: GoogleFonts.dmSans(color: CafeColors.greenOk, fontSize: 13)),
    ),
  );

  // ── Ações ────────────────────────────────────────────────────────────

  Future<void> _solicitarCodigo() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() { _erro = 'Digite seu e-mail.'; _sucesso = null; });
      return;
    }
    setState(() { _loading = true; _erro = null; _sucesso = null; });
    try {
      await ApiService.esqueciSenha(email);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _emailEnviado = email;
        _passo = 2;
        _sucesso = 'Código enviado! Verifique seu e-mail.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _erro = e.message; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _erro = 'Erro ao solicitar código. Tente novamente.'; });
    }
  }

  Future<void> _redefinirSenha() async {
    final codigo = _codigoCtrl.text.trim();
    final senha  = _senhaCtrl.text;
    final confirma = _confirmaCtrl.text;

    if (codigo.length != 6) {
      setState(() { _erro = 'O código deve ter 6 dígitos.'; _sucesso = null; });
      return;
    }
    if (senha.length < 6) {
      setState(() { _erro = 'A senha deve ter pelo menos 6 caracteres.'; _sucesso = null; });
      return;
    }
    if (senha != confirma) {
      setState(() { _erro = 'As senhas não conferem.'; _sucesso = null; });
      return;
    }

    setState(() { _loading = true; _erro = null; _sucesso = null; });
    try {
      await ApiService.resetarSenha(_emailEnviado!, codigo, senha);
      if (!mounted) return;
      setState(() { _loading = false; _sucesso = 'Senha redefinida com sucesso!'; });
      // Volta ao login após 2 segundos
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _erro = e.message; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _erro = 'Erro ao redefinir senha. Tente novamente.'; });
    }
  }
}
