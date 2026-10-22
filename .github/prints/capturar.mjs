// Prints de divulgação do Café Conecta: abre o app publicado, responde às chamadas
// do backend com DADOS DE EXEMPLO (dados.mjs) e fotografa as telas.
import { chromium } from 'playwright';
import fs from 'node:fs';
import * as D from './dados.mjs';

const APP = process.env.APP_URL || 'https://cafe-conecta-flutter.vercel.app/';
const API = 'https://cafe-conecta-backend.vercel.app';
const OUT = process.env.OUT_DIR || 'prints';
fs.mkdirSync(OUT, { recursive: true });
const log = [];

function respostaApi(metodo, caminho) {
  const p = caminho.replace(/\/+$/, '');
  if (metodo !== 'GET') return { ok: true };
  if (p === '/auth/me') return D.EU;
  if (p === '/dashboard') return D.DASHBOARD;
  if (p === '/historico-precos') return D.historico();
  if (p === '/api/cotacoes/indice') return D.indice();
  if (p === '/api/cotacoes/historico') return { pontos: [] };
  if (p === '/cafes') return null; // tratado com query string
  let m;
  if ((m = p.match(/^\/cafes\/([^/]+)$/))) return [...D.LOTES, ...D.MEUS_EXTRA].find((l) => l.id === m[1]) || {};
  if (p === '/propostas') return D.PROPOSTAS;
  if (p === '/mensagens/conversas') return D.CONVERSAS;
  if (p === '/mensagens/nao-lidas') return { total: 2, count: 2 };
  if ((m = p.match(/^\/mensagens\/([^/]+)$/))) return D.MENSAGENS[m[1]] || [];
  if (p === '/favoritos') return [D.LOTES[0], D.LOTES[2]];
  if (p.startsWith('/favoritos/')) return { favorito: false, is_favorito: false };
  if (p === '/alertas') return D.ALERTAS;
  if (p.match(/^\/avaliacoes\/[^/]+\/resumo$/)) return { media: 4.8, total: 12 };
  if (p.startsWith('/avaliacoes/ja-avaliou')) return { ja_avaliou: true };
  if (p.startsWith('/avaliacoes')) return [];
  return [];
}

function listaCafes(params) {
  const usuario = params.get('usuario_id');
  const status = params.get('status');
  if (usuario) {
    return [...D.LOTES, ...D.MEUS_EXTRA].filter((l) => l.usuario_id === usuario && (!status || l.status === status));
  }
  let l = D.LOTES.filter((c) => c.status === 'ativo');
  if (params.get('tipo')) l = l.filter((c) => c.tipo === params.get('tipo'));
  return [...l].sort((a, b) => Number(b.destaque) - Number(a.destaque));
}

async function novaPagina(browser, { largura, altura, escala, logado = true }) {
  const ctx = await browser.newContext({
    viewport: { width: largura, height: altura }, deviceScaleFactor: escala,
    locale: 'pt-BR', timezoneId: 'America/Sao_Paulo',
    isMobile: largura < 600, hasTouch: largura < 600,
  });
  if (logado) {
    await ctx.addInitScript(() => {
      localStorage.setItem('flutter.jwt_token', JSON.stringify('token-de-demonstracao'));
    });
  }
  await ctx.route(`${API}/**`, async (route) => {
    const req = route.request();
    const url = new URL(req.url());
    if (req.method() === 'OPTIONS') return route.fulfill({ status: 204, headers: cors() });
    // Dólar PTAX: usa o valor real do Banco Central
    if (url.pathname === '/api/cotacoes/atual') {
      try {
        const r = await route.fetch();
        return route.fulfill({ response: r, headers: { ...r.headers(), ...cors() } });
      } catch { /* cai no vazio */ }
    }
    if (!logado && url.pathname === '/auth/me') {
      return route.fulfill({ status: 401, headers: cors(), contentType: 'application/json', body: '{"error":"Token não fornecido"}' });
    }
    const corpo = url.pathname === '/cafes' ? listaCafes(url.searchParams) : respostaApi(req.method(), url.pathname);
    log.push(`${req.method()} ${url.pathname}${url.search}`);
    return route.fulfill({ status: 200, headers: cors(), contentType: 'application/json', body: JSON.stringify(corpo) });
  });
  const page = await ctx.newPage();
  page.on('pageerror', (e) => log.push('ERRO PÁGINA: ' + e.message));
  return page;
}

const cors = () => ({
  'access-control-allow-origin': '*',
  'access-control-allow-headers': '*',
  'access-control-allow-methods': 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
});

const espera = (ms) => new Promise((r) => setTimeout(r, ms));

async function abrir(page) {
  await page.goto(APP, { waitUntil: 'networkidle', timeout: 90000 });
  await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 60000 });
  await espera(5000);
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await espera(1500);
}

// Clica no elemento de acessibilidade do Flutter cujo rótulo começa com `texto`
async function clicar(page, texto, { exato = false } = {}) {
  const ok = await page.evaluate(({ texto, exato }) => {
    const nos = [...document.querySelectorAll('flt-semantics')].filter((e) => {
      const r = e.getBoundingClientRect();
      if (r.width === 0 || r.height === 0) return false;
      const rot = (e.getAttribute('aria-label') || e.innerText || '').trim();
      return exato ? rot === texto : rot.startsWith(texto);
    });
    if (!nos.length) return false;
    // o menor (mais específico) primeiro
    nos.sort((a, b) => a.getBoundingClientRect().width * a.getBoundingClientRect().height
      - b.getBoundingClientRect().width * b.getBoundingClientRect().height);
    nos[0].click();
    return true;
  }, { texto, exato });
  log.push(`clicar "${texto}": ${ok ? 'ok' : 'NÃO ENCONTRADO'}`);
  await espera(2500);
  return ok;
}

async function rolar(page, px) {
  const v = page.viewportSize();
  await page.mouse.move(v.width / 2, v.height / 2);
  await page.mouse.wheel(0, px);
  await espera(1500);
}

async function foto(page, nome) {
  await page.screenshot({ path: `${OUT}/${nome}.png` });
  log.push(`foto ${nome}`);
}

const MOBILE = { largura: 390, altura: 844, escala: 3 };
const DESKTOP = { largura: 1440, altura: 900, escala: 2 };

// Cada roteiro começa do zero (app recém-aberto)
const roteiros = [
  ['01-login', MOBILE, false, async () => {}],
  ['02-inicio', MOBILE, true, async () => {}],
  ['03-catalogo', MOBILE, true, async (p) => { await clicar(p, 'Catálogo'); }],
  ['04-detalhes-lote', MOBILE, true, async (p) => { await clicar(p, 'Catálogo'); await clicar(p, 'Detalhes'); }],
  ['05-cotacoes-indice', MOBILE, true, async (p) => { await clicar(p, 'Menu'); await clicar(p, 'Cotações'); await espera(6000); }],
  ['06-cotacoes-bolsa', MOBILE, true, async (p) => { await clicar(p, 'Menu'); await clicar(p, 'Cotações'); await espera(4000); await rolar(p, 900); await espera(8000); }],
  ['07-propostas', MOBILE, true, async (p) => { await clicar(p, 'Propostas'); }],
  ['08-mensagens', MOBILE, true, async (p) => { await clicar(p, 'Mensagens'); }],
  ['09-conversa', MOBILE, true, async (p) => { await clicar(p, 'Mensagens'); await clicar(p, 'Ana Paula'); }],
  ['10-meus-anuncios', MOBILE, true, async (p) => { await clicar(p, 'Menu'); await clicar(p, 'Meus anúncios'); await espera(2000); }],
  ['11-classificacao-ia', MOBILE, true, async (p) => { await clicar(p, 'Menu'); await clicar(p, 'Classificação por IA'); }],
  ['12-historico-precos', MOBILE, true, async (p) => { await clicar(p, 'Menu'); await clicar(p, 'Histórico de preços'); await espera(2000); }],
  ['13-mapa', MOBILE, true, async (p) => { await clicar(p, 'Menu'); await clicar(p, 'Mapa de disponibilidade'); await espera(6000); }],
  ['14-alertas', MOBILE, true, async (p) => { await clicar(p, 'Menu'); await clicar(p, 'Alertas de preço'); }],
  ['15-planos', MOBILE, true, async (p) => { await clicar(p, 'Menu'); await clicar(p, 'Assinatura'); }],
  ['16-menu', MOBILE, true, async (p) => { await clicar(p, 'Menu'); }],
  ['20-desktop-inicio', DESKTOP, true, async () => {}],
  ['21-desktop-catalogo', DESKTOP, true, async (p) => { await clicar(p, 'Catálogo'); }],
  ['22-desktop-cotacoes', DESKTOP, true, async (p) => { await clicar(p, 'Cotações'); await espera(8000); }],
  ['23-desktop-mapa', DESKTOP, true, async (p) => { await clicar(p, 'Mapa de disponibilidade'); await espera(6000); }],
];

const browser = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader'] });
for (const [nome, tela, logado, passos] of roteiros) {
  if (process.env.SO && !process.env.SO.split(',').includes(nome)) continue;
  const page = await novaPagina(browser, { ...tela, logado });
  try {
    await abrir(page);
    await passos(page);
    await foto(page, nome);
    if (nome === '16-menu') {
      // guarda os rótulos visíveis para depuração da navegação
      const rot = await page.evaluate(() => [...document.querySelectorAll('flt-semantics')].map((e) => e.getAttribute('aria-label')).filter(Boolean));
      log.push('rótulos menu: ' + JSON.stringify(rot.slice(0, 60)));
    }
  } catch (e) {
    log.push(`FALHOU ${nome}: ${e.message}`);
  }
  await page.context().close();
}
await browser.close();
fs.writeFileSync(`${OUT}/log.txt`, log.join('\n'));
console.log(log.join('\n'));
