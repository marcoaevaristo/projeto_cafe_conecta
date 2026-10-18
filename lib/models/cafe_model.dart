// lib/models/cafe_model.dart — v5 (UUID ids)

class CafeModel {
  final String? id;
  final String usuarioId;
  final String tipo;
  final String classificacao;
  final int quantidade;
  final String? bebida;
  final String? peneira;
  final String? safra;
  final String regiao;
  final String cidade;
  final String? fazenda;
  final double? precoSaca;
  final String status;
  final String? criadoEm;
  final String? corretorNome;
  final String? corretorEmpresa;
  final String? corretorTelefone;
  final bool? isFavorito;
  final int? scoreQualidade;
  final bool verificado;
  final double? lat;
  final double? lng;

  CafeModel({
    this.id, required this.usuarioId, required this.tipo,
    required this.classificacao, required this.quantidade,
    this.bebida, this.peneira, this.safra,
    required this.regiao, required this.cidade,
    this.fazenda, this.precoSaca, this.status = 'ativo',
    this.criadoEm, this.corretorNome, this.corretorEmpresa,
    this.corretorTelefone, this.isFavorito,
    this.scoreQualidade, this.verificado = false,
    this.lat, this.lng,
  });

  factory CafeModel.fromMap(Map<String, dynamic> map) => CafeModel(
    id: map['id']?.toString(),
    usuarioId: map['usuario_id']?.toString() ?? '',
    tipo: map['tipo'] ?? '',
    classificacao: map['classificacao'] ?? '',
    quantidade: (map['quantidade_sacas'] ?? map['quantidade'] ?? 0) as int,
    bebida: map['bebida'],
    peneira: map['peneira'],
    safra: map['safra'],
    regiao: map['regiao'] ?? '',
    cidade: map['cidade'] ?? '',
    fazenda: map['fazenda'],
    precoSaca: (map['preco_saca'] as num?)?.toDouble(),
    status: map['status'] ?? 'ativo',
    criadoEm: map['criado_em'],
    corretorNome: map['corretor_nome'] ?? map['usuario']?['nome'],
    corretorEmpresa: map['corretor_empresa'] ?? map['usuario']?['empresa'],
    corretorTelefone: map['corretor_telefone'] ?? map['usuario']?['telefone'],
    // API retorna bool; SQLite retornava int
    isFavorito: map['is_favorito'] == true || map['is_favorito'] == 1,
    scoreQualidade: (map['score'] ?? map['score_qualidade']) as int?,
    verificado: map['verificado'] == true || map['verificado'] == 1,
    lat: (map['lat'] as num?)?.toDouble(),
    lng: (map['lng'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'usuario_id': usuarioId, 'tipo': tipo, 'classificacao': classificacao,
    'quantidade_sacas': quantidade, // nome esperado pelo backend
    'bebida': bebida, 'peneira': peneira, 'safra': safra,
    'regiao': regiao, 'cidade': cidade, 'fazenda': fazenda,
    'preco_saca': precoSaca, 'status': status,
    'score': scoreQualidade,
    'lat': lat, 'lng': lng,
  };

  String get nomeCurto => '$tipo – $classificacao';

  String get scoreLabel {
    final s = scoreQualidade ?? 0;
    if (s >= 90) return 'Excelente';
    if (s >= 85) return 'Muito Bom';
    if (s >= 80) return 'Bom';
    return 'Regular';
  }
}

class UsuarioModel {
  final String? id;
  final String nome;
  final String email;
  final String tipo;
  final String? empresa;
  final String? telefone;
  final String? regiao;
  final String? cidade;
  final String? estado;
  final String? plano;
  final bool verificado;

  UsuarioModel({
    this.id, required this.nome, required this.email,
    required this.tipo, this.empresa, this.telefone,
    this.regiao, this.cidade, this.estado, this.plano,
    this.verificado = false,
  });

  factory UsuarioModel.fromMap(Map<String, dynamic> map) => UsuarioModel(
    id: map['id']?.toString(),
    nome: map['nome'] ?? '',
    email: map['email'] ?? '',
    tipo: map['tipo'] ?? 'comprador',
    empresa: map['empresa'],
    telefone: map['telefone'],
    regiao: map['regiao'],
    cidade: map['cidade'],
    estado: map['estado'],
    plano: map['plano'],
    verificado: map['verificado'] == true || map['verificado'] == 1,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'nome': nome, 'email': email, 'tipo': tipo,
    'empresa': empresa, 'telefone': telefone, 'regiao': regiao,
    'cidade': cidade, 'estado': estado, 'plano': plano,
    'verificado': verificado ? 1 : 0,
  };
}

class MensagemModel {
  final String? id;
  final String deUsuarioId;
  final String paraUsuarioId;
  final String texto;
  final bool lida;
  final String? criadoEm;
  final String? remetenteNome;
  final String? remetenteEmpresa;

  MensagemModel({
    this.id, required this.deUsuarioId, required this.paraUsuarioId,
    required this.texto, this.lida = false, this.criadoEm,
    this.remetenteNome, this.remetenteEmpresa,
  });

  factory MensagemModel.fromMap(Map<String, dynamic> map) => MensagemModel(
    id: map['id']?.toString(),
    deUsuarioId: map['de_usuario_id']?.toString() ?? '',
    paraUsuarioId: map['para_usuario_id']?.toString() ?? '',
    texto: map['texto'] ?? '',
    lida: map['lida'] == true || map['lida'] == 1,
    criadoEm: map['criado_em'],
    remetenteNome: map['remetente_nome'],
    remetenteEmpresa: map['remetente_empresa'],
  );
}

class AlertaModel {
  final String? id;
  final String usuarioId;
  final String? tipoCafe;
  final String? classificacao;
  final String? regiao;
  final double? precoMaximo;
  final int? scoreMinimo;
  final bool ativo;
  final String? criadoEm;

  AlertaModel({
    this.id, required this.usuarioId, this.tipoCafe, this.classificacao,
    this.regiao, this.precoMaximo, this.scoreMinimo,
    this.ativo = true, this.criadoEm,
  });

  factory AlertaModel.fromMap(Map<String, dynamic> map) => AlertaModel(
    id: map['id']?.toString(),
    usuarioId: map['usuario_id']?.toString() ?? '',
    tipoCafe: map['tipo_cafe'],
    classificacao: map['classificacao'],
    regiao: map['regiao'],
    precoMaximo: (map['preco_maximo'] as num?)?.toDouble(),
    scoreMinimo: map['score_minimo'],
    ativo: map['ativo'] == true || map['ativo'] == 1,
    criadoEm: map['criado_em'],
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'usuario_id': usuarioId, 'tipo_cafe': tipoCafe,
    'classificacao': classificacao, 'regiao': regiao,
    'preco_maximo': precoMaximo, 'score_minimo': scoreMinimo,
    'ativo': ativo ? 1 : 0,
  };

  String get descricao {
    final p = [if (tipoCafe != null) tipoCafe!, if (classificacao != null) classificacao!, if (regiao != null) regiao!];
    final base = p.isEmpty ? 'Qualquer café' : p.join(' · ');
    final e = [if (precoMaximo != null) 'Preço < R\$ ${precoMaximo!.toStringAsFixed(0)}', if (scoreMinimo != null) 'Score ≥ $scoreMinimo'];
    return e.isEmpty ? base : '$base\n${e.join(' · ')}';
  }
}

class PropostaModel {
  final String? id;
  final String deUsuarioId;
  final String paraUsuarioId;
  final String cafeId;
  final int quantidadeSacas;
  final double precoOfertado;
  final String condicaoPagamento;
  final String prazoEntrega;
  final String? localEntrega;
  final String? observacoes;
  final String status;
  final String? criadoEm;
  final String? remetenteNome;
  final String? remetenteEmpresa;
  final String? cafeTipo;
  final String? cafeClassificacao;
  final String? cafeFazenda;

  PropostaModel({
    this.id, required this.deUsuarioId, required this.paraUsuarioId,
    required this.cafeId, required this.quantidadeSacas,
    required this.precoOfertado, required this.condicaoPagamento,
    required this.prazoEntrega, this.localEntrega, this.observacoes,
    this.status = 'aguardando', this.criadoEm,
    this.remetenteNome, this.remetenteEmpresa,
    this.cafeTipo, this.cafeClassificacao, this.cafeFazenda,
  });

  double get valorTotal => quantidadeSacas * precoOfertado;

  factory PropostaModel.fromMap(Map<String, dynamic> map) => PropostaModel(
    id: map['id']?.toString(),
    deUsuarioId: map['de_usuario_id']?.toString() ?? '',
    paraUsuarioId: map['para_usuario_id']?.toString() ?? '',
    cafeId: map['cafe_id']?.toString() ?? '',
    quantidadeSacas: (map['quantidade_sacas'] ?? 0) as int,
    precoOfertado: (map['preco_ofertado'] as num?)?.toDouble() ?? 0,
    condicaoPagamento: map['condicao_pagamento'] ?? '',
    prazoEntrega: map['prazo_entrega'] ?? '',
    localEntrega: map['local_entrega'],
    observacoes: map['observacoes'],
    status: map['status'] ?? 'aguardando',
    criadoEm: map['criado_em'],
    remetenteNome: map['remetente_nome'],
    remetenteEmpresa: map['remetente_empresa'],
    cafeTipo: map['cafe_tipo'],
    cafeClassificacao: map['cafe_classificacao'],
    cafeFazenda: map['cafe_fazenda'],
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'de_usuario_id': deUsuarioId, 'para_usuario_id': paraUsuarioId,
    'cafe_id': cafeId, 'quantidade_sacas': quantidadeSacas,
    'preco_ofertado': precoOfertado, 'condicao_pagamento': condicaoPagamento,
    'prazo_entrega': prazoEntrega, 'local_entrega': localEntrega,
    'observacoes': observacoes, 'status': status,
  };
}

class HistoricoPrecoModel {
  final int? id;
  final String tipoCafe;
  final String regiao;
  final double precoMedio;
  final String mes;

  HistoricoPrecoModel({
    this.id, required this.tipoCafe, required this.regiao,
    required this.precoMedio, required this.mes,
  });

  factory HistoricoPrecoModel.fromMap(Map<String, dynamic> map) => HistoricoPrecoModel(
    id: map['id'],
    tipoCafe: map['tipo_cafe'] ?? '',
    regiao: map['regiao'] ?? '',
    precoMedio: (map['preco_medio'] as num?)?.toDouble() ?? 0,
    mes: map['mes'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'tipo_cafe': tipoCafe, 'regiao': regiao,
    'preco_medio': precoMedio, 'mes': mes,
  };
}

class AvaliacaoModel {
  final String? id;
  final String deUsuarioId;
  final String paraUsuarioId;
  final String propostaId;
  final int nota;
  final String? comentario;
  final String? criadoEm;
  final String? avaliadorNome;
  final String? avaliadorEmpresa;

  AvaliacaoModel({
    this.id, required this.deUsuarioId, required this.paraUsuarioId,
    required this.propostaId, required this.nota,
    this.comentario, this.criadoEm,
    this.avaliadorNome, this.avaliadorEmpresa,
  });

  factory AvaliacaoModel.fromMap(Map<String, dynamic> map) => AvaliacaoModel(
    id: map['id']?.toString(),
    deUsuarioId: map['de_usuario_id']?.toString() ?? '',
    paraUsuarioId: map['para_usuario_id']?.toString() ?? '',
    propostaId: map['proposta_id']?.toString() ?? '',
    nota: (map['nota'] ?? 5) as int,
    comentario: map['comentario'],
    criadoEm: map['criado_em'],
    avaliadorNome: map['avaliador_nome'],
    avaliadorEmpresa: map['avaliador_empresa'],
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'de_usuario_id': deUsuarioId, 'para_usuario_id': paraUsuarioId,
    'proposta_id': propostaId, 'nota': nota, 'comentario': comentario,
  };
}
