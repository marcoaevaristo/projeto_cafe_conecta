from dataclasses import dataclass
from datetime import date, datetime
import re

import httpx
from bs4 import BeautifulSoup

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "pt-BR,pt;q=0.9",
}


@dataclass
class CepeaQuote:
    tipo: str
    preco: float
    unidade: str
    data_referencia: date
    variacao_pct: float | None


def _parse_br_number(value: str) -> float:
    cleaned = value.strip().replace(".", "").replace(",", ".")
    cleaned = re.sub(r"[^\d.\-]", "", cleaned)
    return float(cleaned)


def _parse_br_date(value: str) -> date:
    value = value.strip()
    for fmt in ("%d/%m/%Y", "%d/%m/%y"):
        try:
            return datetime.strptime(value, fmt).date()
        except ValueError:
            continue
    raise ValueError(f"Data inválida: {value}")


async def fetch_cepea() -> list[CepeaQuote]:
    """Coleta indicadores CEPEA de Arábica e Conilon."""
    urls = {
        "arabica": "https://www.cepea.org.br/br/indicador/cafe.aspx",
        "conilon": "https://www.cepea.org.br/br/indicador/conilon.aspx",
    }
    results: list[CepeaQuote] = []

    async with httpx.AsyncClient(timeout=30, follow_redirects=True, headers=HEADERS) as client:
        for tipo, url in urls.items():
            resp = await client.get(url)
            resp.raise_for_status()
            soup = BeautifulSoup(resp.text, "lxml")

            preco = None
            data_ref = date.today()
            variacao = None

            # Tabela principal do indicador
            for row in soup.select("table tr"):
                cells = [c.get_text(strip=True) for c in row.find_all(["td", "th"])]
                if len(cells) < 2:
                    continue
                label = cells[0].lower()
                if "valor" in label or "médio" in label or "preco" in label or "preço" in label:
                    try:
                        preco = _parse_br_number(cells[1])
                    except ValueError:
                        continue
                if "data" in label:
                    try:
                        data_ref = _parse_br_date(cells[1])
                    except ValueError:
                        pass
                if "varia" in label:
                    try:
                        variacao = _parse_br_number(cells[1].replace("%", ""))
                    except ValueError:
                        pass

            # Fallback: valor destacado na página
            if preco is None:
                valor_el = soup.select_one(".indicador-valor, .valor-indicador, #lblValor")
                if valor_el:
                    preco = _parse_br_number(valor_el.get_text())

            if preco is None:
                raise ValueError(f"Não foi possível extrair preço CEPEA ({tipo})")

            results.append(
                CepeaQuote(
                    tipo=tipo,
                    preco=preco,
                    unidade="saca 60kg",
                    data_referencia=data_ref,
                    variacao_pct=variacao,
                )
            )

    return results
