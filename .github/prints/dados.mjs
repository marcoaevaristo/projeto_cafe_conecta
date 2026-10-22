// Dados de EXEMPLO para os prints de divulgação (nenhum dado real de usuário).
const hoje = new Date();
const dias = (n) => new Date(hoje.getTime() - n * 86400000).toISOString();

export const EU = {
  id: 'u-demo',
  nome: 'Marco Evaristo',
  email: 'demo@cafeconecta.app',
  tipo: 'corretor',
  plano: 'premium',
  plano_contratado: 'premium',
  plano_valido_ate: new Date(hoje.getTime() + 300 * 86400000).toISOString(),
  cidade: 'Três Corações',
  estado: 'MG',
  telefone: '(35) 90000-0000',
  verificado: true,
  is_admin: false,
  criado_em: dias(120),
};

const pessoas = {
  'u-demo': { id: 'u-demo', nome: 'Marco Evaristo', cidade: 'Três Corações', estado: 'MG', verificado: true, telefone: '(35) 90000-0000' },
  'u-ana': { id: 'u-ana', nome: 'Ana Paula Moreira', cidade: 'Carmo de Minas', estado: 'MG', verificado: true, telefone: '(35) 90000-0001' },
  'u-joao': { id: 'u-joao', nome: 'João Batista Ribeiro', cidade: 'Patrocínio', estado: 'MG', verificado: true, telefone: '(34) 90000-0002' },
  'u-luiz': { id: 'u-luiz', nome: 'Luiz Fernando Costa', cidade: 'Franca', estado: 'SP', verificado: false, telefone: '(16) 90000-0003' },
  'u-rosa': { id: 'u-rosa', nome: 'Rosângela Teixeira', cidade: 'Manhuaçu', estado: 'MG', verificado: true, telefone: '(33) 90000-0004' },
  'u-edu': { id: 'u-edu', nome: 'Eduardo Pimenta', cidade: 'Vila Valério', estado: 'ES', verificado: true, telefone: '(27) 90000-0005' },
};

const lote = (id, dono, o) => ({
  id, usuario_id: dono, status: 'ativo', verificado: pessoas[dono].verificado,
  destaque: false, fotos: [], estado: pessoas[dono].estado, usuario: pessoas[dono],
  ...o,
});

export const LOTES = [
  lote('c1', 'u-ana', { tipo: 'Arábica', classificacao: 'Especial', bebida: 'Estritamente Mole', peneira: '17/18', safra: '2025/2026', regiao: 'Sul de Minas', cidade: 'Carmo de Minas', fazenda: 'Fazenda Santa Helena', quantidade_sacas: 80, preco_saca: 2680, score: 87, destaque: true, criado_em: dias(1), lat: -22.12, lng: -45.13 }),
  lote('c2', 'u-demo', { tipo: 'Arábica', classificacao: 'Tipo 6', bebida: 'Dura', peneira: '16/18', safra: '2025/2026', regiao: 'Sul de Minas', cidade: 'Três Corações', fazenda: 'Sítio Boa Vista', quantidade_sacas: 250, preco_saca: 2050, score: 81, criado_em: dias(2), lat: -21.69, lng: -45.25 }),
  lote('c3', 'u-joao', { tipo: 'Arábica', classificacao: 'Tipo 6', bebida: 'Apenas Mole', peneira: '16/18', safra: '2025/2026', regiao: 'Cerrado Mineiro', cidade: 'Patrocínio', fazenda: 'Fazenda Chapadão', quantidade_sacas: 400, preco_saca: 2120, score: 83, criado_em: dias(3), lat: -18.94, lng: -46.99 }),
  lote('c4', 'u-rosa', { tipo: 'Arábica', classificacao: 'Tipo 7', bebida: 'Dura', peneira: '15/16', safra: '2025/2026', regiao: 'Matas de Minas', cidade: 'Manhuaçu', fazenda: 'Fazenda Serra Verde', quantidade_sacas: 150, preco_saca: 1890, score: 79, criado_em: dias(4), lat: -20.26, lng: -42.03 }),
  lote('c5', 'u-edu', { tipo: 'Conilon', classificacao: 'Tipo 7', bebida: null, peneira: '13/15', safra: '2025/2026', regiao: 'Espírito Santo', cidade: 'Vila Valério', fazenda: 'Sítio Recanto', quantidade_sacas: 600, preco_saca: 1310, score: 80, criado_em: dias(5), lat: -18.99, lng: -40.38 }),
  lote('c6', 'u-luiz', { tipo: 'Arábica', classificacao: 'Tipo 6', bebida: 'Mole', peneira: '17/18', safra: '2025/2026', regiao: 'Outro', cidade: 'Franca', fazenda: 'Fazenda Alta Mogiana', quantidade_sacas: 120, preco_saca: 2240, score: 84, criado_em: dias(6), lat: -20.54, lng: -47.4 }),
  lote('c7', 'u-demo', { tipo: 'Arábica', classificacao: 'Especial', bebida: 'Mole', peneira: '16/18', safra: '2025/2026', regiao: 'Sul de Minas', cidade: 'Varginha', fazenda: 'Fazenda Recanto do Café', quantidade_sacas: 60, preco_saca: 2540, score: 86, criado_em: dias(8), lat: -21.55, lng: -45.43 }),
  lote('c8', 'u-joao', { tipo: 'Arábica', classificacao: 'Tipo 7', bebida: 'Riada', peneira: '14/16', safra: '2025/2026', regiao: 'Cerrado Mineiro', cidade: 'Araguari', fazenda: 'Fazenda Três Barras', quantidade_sacas: 300, preco_saca: 1840, score: 77, criado_em: dias(9), lat: -18.65, lng: -48.19 }),
];

export const MEUS_EXTRA = [
  lote('c9', 'u-demo', { tipo: 'Arábica', classificacao: 'Tipo 6', bebida: 'Dura', peneira: '16/18', safra: '2024/2025', regiao: 'Sul de Minas', cidade: 'Três Corações', fazenda: 'Sítio Boa Vista', quantidade_sacas: 180, preco_saca: 1980, score: 80, status: 'vendido', preco_venda: 2010, vendido_em: dias(12), criado_em: dias(40) }),
  lote('c10', 'u-demo', { tipo: 'Arábica', classificacao: 'Tipo 7', bebida: 'Riada', peneira: '15/16', safra: '2025/2026', regiao: 'Sul de Minas', cidade: 'Varginha', fazenda: 'Fazenda Recanto do Café', quantidade_sacas: 90, preco_saca: 1870, score: 78, status: 'pausado', criado_em: dias(15) }),
];

// Índice com a mesma regra do backend (média ponderada pelas sacas)
export function indice() {
  const ativos = LOTES;
  const grupo = (f) => {
    const m = new Map();
    for (const l of ativos) { const k = f(l); if (!m.has(k)) m.set(k, []); m.get(k).push(l); }
    return m;
  };
  const resumo = (ls) => {
    const sacas = ls.reduce((s, l) => s + l.quantidade_sacas, 0);
    const media = ls.reduce((s, l) => s + l.preco_saca * l.quantidade_sacas, 0) / sacas;
    return { preco_medio: Math.round(media * 100) / 100, preco_min: Math.min(...ls.map((l) => l.preco_saca)), preco_max: Math.max(...ls.map((l) => l.preco_saca)), quantidade: ls.length, sacas };
  };
  const por_tipo = [...grupo((l) => l.tipo)].map(([tipo, ls]) => ({ tipo, ...resumo(ls) })).sort((a, b) => b.sacas - a.sacas);
  const ofertas = [...grupo((l) => `${l.tipo}|${l.regiao}`)].map(([k, ls]) => { const [tipo, regiao] = k.split('|'); return { tipo, regiao, ...resumo(ls) }; }).sort((a, b) => b.sacas - a.sacas);
  return {
    atualizado_em: hoje.toISOString(), fonte: 'Café Conecta', total_lotes: ativos.length,
    total_sacas: ativos.reduce((s, l) => s + l.quantidade_sacas, 0), por_tipo, ofertas,
    negocios: [{ tipo: 'Arábica', preco_medio: 2085.4, preco_min: 1950, preco_max: 2300, quantidade: 7, sacas: 1240 }],
    total_negocios: 7, dias_negocios: 90, min_negocios: 3,
  };
}

export function historico() {
  const base = { 'Sul de Minas': 1980, 'Cerrado Mineiro': 2040, 'Zona da Mata': 1860 };
  const desvio = [0, 35, -20, 60, 95, 70];
  const out = [];
  for (let m = 5; m >= 0; m--) {
    const d = new Date(hoje.getFullYear(), hoje.getMonth() - m, 1);
    const mes = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
    for (const [regiao, b] of Object.entries(base)) {
      out.push({ id: null, tipo_cafe: 'Arábica', regiao, mes, preco_medio: b + desvio[5 - m] + (regiao === 'Zona da Mata' ? -15 * (5 - m) : 0), lotes: 4 });
    }
  }
  return out;
}

export const DASHBOARD = {
  lotes_ativos: 2, lotes_total: 4, visualizacoes: 148, propostas_recebidas: 9,
  negocios_fechados: 3, propostas_pendentes: 2, propostas_aceitas: 3,
  mensagens_nao_lidas: 2, media_avaliacao: 4.8, total_avaliacoes: 12,
};

const prop = (id, de, para, cafe, o) => {
  const c = [...LOTES, ...MEUS_EXTRA].find((l) => l.id === cafe);
  return {
    id, de_usuario_id: de, para_usuario_id: para, cafe_id: cafe,
    remetente_nome: pessoas[de].nome, remetente_empresa: null,
    cafe_tipo: c.tipo, cafe_classificacao: c.classificacao, cafe_fazenda: c.fazenda,
    condicao_pagamento: '30 dias', prazo_entrega: '15 dias', local_entrega: c.cidade, ...o,
  };
};

export const PROPOSTAS = [
  prop('p1', 'u-luiz', 'u-demo', 'c2', { quantidade_sacas: 100, preco_ofertado: 2010, status: 'aguardando', status_app: 'aguardando', observacoes: 'Retiro na fazenda. Pagamento em 30 dias.', criado_em: dias(0.2) }),
  prop('p2', 'u-demo', 'u-ana', 'c1', { quantidade_sacas: 40, preco_ofertado: 2600, status: 'contraproposta', status_app: 'contraproposta', observacoes: 'Interesse no lote todo se fecharmos a 2.600.', criado_em: dias(1) }),
  prop('p3', 'u-joao', 'u-demo', 'c7', { quantidade_sacas: 60, preco_ofertado: 2500, status: 'aceita', status_app: 'aceita', condicao_pagamento: 'À vista', observacoes: null, criado_em: dias(3) }),
  prop('p4', 'u-demo', 'u-rosa', 'c4', { quantidade_sacas: 150, preco_ofertado: 1820, status: 'recusada', status_app: 'recusada', observacoes: null, criado_em: dias(6) }),
];

export const CONVERSAS = [
  { contato_id: 'u-ana', contato_nome: 'Ana Paula Moreira', contato_empresa: 'Fazenda Santa Helena', contato_verificado: true, ultima_mensagem: 'Posso mandar a amostra na segunda.', de_usuario_id: 'u-ana', lida: false, criado_em: dias(0.05) },
  { contato_id: 'u-luiz', contato_nome: 'Luiz Fernando Costa', contato_empresa: null, contato_verificado: false, ultima_mensagem: 'Fechado, aguardo a nota.', de_usuario_id: 'u-luiz', lida: false, criado_em: dias(0.3) },
  { contato_id: 'u-joao', contato_nome: 'João Batista Ribeiro', contato_empresa: 'Fazenda Chapadão', contato_verificado: true, ultima_mensagem: 'Obrigado pela negociação!', de_usuario_id: 'u-demo', lida: true, criado_em: dias(2) },
];

const msg = (id, de, para, texto, h) => ({ id, de_usuario_id: de, para_usuario_id: para, remetente_id: de, destinatario_id: para, texto, conteudo: texto, lida: true, criado_em: new Date(hoje.getTime() - h * 3600000).toISOString() });
export const MENSAGENS = {
  'u-ana': [
    msg('m1', 'u-demo', 'u-ana', 'Olá, Ana! Vi o lote especial da Fazenda Santa Helena. Ainda está disponível?', 5),
    msg('m2', 'u-ana', 'u-demo', 'Olá, Marco! Está sim, são 80 sacas, peneira 17/18, bebida estritamente mole.', 4.6),
    msg('m3', 'u-demo', 'u-ana', 'Ótimo. Tenho um comprador de café especial em Varginha. Consegue enviar uma amostra?', 4.2),
    msg('m4', 'u-ana', 'u-demo', 'Posso mandar a amostra na segunda.', 1.2),
  ],
};

export const ALERTAS = [
  { id: 'a1', usuario_id: 'u-demo', tipo_cafe: 'Arábica', regiao: 'Sul de Minas', preco_maximo: 2100, ativo: true, criado_em: dias(20) },
  { id: 'a2', usuario_id: 'u-demo', tipo_cafe: 'Conilon', regiao: 'Espírito Santo', preco_maximo: 1350, ativo: true, criado_em: dias(10) },
];
