// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/theme.dart';
import 'cadastro_screen.dart';
import 'esqueci_senha_screen.dart';
import 'main_screen.dart';
import 'texto_legal_screen.dart';
import '../services/api_service.dart';
import '../utils/textos_legais.dart';
import '../widgets/google/botao_google.dart';

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
  String? _googleClientId;

  @override
  void initState() {
    super.initState();
    ApiService.getGoogleClientId().then((id) {
      if (mounted && id != null && id.isNotEmpty) setState(() => _googleClientId = id);
    });
  }

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
                        if (_googleClientId != null) ...[
                          const SizedBox(height: 14),
                          Row(children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('ou', style: GoogleFonts.dmSans(color: CafeColors.lightRoast, fontSize: 12)),
                            ),
                            const Expanded(child: Divider()),
                          ]),
                          const SizedBox(height: 10),
                          BotaoGoogle(clientId: _googleClientId!, aoEntrar: _google),
                        ],
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const EsqueciSenhaScreen())),
                          child: Center(
                            child: Text(
                              'Esqueci minha senha',
                              style: GoogleFonts.dmSans(
                                color: CafeColors.caramel,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: CafeColors.caramel,
                              ),
                            ),
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

  /// Login com Google: entra direto ou, se for conta nova, pergunta o perfil e o aceite dos termos.
  Future<void> _google(String credencial) async {
    setState(() { _loading = true; _erro = null; });
    try {
      var (status, data) = await ApiService.entrarComGoogle({'credential': credencial});
      if (status == 428 && mounted) {
        setState(() => _loading = false);
        final tipo = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _CompletarCadastroGoogle(nome: '${data['nome'] ?? ''}', email: '${data['email'] ?? ''}'),
        );
        if (tipo == null || !mounted) return;
        setState(() => _loading = true);
        (status, data) = await ApiService.entrarComGoogle({
          'credential': credencial, 'tipo': tipo, 'aceite_termos': true, 'versao_termos': versaoTermos,
        });
      }
      if ((status == 200 || status == 201) && data['token'] != null) {
        if (!mounted) return;
        await context.read<AppState>().entrarComToken(data['token'] as String);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen()), (_) => false);
        return;
      }
      if (mounted) setState(() => _erro = '${data['error'] ?? 'Não foi possível entrar com Google.'}');
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível entrar com Google. Tente de novo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      // limpa a pilha (boas-vindas, catálogo público) e abre o app
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const MainScreen()), (_) => false);
    } else {
      setState(() => _erro =
          context.read<AppState>().ultimoErroLogin ?? 'E-mail ou senha incorretos.');
    }
  }
}

/// Conta nova pelo Google: escolher o perfil e aceitar os termos (LGPD).
class _CompletarCadastroGoogle extends StatefulWidget {
  final String nome, email;
  const _CompletarCadastroGoogle({required this.nome, required this.email});
  @override
  State<_CompletarCadastroGoogle> createState() => _CompletarCadastroGoogleState();
}

class _CompletarCadastroGoogleState extends State<_CompletarCadastroGoogle> {
  String? _tipo;
  bool _aceite = false;

  @override
  Widget build(BuildContext context) {
    final link = GoogleFonts.dmSans(color: CafeColors.caramel, decoration: TextDecoration.underline, fontSize: 13);
    void abrir(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    return AlertDialog(
      title: const Text('Complete seu cadastro'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${widget.nome}\n${widget.email}', style: GoogleFonts.dmSans(fontSize: 13)),
          const SizedBox(height: 14),
          const Text('Você é:'),
          for (final t in const [('produtor', 'Produtor'), ('comprador', 'Comprador'), ('corretor', 'Corretor')])
            RadioListTile<String>(
              value: t.$1,
              groupValue: _tipo,
              onChanged: (v) => setState(() => _tipo = v),
              title: Text(t.$2),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          CheckboxListTile(
            value: _aceite,
            onChanged: (v) => setState(() => _aceite = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Wrap(children: [
              const Text('Li e aceito os '),
              GestureDetector(onTap: () => abrir(const TextoLegalScreen.termos()), child: Text('Termos de uso', style: link)),
              const Text(' e a '),
              GestureDetector(onTap: () => abrir(const TextoLegalScreen.privacidade()), child: Text('Política de privacidade', style: link)),
            ]),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _tipo != null && _aceite ? () => Navigator.pop(context, _tipo) : null,
          child: const Text('Criar conta'),
        ),
      ],
    );
  }
}
