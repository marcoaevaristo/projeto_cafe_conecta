// lib/screens/liberar_plano_screen.dart — admin libera plano sem pagamento até uma data
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../utils/erros.dart';
import '../utils/theme.dart';

const _planos = {
  'basico': 'Básico',
  'profissional': 'Profissional',
  'premium': 'Premium',
};
const _nomePlano = {'gratuito': 'Gratuito', ..._planos};
final _dataBr = DateFormat('dd/MM/yyyy');

String _validade(String? iso) {
  final d = DateTime.tryParse(iso ?? '');
  return d == null ? '' : 'até ${_dataBr.format(d.toLocal())}';
}

class LiberarPlanoScreen extends StatefulWidget {
  const LiberarPlanoScreen({super.key});
  @override
  State<LiberarPlanoScreen> createState() => _LiberarPlanoScreenState();
}

class _LiberarPlanoScreenState extends State<LiberarPlanoScreen> {
  final _busca = TextEditingController();
  Timer? _espera;
  List<Map<String, dynamic>> _usuarios = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  @override
  void dispose() {
    _espera?.cancel();
    _busca.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() => _carregando = true);
    try {
      final r = await ApiService.buscarUsuariosAdmin(_busca.text.trim());
      if (mounted) setState(() { _usuarios = r; _carregando = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _carregando = false);
        mostrarErro(context, e);
      }
    }
  }

  // espera a pessoa parar de digitar antes de buscar
  void _aoDigitar(String _) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 400), _buscar);
  }

  Future<void> _abrir(Map<String, dynamic> u) async {
    final alterou = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => _DefinirPlanoScreen(usuario: u)));
    if (alterou == true) _buscar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liberar plano (cortesia)')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _busca,
            onChanged: _aoDigitar,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar por nome ou e-mail',
            ),
          ),
        ),
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : _usuarios.isEmpty
                  ? const Center(child: Text('Nenhum usuário encontrado'))
                  : ListView.separated(
                      itemCount: _usuarios.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final u = _usuarios[i];
                        final efetivo = u['plano_efetivo'] ?? 'gratuito';
                        return ListTile(
                          title: Text(u['nome'] ?? '—'),
                          subtitle: Text('${u['email']} · ${u['tipo']}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_nomePlano[efetivo] ?? efetivo,
                                  style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w700,
                                      color: efetivo == 'gratuito'
                                          ? CafeColors.lightRoast
                                          : CafeColors.greenOk)),
                              if (efetivo != 'gratuito')
                                Text(_validade(u['plano_valido_ate']),
                                    style: GoogleFonts.dmSans(fontSize: 11)),
                            ],
                          ),
                          onTap: () => _abrir(u),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}

// ── Escolher plano e data final ───────────────────────────────────────
class _DefinirPlanoScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const _DefinirPlanoScreen({required this.usuario});
  @override
  State<_DefinirPlanoScreen> createState() => _DefinirPlanoScreenState();
}

class _DefinirPlanoScreenState extends State<_DefinirPlanoScreen> {
  late String _plano;
  late DateTime _ate;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final atual = widget.usuario['plano_efetivo'] as String? ?? 'gratuito';
    _plano = _planos.containsKey(atual) ? atual : 'premium';
    final validade = DateTime.tryParse(widget.usuario['plano_valido_ate'] ?? '')?.toLocal();
    final hoje = DateTime.now();
    _ate = validade != null && validade.isAfter(hoje)
        ? validade
        : DateTime(hoje.year, hoje.month + 1, hoje.day); // padrão: 1 mês
  }

  Future<void> _escolherData() async {
    final hoje = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _ate,
      firstDate: DateTime(hoje.year, hoje.month, hoje.day),
      lastDate: DateTime(hoje.year + 5),
      helpText: 'Plano liberado até',
    );
    if (d != null) setState(() => _ate = d);
  }

  void _atalho(int meses) {
    final h = DateTime.now();
    setState(() => _ate = DateTime(h.year, h.month + meses, h.day));
  }

  Future<void> _salvar(String plano) async {
    setState(() => _salvando = true);
    try {
      await ApiService.liberarPlanoAdmin(widget.usuario['id'], plano,
          plano == 'gratuito' ? null : DateFormat('yyyy-MM-dd').format(_ate));
      if (!mounted) return;
      // se liberou para a própria conta, atualiza o app na hora
      final eu = context.read<AppState>().usuario;
      if (eu?.id == widget.usuario['id']) await context.read<AppState>().recarregarUsuario();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(plano == 'gratuito'
              ? '${widget.usuario['nome']} voltou ao plano Gratuito'
              : 'Plano ${_planos[plano]} liberado para ${widget.usuario['nome']} até ${_dataBr.format(_ate)}')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        mostrarErro(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    final efetivo = u['plano_efetivo'] as String? ?? 'gratuito';
    return Scaffold(
      appBar: AppBar(title: const Text('Liberar plano')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline, color: CafeColors.caramel),
            title: Text(u['nome'] ?? '—'),
            subtitle: Text('${u['email']}\nAgora: ${_nomePlano[efetivo] ?? efetivo} ${_validade(u['plano_valido_ate'])}'),
            isThreeLine: true,
          ),
        ),
        const SizedBox(height: 16),
        Text('Plano', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final p in _planos.entries)
            ChoiceChip(
              label: Text(p.value),
              selected: _plano == p.key,
              onSelected: (_) => setState(() => _plano = p.key),
            ),
        ]),
        const SizedBox(height: 20),
        Text('Liberado até', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _escolherData,
          icon: const Icon(Icons.event),
          label: Text('${_dataBr.format(_ate)} (fim do dia)'),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final m in const [1, 3, 6, 12])
            ActionChip(label: Text(m == 12 ? '1 ano' : '$m ${m == 1 ? 'mês' : 'meses'}'), onPressed: () => _atalho(m)),
        ]),
        const SizedBox(height: 8),
        Text('Depois dessa data a conta volta sozinha ao plano Gratuito. Não gera cobrança nem entra na receita.',
            style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _salvando ? null : () => _salvar(_plano),
          child: _salvando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Liberar ${_planos[_plano]} até ${_dataBr.format(_ate)}'),
        ),
        if (efetivo != 'gratuito') ...[
          const SizedBox(height: 10),
          TextButton(
            onPressed: _salvando ? null : () => _salvar('gratuito'),
            style: TextButton.styleFrom(foregroundColor: CafeColors.redAlert),
            child: const Text('Encerrar agora (voltar ao Gratuito)'),
          ),
        ],
      ]),
    );
  }
}
