// lib/services/database_service.dart — v3
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/cafe_model.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DatabaseService {
  static Database? _db;
  static Future<Database> get db async { _db ??= await _initDb(); return _db!; }

  static Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'cafe_conecta_v3.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE usuarios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT NOT NULL, email TEXT UNIQUE NOT NULL, senha_hash TEXT NOT NULL,
      tipo TEXT NOT NULL DEFAULT 'comprador', empresa TEXT, telefone TEXT,
      regiao TEXT, verificado INTEGER DEFAULT 0,
      total_avaliacoes INTEGER DEFAULT 0, media_avaliacao REAL DEFAULT 0,
      criado_em TEXT DEFAULT CURRENT_TIMESTAMP)''');

    await db.execute('''CREATE TABLE cafes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      usuario_id INTEGER NOT NULL, tipo TEXT NOT NULL, classificacao TEXT NOT NULL,
      quantidade INTEGER NOT NULL, bebida TEXT, peneira TEXT, safra TEXT,
      regiao TEXT NOT NULL, cidade TEXT NOT NULL, fazenda TEXT,
      preco_saca REAL, score_qualidade INTEGER DEFAULT 75,
      lat REAL, lng REAL,
      status TEXT DEFAULT 'ativo', criado_em TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (usuario_id) REFERENCES usuarios(id))''');

    await db.execute('''CREATE TABLE favoritos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      usuario_id INTEGER NOT NULL, cafe_id INTEGER NOT NULL,
      UNIQUE(usuario_id, cafe_id))''');

    await db.execute('''CREATE TABLE mensagens (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      de_usuario_id INTEGER NOT NULL, para_usuario_id INTEGER NOT NULL,
      texto TEXT NOT NULL, lida INTEGER DEFAULT 0,
      criado_em TEXT DEFAULT CURRENT_TIMESTAMP)''');

    await db.execute('''CREATE TABLE alertas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      usuario_id INTEGER NOT NULL, tipo_cafe TEXT, classificacao TEXT,
      regiao TEXT, preco_maximo REAL, score_minimo INTEGER,
      ativo INTEGER DEFAULT 1, criado_em TEXT DEFAULT CURRENT_TIMESTAMP)''');

    await db.execute('''CREATE TABLE propostas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      de_usuario_id INTEGER NOT NULL, para_usuario_id INTEGER NOT NULL,
      cafe_id INTEGER NOT NULL, quantidade_sacas INTEGER NOT NULL,
      preco_ofertado REAL NOT NULL, condicao_pagamento TEXT NOT NULL,
      prazo_entrega TEXT NOT NULL, local_entrega TEXT, observacoes TEXT,
      status TEXT DEFAULT 'aguardando',
      criado_em TEXT DEFAULT CURRENT_TIMESTAMP)''');

    await db.execute('''CREATE TABLE historico_precos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tipo_cafe TEXT NOT NULL, regiao TEXT NOT NULL,
      preco_medio REAL NOT NULL, mes TEXT NOT NULL)''');

    // v3: avaliações
    await db.execute('''CREATE TABLE avaliacoes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      de_usuario_id INTEGER NOT NULL, para_usuario_id INTEGER NOT NULL,
      proposta_id INTEGER NOT NULL, nota INTEGER NOT NULL,
      comentario TEXT, criado_em TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (de_usuario_id) REFERENCES usuarios(id),
      FOREIGN KEY (para_usuario_id) REFERENCES usuarios(id))''');

    await _seed(db);
  }

  static Future<void> _seed(Database db) async {
    String h(String pw) => sha256.convert(utf8.encode(pw)).toString();

    for (final u in [
      {'nome':'João Pedro da Silva','email':'joao@cafesuldeminas.com.br','senha_hash':h('123456'),'tipo':'corretor','empresa':'Café Sul de Minas','telefone':'(34) 99999-1234','regiao':'Sul de Minas','verificado':1,'media_avaliacao':4.8,'total_avaliacoes':47},
      {'nome':'Maria Fazenda Santa Maria','email':'maria@fazenda.com.br','senha_hash':h('123456'),'tipo':'corretor','empresa':'Fazenda Santa Maria','telefone':'(35) 98888-5678','regiao':'Sul de Minas','verificado':1,'media_avaliacao':4.6,'total_avaliacoes':23},
      {'nome':'Carlos Cafés do Vale','email':'carlos@cafesdovale.com.br','senha_hash':h('123456'),'tipo':'corretor','empresa':'Cafés do Vale','telefone':'(32) 97777-9012','regiao':'Zona da Mata','verificado':0,'media_avaliacao':4.2,'total_avaliacoes':11},
      {'nome':'Ana Compradora','email':'ana@torrefacao.com.br','senha_hash':h('123456'),'tipo':'comprador','empresa':'Torrefação Aroma','telefone':'(11) 96666-3456','regiao':'São Paulo','verificado':0,'media_avaliacao':4.5,'total_avaliacoes':8},
      {'nome':'Cooperativa Cerrado','email':'cooperativa@cerrado.com.br','senha_hash':h('123456'),'tipo':'corretor','empresa':'Cooperativa Cerrado','telefone':'(34) 95555-7890','regiao':'Cerrado Mineiro','verificado':1,'media_avaliacao':4.9,'total_avaliacoes':62},
    ]) { await db.insert('usuarios', u); }

    for (final c in [
      {'usuario_id':1,'tipo':'Arábica','classificacao':'Tipo 6','quantidade':1250,'bebida':'Dura','peneira':'16/18','safra':'2024/2025','regiao':'Patrocínio - MG','cidade':'Patrocínio','fazenda':'Fazenda Boa Vista','preco_saca':980.0,'score_qualidade':84,'lat':-18.9736,'lng':-46.9926,'status':'ativo'},
      {'usuario_id':2,'tipo':'Conilon','classificacao':'Tipo 7','quantidade':800,'bebida':'Riada','peneira':'13/15','safra':'2024/2025','regiao':'Varginha - ES','cidade':'Cachoeiro','fazenda':'Cafés do Vale','preco_saca':650.0,'score_qualidade':76,'lat':-20.8439,'lng':-41.1128,'status':'ativo'},
      {'usuario_id':2,'tipo':'Arábica','classificacao':'Tipo 4','quantidade':600,'bebida':'Mole','peneira':'17/18','safra':'2024/2025','regiao':'Guapé - MG','cidade':'Guapé','fazenda':'Fazenda Santa Maria','preco_saca':1150.0,'score_qualidade':80,'lat':-20.7617,'lng':-45.9197,'status':'ativo'},
      {'usuario_id':1,'tipo':'Arábica','classificacao':'Especial','quantidade':300,'bebida':'Estritamente Mole','peneira':'18 acima','safra':'2024/2025','regiao':'Monte Carmelo - MG','cidade':'Monte Carmelo','fazenda':'Fazenda Harmonia','preco_saca':1800.0,'score_qualidade':91,'lat':-18.7261,'lng':-47.5003,'status':'ativo'},
      {'usuario_id':3,'tipo':'Robusta','classificacao':'Tipo 6','quantidade':1500,'bebida':'Dura','peneira':'15/16','safra':'2024/2025','regiao':'Colatina - ES','cidade':'Colatina','fazenda':'Sítio Bela Vista','preco_saca':520.0,'score_qualidade':71,'lat':-19.5392,'lng':-40.6303,'status':'ativo'},
      {'usuario_id':5,'tipo':'Arábica','classificacao':'Especial','quantidade':500,'bebida':'Estritamente Mole','peneira':'18+','safra':'2024/2025','regiao':'Patrocínio - MG','cidade':'Patrocínio','fazenda':'Cooperativa Cerrado','preco_saca':1800.0,'score_qualidade':93,'lat':-18.9200,'lng':-46.9900,'status':'ativo'},
      {'usuario_id':2,'tipo':'Arábica','classificacao':'Tipo 6','quantidade':900,'bebida':'Mole','peneira':'16/17','safra':'2024/2025','regiao':'Varginha - MG','cidade':'Varginha','fazenda':'Sítio das Pedras','preco_saca':1050.0,'score_qualidade':82,'lat':-21.5513,'lng':-45.4308,'status':'ativo'},
      {'usuario_id':3,'tipo':'Arábica','classificacao':'Tipo 7','quantidade':400,'bebida':'Riada','peneira':'14/16','safra':'2024/2025','regiao':'Três Pontas - MG','cidade':'Três Pontas','fazenda':'Fazenda Aurora','preco_saca':880.0,'score_qualidade':78,'lat':-21.3667,'lng':-45.5127,'status':'ativo'},
    ]) { await db.insert('cafes', c); }

    for (final m in [
      {'de_usuario_id':4,'para_usuario_id':1,'texto':'Olá, tenho interesse no Arábica Tipo 6!','lida':1},
      {'de_usuario_id':1,'para_usuario_id':4,'texto':'Olá! Temos 1.250 sacas. Posso entregar em 15 dias.','lida':1},
      {'de_usuario_id':2,'para_usuario_id':4,'texto':'Nova safra disponível. Conilon Tipo 7, 800 sacas!','lida':0},
      {'de_usuario_id':5,'para_usuario_id':4,'texto':'Preços atualizados safra 24/25.','lida':0},
    ]) { await db.insert('mensagens', m); }

    for (final a in [
      {'usuario_id':4,'tipo_cafe':'Arábica','classificacao':'Especial','regiao':'Sul de Minas','preco_maximo':1500.0,'score_minimo':85,'ativo':1},
      {'usuario_id':4,'tipo_cafe':'Arábica','classificacao':'Tipo 6','regiao':'Patrocínio - MG','preco_maximo':950.0,'score_minimo':80,'ativo':1},
    ]) { await db.insert('alertas', a); }

    // Proposta aceita (para poder avaliar)
    await db.insert('propostas', {
      'de_usuario_id':4,'para_usuario_id':1,'cafe_id':1,
      'quantidade_sacas':500,'preco_ofertado':960.0,
      'condicao_pagamento':'30/60 dias','prazo_entrega':'15 dias',
      'local_entrega':'FOB Fazenda', 'status':'aceita',
    });

    // Avaliações de exemplo
    for (final av in [
      {'de_usuario_id':4,'para_usuario_id':1,'proposta_id':1,'nota':5,'comentario':'Excelente qualidade e entrega no prazo. Muito profissional!'},
      {'de_usuario_id':1,'para_usuario_id':4,'proposta_id':1,'nota':5,'comentario':'Ótimo comprador, pagamento em dia. Recomendo!'},
    ]) { await db.insert('avaliacoes', av); }

    final meses = ['2024-11','2024-12','2025-01','2025-02','2025-03','2025-04'];
    final sulP = [980.0,1010.0,1050.0,1090.0,1150.0,1250.0];
    final cerP = [900.0,920.0,960.0,980.0,1010.0,1060.0];
    final matP = [820.0,840.0,850.0,860.0,840.0,830.0];
    for (int i = 0; i < meses.length; i++) {
      await db.insert('historico_precos', {'tipo_cafe':'Arábica','regiao':'Sul de Minas','preco_medio':sulP[i],'mes':meses[i]});
      await db.insert('historico_precos', {'tipo_cafe':'Arábica','regiao':'Cerrado Mineiro','preco_medio':cerP[i],'mes':meses[i]});
      await db.insert('historico_precos', {'tipo_cafe':'Arábica','regiao':'Zona da Mata','preco_medio':matP[i],'mes':meses[i]});
    }
  }

  // ── USUÁRIOS ──
  static Future<UsuarioModel?> login(String email, String senha) async {
    final d = await db;
    final hash = sha256.convert(utf8.encode(senha)).toString();
    final rows = await d.query('usuarios', where: 'email=? AND senha_hash=?', whereArgs: [email, hash]);
    return rows.isEmpty ? null : UsuarioModel.fromMap(rows.first);
  }

  static Future<int> cadastrarUsuario(Map<String, dynamic> dados) async {
    final d = await db;
    dados['senha_hash'] = sha256.convert(utf8.encode(dados['senha'])).toString();
    dados.remove('senha');
    return await d.insert('usuarios', dados);
  }

  static Future<UsuarioModel?> getUsuario(int id) async {
    final rows = await (await db).query('usuarios', where: 'id=?', whereArgs: [id]);
    return rows.isEmpty ? null : UsuarioModel.fromMap(rows.first);
  }

  static Future<Map<String, dynamic>?> getUsuarioCompleto(int id) async {
    final rows = await (await db).rawQuery('''
      SELECT u.*,
        (SELECT AVG(nota) FROM avaliacoes WHERE para_usuario_id=u.id) as media_calc,
        (SELECT COUNT(*) FROM avaliacoes WHERE para_usuario_id=u.id) as total_calc,
        (SELECT COUNT(*) FROM cafes WHERE usuario_id=u.id AND status='ativo') as lotes_ativos,
        (SELECT COUNT(*) FROM propostas WHERE (de_usuario_id=u.id OR para_usuario_id=u.id) AND status='aceita') as negocios_fechados
      FROM usuarios u WHERE u.id=?''', [id]);
    return rows.isEmpty ? null : rows.first as Map<String, dynamic>;
  }

  // ── CAFÉS ──
  static Future<List<CafeModel>> getCafes({
    String? tipo, String? classificacao, String? regiao,
    String? statusFiltro, int? usuarioId, bool apenasAtivos = true,
    int? scoreMinimo,
  }) async {
    final d = await db;
    final where = <String>[];
    final args = <dynamic>[];
    if (apenasAtivos && statusFiltro == null) where.add("c.status='ativo'");
    if (statusFiltro != null && statusFiltro != 'todos') { where.add('c.status=?'); args.add(statusFiltro); }
    if (tipo != null && tipo != 'Todos') { where.add('c.tipo=?'); args.add(tipo); }
    if (classificacao != null && classificacao != 'Todas') { where.add('c.classificacao=?'); args.add(classificacao); }
    if (regiao != null && regiao != 'Todas') { where.add('c.regiao LIKE ?'); args.add('%$regiao%'); }
    if (usuarioId != null) { where.add('c.usuario_id=?'); args.add(usuarioId); }
    if (scoreMinimo != null) { where.add('c.score_qualidade >= ?'); args.add(scoreMinimo); }
    final ws = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await d.rawQuery('''
      SELECT c.*, u.nome AS corretor_nome, u.empresa AS corretor_empresa,
             u.telefone AS corretor_telefone, u.verificado
      FROM cafes c LEFT JOIN usuarios u ON u.id=c.usuario_id
      $ws ORDER BY c.criado_em DESC''', args);
    return rows.map(CafeModel.fromMap).toList();
  }

  static Future<int> inserirCafe(CafeModel cafe) async => (await db).insert('cafes', cafe.toMap());
  static Future<void> atualizarStatusCafe(int id, String status) async =>
    (await db).update('cafes', {'status': status}, where: 'id=?', whereArgs: [id]);

  // ── FAVORITOS ──
  static Future<List<CafeModel>> getFavoritos(int uid) async {
    final rows = await (await db).rawQuery('''
      SELECT c.*, u.nome AS corretor_nome, u.empresa AS corretor_empresa,
             u.telefone AS corretor_telefone, u.verificado, 1 AS is_favorito
      FROM favoritos f JOIN cafes c ON c.id=f.cafe_id
      LEFT JOIN usuarios u ON u.id=c.usuario_id
      WHERE f.usuario_id=? ORDER BY f.id DESC''', [uid]);
    return rows.map(CafeModel.fromMap).toList();
  }

  static Future<bool> isFavorito(int uid, int cid) async {
    final r = await (await db).query('favoritos', where: 'usuario_id=? AND cafe_id=?', whereArgs: [uid, cid]);
    return r.isNotEmpty;
  }

  static Future<void> toggleFavorito(int uid, int cid) async {
    final d = await db;
    if (await isFavorito(uid, cid)) {
      await d.delete('favoritos', where: 'usuario_id=? AND cafe_id=?', whereArgs: [uid, cid]);
    } else {
      await d.insert('favoritos', {'usuario_id': uid, 'cafe_id': cid});
    }
  }

  // ── MENSAGENS ──
  static Future<List<Map<String, dynamic>>> getConversas(int uid) async =>
    (await (await db).rawQuery('''
      SELECT CASE WHEN m.de_usuario_id=? THEN m.para_usuario_id ELSE m.de_usuario_id END AS contato_id,
             u.nome AS contato_nome, u.empresa AS contato_empresa, u.verificado AS contato_verificado,
             m.texto AS ultima_mensagem, m.criado_em, m.lida, m.de_usuario_id
      FROM mensagens m
      JOIN usuarios u ON u.id=CASE WHEN m.de_usuario_id=? THEN m.para_usuario_id ELSE m.de_usuario_id END
      WHERE m.de_usuario_id=? OR m.para_usuario_id=?
      GROUP BY contato_id ORDER BY m.criado_em DESC''',
      [uid, uid, uid, uid])).toList();

  static Future<List<MensagemModel>> getMensagensConversa(int uid, int cid) async {
    final rows = await (await db).rawQuery('''
      SELECT m.*, u.nome AS remetente_nome, u.empresa AS remetente_empresa
      FROM mensagens m JOIN usuarios u ON u.id=m.de_usuario_id
      WHERE (m.de_usuario_id=? AND m.para_usuario_id=?) OR (m.de_usuario_id=? AND m.para_usuario_id=?)
      ORDER BY m.criado_em ASC''', [uid, cid, cid, uid]);
    return rows.map(MensagemModel.fromMap).toList();
  }

  static Future<void> enviarMensagem(int de, int para, String texto) async =>
    (await db).insert('mensagens', {'de_usuario_id': de, 'para_usuario_id': para, 'texto': texto, 'criado_em': DateTime.now().toIso8601String()});

  static Future<int> countNaoLidas(int uid) async {
    final r = await (await db).rawQuery('SELECT COUNT(*) as cnt FROM mensagens WHERE para_usuario_id=? AND lida=0', [uid]);
    return r.first['cnt'] as int;
  }

  // ── ALERTAS ──
  static Future<List<AlertaModel>> getAlertas(int uid) async {
    final rows = await (await db).query('alertas', where: 'usuario_id=?', whereArgs: [uid], orderBy: 'id DESC');
    return rows.map(AlertaModel.fromMap).toList();
  }

  static Future<int> inserirAlerta(AlertaModel a) async => (await db).insert('alertas', a.toMap());
  static Future<void> toggleAlerta(int id, bool ativo) async =>
    (await db).update('alertas', {'ativo': ativo ? 1 : 0}, where: 'id=?', whereArgs: [id]);
  static Future<void> excluirAlerta(int id) async =>
    (await db).delete('alertas', where: 'id=?', whereArgs: [id]);

  // ── PROPOSTAS ──
  static Future<List<PropostaModel>> getPropostas(int uid) async {
    final rows = await (await db).rawQuery('''
      SELECT p.*, u.nome AS remetente_nome, u.empresa AS remetente_empresa,
             c.tipo AS cafe_tipo, c.classificacao AS cafe_classificacao, c.fazenda AS cafe_fazenda
      FROM propostas p
      LEFT JOIN usuarios u ON u.id=p.de_usuario_id
      LEFT JOIN cafes c ON c.id=p.cafe_id
      WHERE p.de_usuario_id=? OR p.para_usuario_id=?
      ORDER BY p.criado_em DESC''', [uid, uid]);
    return rows.map(PropostaModel.fromMap).toList();
  }

  static Future<int> inserirProposta(PropostaModel p) async => (await db).insert('propostas', p.toMap());
  static Future<void> atualizarStatusProposta(int id, String status) async =>
    (await db).update('propostas', {'status': status}, where: 'id=?', whereArgs: [id]);

  // ── HISTÓRICO DE PREÇOS ──
  static Future<List<HistoricoPrecoModel>> getHistoricoPrecos({String? regiao, int meses = 6}) async {
    final rows = await (await db).rawQuery(
      'SELECT * FROM historico_precos ${regiao != null ? "WHERE regiao LIKE \'%$regiao%\'" : ""} ORDER BY mes ASC LIMIT ${meses * 3}');
    return rows.map(HistoricoPrecoModel.fromMap).toList();
  }

  // ── AVALIAÇÕES (v3) ──
  static Future<List<AvaliacaoModel>> getAvaliacoes(int paraUsuarioId) async {
    final rows = await (await db).rawQuery('''
      SELECT av.*, u.nome AS avaliador_nome, u.empresa AS avaliador_empresa
      FROM avaliacoes av JOIN usuarios u ON u.id=av.de_usuario_id
      WHERE av.para_usuario_id=? ORDER BY av.criado_em DESC''', [paraUsuarioId]);
    return rows.map(AvaliacaoModel.fromMap).toList();
  }

  static Future<Map<String, dynamic>> getResumoAvaliacoes(int paraUsuarioId) async {
    final rows = await (await db).rawQuery('''
      SELECT AVG(nota) as media, COUNT(*) as total,
             SUM(CASE WHEN nota=5 THEN 1 ELSE 0 END) as n5,
             SUM(CASE WHEN nota=4 THEN 1 ELSE 0 END) as n4,
             SUM(CASE WHEN nota=3 THEN 1 ELSE 0 END) as n3,
             SUM(CASE WHEN nota<=2 THEN 1 ELSE 0 END) as n2
      FROM avaliacoes WHERE para_usuario_id=?''', [paraUsuarioId]);
    return rows.first as Map<String, dynamic>;
  }

  static Future<int> inserirAvaliacao(AvaliacaoModel av) async {
    final d = await db;
    final id = await d.insert('avaliacoes', av.toMap());
    final resumo = await getResumoAvaliacoes(av.paraUsuarioId);
    await d.update('usuarios', {
      'media_avaliacao': resumo['media'] ?? 0,
      'total_avaliacoes': resumo['total'] ?? 0,
    }, where: 'id=?', whereArgs: [av.paraUsuarioId]);
    return id;
  }

  static Future<bool> jaAvaliou(int deUid, int propostaId) async {
    final rows = await (await db).query('avaliacoes', where: 'de_usuario_id=? AND proposta_id=?', whereArgs: [deUid, propostaId]);
    return rows.isNotEmpty;
  }

  // ── DASHBOARD (v3) ──
  static Future<Map<String, dynamic>> getDashboard(int uid) async {
    final d = await db;
    final lotesAtivos = (await d.rawQuery('SELECT COUNT(*) as c FROM cafes WHERE usuario_id=? AND status=\'ativo\'', [uid])).first['c'];
    final totalVisualizacoes = (await d.rawQuery('SELECT COUNT(*) as c FROM favoritos f JOIN cafes c ON c.id=f.cafe_id WHERE c.usuario_id=?', [uid])).first['c'];
    final propostasRecebidas = (await d.rawQuery('SELECT COUNT(*) as c FROM propostas WHERE para_usuario_id=?', [uid])).first['c'];
    final negociosFechados = (await d.rawQuery('SELECT COUNT(*) as c FROM propostas WHERE (de_usuario_id=? OR para_usuario_id=?) AND status=\'aceita\'', [uid, uid])).first['c'];
    final mediaAvaliacao = (await d.rawQuery('SELECT AVG(nota) as m FROM avaliacoes WHERE para_usuario_id=?', [uid])).first['m'];
    return {
      'lotes_ativos': lotesAtivos,
      'visualizacoes': totalVisualizacoes,
      'propostas_recebidas': propostasRecebidas,
      'negocios_fechados': negociosFechados,
      'media_avaliacao': mediaAvaliacao ?? 0.0,
    };
  }
}
