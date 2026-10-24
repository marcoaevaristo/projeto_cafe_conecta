// lib/screens/configuracoes_screen.dart
// Dados da conta, senha, assinatura e exclusão de conta.
import 'boas_vindas_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../utils/erros.dart';
import '../utils/theme.dart';
import 'login_screen.dart';
import 'planos_screen.dart';

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppState>().usuario;
    if (u == null) return const Scaffold(body: SizedBox());
    final estado = context.watch<AppState>();

    String validade() {
      final v = DateTime.tryParse(u.planoValidoAte ?? '');
      return v == null ? '' : ' · válido até ${DateFormat('dd/MM/yyyy').format(v.toLocal())}';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _titulo('Conta'),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.person_outline, color: CafeColors.caramel),
              title: const Text('Dados pessoais'),
              subtitle: Text('${u.nome} · ${u.telefone ?? 'sem telefone'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _EditarPerfilScreen())),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.email_outlined, color: CafeColors.caramel),
              title: const Text('E-mail'),
              subtitle: Text(u.email),
            ),
          ]),
        ),
        _titulo('Avisos'),
        const Card(child: _AvisosEmail()),
        _titulo('Segurança'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.lock_outline, color: CafeColors.caramel),
            title: const Text('Trocar senha'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const _TrocarSenhaScreen())),
          ),
        ),
        _titulo('Assinatura'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.card_membership_outlined, color: CafeColors.caramel),
            title: Text('Plano ${estado.plano.nome}'),
            subtitle: Text(estado.planoTier == 0
                ? 'Sem cobrança'
                : 'Pagamento mensal, sem renovação automática${validade()}'),
            trailing: TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PlanosScreen())),
              child: Text(estado.planoTier == 0 ? 'Assinar' : 'Renovar ou mudar'),
            ),
          ),
        ),
        _titulo('Zona de perigo'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: CafeColors.redAlert),
            title: const Text('Excluir minha conta',
                style: TextStyle(color: CafeColors.redAlert)),
            subtitle: const Text('Apaga seus anúncios, propostas, mensagens e fotos'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const _ExcluirContaScreen())),
          ),
        ),
      ]),
    );
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(t.toUpperCase(),
            style: GoogleFonts.dmSans(
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: CafeColors.lightRoast)),
      );
}

// ── Avisos por e-mail ─────────────────────────────────────────────────
class _AvisosEmail extends StatefulWidget {
  const _AvisosEmail();
  @override
  State<_AvisosEmail> createState() => _AvisosEmailState();
}

class _AvisosEmailState extends State<_AvisosEmail> {
  bool? _ligado;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    ApiService.getAvisosEmail().then((v) {
      if (mounted) setState(() => _ligado = v);
    }).catchError((_) {
      if (mounted) setState(() => _ligado = true);
    });
  }

  Future<void> _alterar(bool v) async {
    setState(() { _ligado = v; _salvando = true; });
    try {
      await ApiService.setAvisosEmail(v);
    } catch (e) {
      if (mounted) {
        setState(() => _ligado = !v);
        mostrarErro(context, e);
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => SwitchListTile(
        secondary: const Icon(Icons.mark_email_unread_outlined, color: CafeColors.caramel),
        title: const Text('Avisos por e-mail'),
        subtitle: const Text('Nova proposta, resposta, mensagem e alerta de preço'),
        value: _ligado ?? true,
        activeColor: CafeColors.caramel,
        onChanged: _ligado == null || _salvando ? null : _alterar,
      );
}

// ── Editar dados pessoais ─────────────────────────────────────────────
class _EditarPerfilScreen extends StatefulWidget {
  const _EditarPerfilScreen();
  @override
  State<_EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<_EditarPerfilScreen> {
  late final TextEditingController _nome, _telefone, _cidade, _estado;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().usuario!;
    _nome = TextEditingController(text: u.nome);
    _telefone = TextEditingController(text: u.telefone ?? '');
    _cidade = TextEditingController(text: u.cidade ?? '');
    _estado = TextEditingController(text: u.estado ?? '');
  }

  @override
  void dispose() {
    for (final c in [_nome, _telefone, _cidade, _estado]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nome.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Informe seu nome')));
      return;
    }
    setState(() => _salvando = true);
    try {
      String? ouNulo(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
      await ApiService.atualizarPerfil({
        'nome': _nome.text.trim(),
        'telefone': ouNulo(_telefone),
        'cidade': ouNulo(_cidade),
        'estado': ouNulo(_estado)?.toUpperCase(),
      });
      if (!mounted) return;
      await context.read<AppState>().recarregarUsuario();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Dados atualizados')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        mostrarErro(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dados pessoais')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _campo(_nome, 'Nome completo', Icons.person_outline),
        _campo(_telefone, 'Telefone / WhatsApp', Icons.phone_outlined,
            tipo: TextInputType.phone,
            ajuda: 'Aparece nos seus anúncios para quem está logado'),
        _campo(_cidade, 'Cidade', Icons.location_city_outlined),
        _campo(_estado, 'Estado (UF)', Icons.map_outlined, max: 2),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Salvar'),
        ),
      ]),
    );
  }
}

// ── Trocar senha ──────────────────────────────────────────────────────
class _TrocarSenhaScreen extends StatefulWidget {
  const _TrocarSenhaScreen();
  @override
  State<_TrocarSenhaScreen> createState() => _TrocarSenhaScreenState();
}

class _TrocarSenhaScreenState extends State<_TrocarSenhaScreen> {
  final _atual = TextEditingController();
  final _nova = TextEditingController();
  final _confirma = TextEditingController();
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _atual.dispose();
    _nova.dispose();
    _confirma.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nova.text.length < 6) {
      setState(() => _erro = 'A nova senha deve ter pelo menos 6 caracteres');
      return;
    }
    if (_nova.text != _confirma.text) {
      setState(() => _erro = 'A confirmação não confere com a nova senha');
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await ApiService.trocarSenha(_atual.text, _nova.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Senha alterada')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _salvando = false;
          _erro = mensagemDeErro(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trocar senha')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _campo(_atual, 'Senha atual', Icons.lock_outline, senha: true),
        _campo(_nova, 'Nova senha (mín. 6 caracteres)', Icons.lock_reset, senha: true),
        _campo(_confirma, 'Confirme a nova senha', Icons.lock_reset, senha: true),
        if (_erro != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_erro!, style: const TextStyle(color: CafeColors.redAlert)),
          ),
        ElevatedButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Trocar senha'),
        ),
      ]),
    );
  }
}

// ── Excluir conta ─────────────────────────────────────────────────────
class _ExcluirContaScreen extends StatefulWidget {
  const _ExcluirContaScreen();
  @override
  State<_ExcluirContaScreen> createState() => _ExcluirContaScreenState();
}

class _ExcluirContaScreenState extends State<_ExcluirContaScreen> {
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();
  bool _excluindo = false;
  String? _erro;

  @override
  void dispose() {
    _senha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  bool get _podeExcluir =>
      _senha.text.isNotEmpty && _confirmacao.text.trim().toUpperCase() == 'EXCLUIR';

  Future<void> _excluir() async {
    setState(() {
      _excluindo = true;
      _erro = null;
    });
    try {
      await ApiService.excluirConta(_senha.text);
      if (!mounted) return;
      // pega antes de sair da tela: depois da navegação este contexto deixa de existir
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      await context.read<AppState>().logout();
      navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BoasVindasScreen()), (_) => false);
      messenger.showSnackBar(const SnackBar(content: Text('Sua conta foi excluída')));
    } catch (e) {
      if (mounted) {
        setState(() {
          _excluindo = false;
          _erro = mensagemDeErro(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Excluir conta')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CafeColors.redAlert.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CafeColors.redAlert.withValues(alpha: 0.3)),
          ),
          child: const Text(
            'Isto apaga de forma permanente sua conta, seus anúncios e fotos, propostas, '
            'mensagens, alertas, avaliações e laudos. Não dá para desfazer. '
            'Pagamentos já feitos não são reembolsados.',
            style: TextStyle(height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        _campo(_senha, 'Sua senha', Icons.lock_outline,
            senha: true, aoMudar: (_) => setState(() {})),
        _campo(_confirmacao, 'Digite EXCLUIR para confirmar', Icons.warning_amber_outlined,
            aoMudar: (_) => setState(() {})),
        if (_erro != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_erro!, style: const TextStyle(color: CafeColors.redAlert)),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: CafeColors.redAlert, foregroundColor: Colors.white),
          onPressed: _podeExcluir && !_excluindo ? _excluir : null,
          child: _excluindo
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Excluir minha conta para sempre'),
        ),
      ]),
    );
  }
}

Widget _campo(TextEditingController c, String label, IconData icone,
        {bool senha = false,
        TextInputType? tipo,
        String? ajuda,
        int? max,
        void Function(String)? aoMudar}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        obscureText: senha,
        keyboardType: tipo,
        maxLength: max,
        onChanged: aoMudar,
        decoration: InputDecoration(
          labelText: label,
          helperText: ajuda,
          prefixIcon: Icon(icone),
          counterText: '',
        ),
      ),
    );
