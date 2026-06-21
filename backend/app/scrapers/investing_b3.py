from dataclasses import dataclass
from datetime import date
import json
import re

import httpx

from app.scrapers.cepea import HEADERS, _parse_br_number


@dataclass
class B3Quote:
    contrato: str
    simbolo: str | None
    preco: float
    variacao_pct: float | None
    moeda: str
    data_referencia: date


async def fetch_investing_futuros() -> list[B3Quote]:
    """Coleta futuros de café via widget/página Investing.com."""
    targets = [
        {
            "contrato": "Café Arábica (ICE)",
            "simbolo": "KC",
            "url": "https://br.investing.com/commodities/us-coffee-c",
            "moeda": "USD",
        },
        {
            "contrato": "Café Conilon (ICE)",
            "simbolo": "RC",
            "url": "https://br.investing.com/commodities/london-coffee",
            "moeda": "USD",
        },
    ]
    results: list[B3Quote] = []

    async with httpx.AsyncClient(timeout=30, follow_redirects=True, headers=HEADERS) as client:
        for item in targets:
            resp = await client.get(item["url"])
            resp.raise_for_status()
            html = resp.text

            preco = None
            variacao = None

            # JSON embutido no widget
            for match in re.finditer(r'"last_last"\s*:\s*"([\d.,]+)"', html):
                try:
                    preco = _parse_br_number(match.group(1))
                    break
                except ValueError:
                    continue

            for match in re.finditer(r'"pcp"\s*:\s*"([+-]?[\d.,]+)"', html):
                try:
                    variacao = _parse_br_number(match.group(1))
                    break
                except ValueError:
                    continue

            if preco is None:
                # Fallback: data-test last-value
                m = re.search(r'data-test="instrument-price-last"[^>]*>([\d.,]+)<', html)
                if m:
                    preco = _parse_br_number(m.group(1))

            if preco is None:
                # Fallback: script __NEXT_DATA__
                nd = re.search(r'<script id="__NEXT_DATA__"[^>]*>(.*?)</script>', html, re.S)
                if nd:
                    try:
                        data = json.loads(nd.group(1))
                        text = json.dumps(data)
                        m2 = re.search(r'"last"\s*:\s*"([\d.,]+)"', text)
                        if m2:
                            preco = _parse_br_number(m2.group(1))
                    except json.JSONDecodeError:
                        pass

            if preco is None:
                raise ValueError(f"Preço não encontrado para {item['contrato']}")

            results.append(
                B3Quote(
                    contrato=item["contrato"],
                    simbolo=item["simbolo"],
                    preco=preco,
                    variacao_pct=variacao,
                    moeda=item["moeda"],
                    data_referencia=date.today(),
                )
            )

    return results
