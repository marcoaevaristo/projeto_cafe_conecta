// lib/screens/empresa_screen.dart — conta empresarial (cooperativa, trading, banco, torrefação).
// Criar empresa, entrar com código de convite, ver membros e, para administradores,
// o painel consolidado com relatório em PDF e planilha.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/app_state.dart';
import '../utils/erros.dart';
import '../utils/theme.dart';
import 'relatorios_screen.dart';

const _tipos = {
  'cooperativa': 'Cooperativa',
  'trading': 'Trading / exportadora',
  'banco': 'Banco / financeira',
  'torrefacao': 'Torrefação',
  'outro': 'Outro',
};

class EmpresaScreen extends StatefulWidget {
  const EmpresaScreen({super.key});
  @override
  State<EmpresaScreen> createState() => _EmpresaScreenState();
}

class _EmpresaScreenState extends State<EmpresaScreen> {
  List<Map<String, dynamic>>? _empresas;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final l = await ApiService.getMinhasEmpresas();
      if (mounted) setState(() { _empresas = l; _erro = null; });
    } catch (e) {
      if (mounted) setState(() { _empresas = []; _erro = mensagemDeErro(e); });
    }
  }

  Future<void> _entrar() async {
    final c = TextEditingController();
    final codigo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Entrar numa empresa'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Peça o código de convite ao administrador da empresa.'),
          const SizedBox(height: 10),
          TextField(
            controller: c,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Código', hintText: 'XXXXX-XXXXX'),
          ),
          const SizedBox(height: 10),
          Text('Ao entrar, os administradores da empresa passam a ver seus lotes, vendas e compras no painel dela. '
              'Você pode sair quando quiser.',
              style: GoogleFonts.dmSans(fontSize: 12, color: CafeColors.lightRoast)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Entrar')),
        ],
      ),
    );
    if (codigo == null || codigo.isEmpty) return;
    try {
      final r = await ApiService.entrarEmpresa(codigo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Você entrou em ${r['empresa']?['nome'] ?? 'empresa'}')));
      }
      _carregar();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  Future<void> _criar() async {
    final ok = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (_) => const _FormEmpresa());
    if (ok == true) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _empresas;
    return Scaffold(
      appBar: AppBar(title: const Text('Conta empresarial')),
      body: lista == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    Text(
                      'Cooperativas, tradings, bancos e torrefações reúnem produtores, compradores e corretores '
                      'numa conta só e acompanham o volume ofertado e negociado de todos num painel.',
                      style: GoogleFonts.dmSans(fontSize: 13, height: 1.45, color: CafeColors.lightRoast),
                    ),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      ElevatedButton.icon(onPressed: _criar, icon: const Icon(Icons.add_business_outlined), label: const Text('Criar empresa')),
                      OutlinedButton.icon(onPressed: _entrar, icon: const Icon(Icons.vpn_key_outlined), label: const Text('Tenho um código')),
                    ]),
                    const SizedBox(height: 16),
                    if (_erro != null) Text(_erro!, textAlign: TextAlign.center),
                    if (_erro == null && lista.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Você ainda não faz parte de nenhuma empresa.',
                            textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: CafeColors.lightRoast)),
                      ),
                    for (final e in lista)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.business_outlined, color: CafeColors.caramel),
                          title: Text('${e['nome']}', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                          subtitle: Text('${_tipos[e['tipo']] ?? e['tipo']} · ${e['papel'] == 'admin' ? 'administrador' : 'membro'}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => _EmpresaDetalhe(empresa: e)));
                            _carregar();
                          },
                        ),
                      ),
                  ]),
                ),
              ),
            ),
    );
  }
}

class _FormEmpresa extends StatefulWidget {
  const _FormEmpresa();
  @override
  State<_FormEmpresa> createState() => _FormEmpresaState();
}

class _FormEmpresaState extends State<_FormEmpresa> {
  final _nome = TextEditingController();
  final _cnpj = TextEditingController();
  String _tipo = 'cooperativa';
  bool _enviando = false;

  @override
  void dispose() {
    _nome.dispose();
    _cnpj.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _enviando = true);
    try {
      await ApiService.criarEmpresa({'nome': _nome.text.trim(), 'tipo': _tipo, 'cnpj': _cnpj.text.trim()});
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Nova empresa',
              style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: CafeColors.darkRoast)),
          const SizedBox(height: 14),
          TextField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _tipo,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: _tipos.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => _tipo = v ?? _tipo),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _cnpj,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(14)],
            decoration: const InputDecoration(labelText: 'CNPJ (opcional, só números)'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _enviando ? null : _salvar, child: Text(_enviando ? 'Criando…' : 'Criar empresa')),
        ]),
      );
}

class _EmpresaDetalhe extends StatefulWidget {
  final Map<String, dynamic> empresa;
  const _EmpresaDetalhe({required this.empresa});
  @override
  State<_EmpresaDetalhe> createState() => _EmpresaDetalheState();
}

class _EmpresaDetalheState extends State<_EmpresaDetalhe> {
  List<Map<String, dynamic>>? _membros;

  bool get _admin => widget.empresa['papel'] == 'admin';
  String get _id => '${widget.empresa['id']}';

  @override
  void initState() {
    super.initState();
    _carregarMembros();
  }

  Future<void> _carregarMembros() async {
    try {
      final m = await ApiService.getMembrosEmpresa(_id);
      if (mounted) setState(() => _membros = m);
    } catch (e) {
      if (mounted) {
        setState(() => _membros = []);
        mostrarErro(context, e);
      }
    }
  }

  Future<void> _remover(String usuarioId, {bool euMesmo = false}) async {
    try {
      await ApiService.removerMembro(_id, usuarioId);
      if (euMesmo) {
        if (mounted) Navigator.pop(context);
      } else {
        _carregarMembros();
      }
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.empresa;
    final eu = context.read<AppState>().usuario?.id;
    final membros = Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(children: [
        if (_admin && e['codigo_convite'] != null)
          Card(
            color: CafeColors.cream,
            child: ListTile(
              leading: const Icon(Icons.vpn_key_outlined, color: CafeColors.caramel),
              title: SelectableText('${e['codigo_convite']}',
                  style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: CafeColors.darkRoast)),
              subtitle: const Text('Código de convite. Mande para quem deve entrar na empresa.'),
              trailing: IconButton(
                tooltip: 'Copiar',
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: '${e['codigo_convite']}'));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado')));
                  }
                },
              ),
            ),
          ),
        const SizedBox(height: 8),
        if (_membros == null) const Center(child: CircularProgressIndicator()),
        for (final m in _membros ?? [])
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              title: Text('${m['usuario']?['nome'] ?? '—'}', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
              subtitle: Text([
                m['papel'] == 'admin' ? 'administrador' : 'membro',
                m['usuario']?['tipo'],
                [m['usuario']?['cidade'], m['usuario']?['estado']].where((x) => x != null).join('/'),
              ].where((x) => x != null && '$x'.isNotEmpty).join(' · ')),
              trailing: !_admin || m['usuario']?['id'] == e['dono_id']
                  ? null
                  : PopupMenuButton<String>(
                      onSelected: (acao) async {
                        final uid = '${m['usuario']['id']}';
                        if (acao == 'remover') {
                          _remover(uid);
                        } else {
                          try {
                            await ApiService.mudarPapel(_id, uid, acao);
                            _carregarMembros();
                          } catch (err) {
                            if (context.mounted) mostrarErro(context, err);
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        if (m['papel'] != 'admin') const PopupMenuItem(value: 'admin', child: Text('Tornar administrador')),
                        if (m['papel'] == 'admin') const PopupMenuItem(value: 'membro', child: Text('Tornar membro')),
                        const PopupMenuItem(value: 'remover', child: Text('Remover da empresa')),
                      ],
                    ),
            ),
          ),
        if (eu != null && eu != e['dono_id']) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _remover(eu, euMesmo: true),
            icon: const Icon(Icons.logout, color: CafeColors.redAlert),
            label: const Text('Sair da empresa', style: TextStyle(color: CafeColors.redAlert)),
          ),
        ],
      ]),
    );

    return DefaultTabController(
      length: _admin ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${e['nome']}'),
          bottom: _admin
              ? const TabBar(
                  labelColor: CafeColors.gold,
                  unselectedLabelColor: CafeColors.cream,
                  indicatorColor: CafeColors.gold,
                  tabs: [Tab(text: 'Painel'), Tab(text: 'Membros')],
                )
              : null,
        ),
        body: _admin
            ? TabBarView(children: [
                PainelRelatorio(
                  titulo: 'Painel · ${e['nome']}',
                  subtitulo: 'Somatório de todos os membros da empresa.',
                  nomeArquivo: 'painel-${'${e['nome']}'.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}',
                  carregar: (de, ate) => ApiService.getPainelEmpresa(_id, de, ate),
                ),
                membros,
              ])
            : membros,
      ),
    );
  }
}
