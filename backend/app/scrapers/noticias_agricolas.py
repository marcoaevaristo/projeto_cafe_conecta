from dataclasses import dataclass
from datetime import date, datetime
import re

import httpx
from bs4 import BeautifulSoup

from app.scrapers.cepea import HEADERS, _parse_br_date, _parse_br_number


@dataclass
class NoticiasQuote:
    tipo: str
    preco: float
    unidade: str
    data_referencia: date
    variacao_pct: float | None


async def fetch_noticias_agricolas() -> list[NoticiasQuote]:
    """Coleta preços físicos de café em Notícias Agrícolas."""
    url = "https://www.noticiasagricolas.com.br/cotacoes/cafe"
    results: list[NoticiasQuote] = []

    async with httpx.AsyncClient(timeout=30, follow_redirects=True, headers=HEADERS) as client:
        resp = await client.get(url)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "lxml")

        for row in soup.select("table tbody tr, .cotacao-item, .table-cotacao tr"):
            cells = [c.get_text(" ", strip=True) for c in row.find_all(["td", "th"])]
            if len(cells) < 2:
                continue

            texto = " ".join(cells).lower()
            if "café" not in texto and "cafe" not in texto:
                continue

            tipo = cells[0]
            preco_txt = cells[1] if len(cells) > 1 else cells[-1]
            try:
                preco = _parse_br_number(re.search(r"[\d.,]+", preco_txt).group())
            except (ValueError, AttributeError):
                continue

            data_ref = date.today()
            variacao = None
            for cell in cells[2:]:
                if re.search(r"\d{2}/\d{2}/\d{4}", cell):
                    try:
                        data_ref = _parse_br_date(re.search(r"\d{2}/\d{2}/\d{4}", cell).group())
                    except ValueError:
                        pass
                if "%" in cell:
                    try:
                        variacao = _parse_br_number(cell.replace("%", ""))
                    except ValueError:
                        pass

            tipo_norm = tipo.strip()
            if not tipo_norm:
                tipo_norm = "Café Arábica"

            results.append(
                NoticiasQuote(
                    tipo=tipo_norm,
                    preco=preco,
                    unidade="saca 60kg",
                    data_referencia=data_ref,
                    variacao_pct=variacao,
                )
            )

        if not results:
            # Fallback: página de cotações geral
            resp2 = await client.get("https://www.noticiasagricolas.com.br/cotacoes")
            soup2 = BeautifulSoup(resp2.text, "lxml")
            for el in soup2.find_all(string=re.compile(r"caf[eé]", re.I)):
                parent = el.find_parent(["tr", "div", "li"])
                if not parent:
                    continue
                text = parent.get_text(" ", strip=True)
                match = re.search(r"([\d.]+,\d{2})", text)
                if match:
                    results.append(
                        NoticiasQuote(
                            tipo="Café Arábica (físico)",
                            preco=_parse_br_number(match.group(1)),
                            unidade="saca 60kg",
                            data_referencia=date.today(),
                            variacao_pct=None,
                        )
                    )
                    break

    if not results:
        raise ValueError("Não foi possível extrair cotações de Notícias Agrícolas")

    return results[:5]
