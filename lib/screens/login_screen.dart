// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/theme.dart';
import 'cadastro_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _loading = false;
  bool _verSenha = false;
  String? _erro;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradiente
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CafeColors.espresso,
                  CafeColors.darkRoast,
                  CafeColors.mediumRoast
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Padrão de pontos
          Opacity(
            opacity: 0.06,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
                mainAxisSpacing: 30,
                crossAxisSpacing: 30,
              ),
              itemBuilder: (_, __) => const CircleAvatar(
                radius: 2,
                backgroundColor: CafeColors.caramel,
              ),
            ),
          ),
          // Conteúdo
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  // Logo
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: CafeColors.caramel.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: CafeColors.gold.withValues(alpha: 0.5),
                          width: 2),
                    ),
                    child: const Center(
                      child: Text('☕', style: TextStyle(fontSize: 42)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('CAFÉ CONECTA',
                      style: GoogleFonts.playfairDisplay(
                        color: CafeColors.gold,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      )),
                  Text('CATÁLOGO DE CAFÉS',
                      style: GoogleFonts.dmSans(
                        color: CafeColors.caramel,
                        fontSize: 11,
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w500,
                      )),
                  const SizedBox(height: 8),
                  Text(
                    'Conectando produtores, corretores e\ncompradores com agilidade e confiança.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: CafeColors.cream.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Card do form
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Entrar',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: CafeColors.darkRoast,
                            )),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _senhaCtrl,
                          obscureText: !_verSenha,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_verSenha
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () =>
                                  setState(() => _verSenha = !_verSenha),
                            ),
                          ),
                        ),
                        if (_erro != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  CafeColors.redAlert.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: CafeColors.redAlert
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Text(_erro!,
                                style: GoogleFonts.dmSans(
                                    color: CafeColors.redAlert, fontSize: 13)),
                          ),
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Entrar'),
                        ),
                        const SizedBox(height: 12),
                        // Dica usuários de teste
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: CafeColors.cream,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('👤 Usuários de teste (senha: 123456)',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: CafeColors.mediumRoast)),
                              const SizedBox(height: 4),
                              ...[
                                ('Corretor', 'joao@cafesuldeminas.com.br'),
                                ('Comprador', 'ana@torrefacao.com.br'),
                              ].map((u) => GestureDetector(
                                    onTap: () {
                                      _emailCtrl.text = u.$2;
                                      _senhaCtrl.text = '123456';
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text('${u.$1}: ${u.$2}',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 11,
                                            color: CafeColors.caramel,
                                            decoration:
                                                TextDecoration.underline,
                                          )),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Não tem conta? ',
                          style: GoogleFonts.dmSans(
                              color: CafeColors.cream.withValues(alpha: 0.7))),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CadastroScreen(),
                            )),
                        child: Text('Criar conta',
                            style: GoogleFonts.dmSans(
                              color: CafeColors.gold,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: CafeColors.gold,
                            )),
                      ),
                    ],
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

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    final ok = await context.read<AppState>().login(
          _emailCtrl.text.trim(),
          _senhaCtrl.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainScreen()));
    } else {
      setState(() => _erro = 'E-mail ou senha incorretos.');
    }
  }
}
