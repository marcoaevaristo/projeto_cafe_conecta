#!/usr/bin/env python3
"""Gera web/privacidade.html e web/termos.html a partir de lib/utils/textos_legais.dart.
Rode de novo sempre que mudar os textos:  python3 tool/gerar_paginas_legais.py"""
import html, re, pathlib

raiz = pathlib.Path(__file__).resolve().parent.parent
dart = (raiz / 'lib/utils/textos_legais.dart').read_text(encoding='utf-8')
consts = dict(re.findall(r"const (\w+) = '([^']*)';", dart))

def troca(t):
    return re.sub(r'\$(\w+)', lambda m: consts.get(m.group(1), m.group(0)), t).replace("\\'", "'")

def secoes(nome):
    bloco = dart.split(f'const List<SecaoLegal> {nome} = [', 1)[1].split('\n];', 1)[0]
    out = []
    for titulo, corpo in re.findall(r"\(titulo: '((?:[^'\\]|\\.)*)', paragrafos: \[(.*?)\]\)", bloco, re.S):
        paras = re.findall(r"'((?:[^'\\]|\\.)*)'", corpo)
        out.append((troca(titulo), [troca(p) for p in paras]))
    return out

CSS = """:root{--bg:#FDF6EC;--fg:#2C1A0E;--muted:#8B5E3C;--accent:#C4863A;--card:#fff}
@media (prefers-color-scheme:dark){:root{--bg:#1A0F08;--fg:#F5EAD8;--muted:#D4B48C;--accent:#D4A843;--card:#2C1A0E}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.6 system-ui,-apple-system,"Segoe UI",sans-serif}
header{background:#2C1A0E;color:#D4A843;padding:18px max(16px,env(safe-area-inset-left))}
header a{color:#D4A843;text-decoration:none;font-weight:700;font-size:20px}
main{max-width:760px;margin:0 auto;padding:24px max(16px,env(safe-area-inset-left)) 48px}
h1{font-size:28px;margin:0 0 4px;text-wrap:balance}.data{color:var(--muted);margin:0 0 24px}
h2{font-size:18px;margin:28px 0 8px;color:var(--fg)}p{margin:0 0 10px}
nav{margin-top:32px;padding-top:16px;border-top:1px solid var(--accent)}nav a{color:var(--accent);margin-right:16px}"""

def pagina(arquivo, titulo, nome, outro):
    corpo = ''.join(f'<h2>{html.escape(t)}</h2>' + ''.join(f'<p>{html.escape(p)}</p>' for p in ps) for t, ps in secoes(nome))
    doc = f"""<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{titulo} · Café Conecta</title><meta name="description" content="{titulo} do Café Conecta, marketplace de café.">
<style>{CSS}</style></head><body>
<header><a href="/">☕ Café Conecta</a></header>
<main><h1>{titulo}</h1><p class="data">Versão de {consts['dataTermos']}</p>{corpo}
<nav><a href="/">Abrir o app</a><a href="{outro[1]}">{outro[0]}</a></nav></main>
</body></html>
"""
    (raiz / 'web' / arquivo).write_text(doc, encoding='utf-8')
    print(arquivo, len(secoes(nome)), 'seções')

pagina('privacidade.html', 'Política de privacidade', 'politicaDePrivacidade', ('Termos de uso', '/termos.html'))
pagina('termos.html', 'Termos de uso', 'termosDeUso', ('Política de privacidade', '/privacidade.html'))
