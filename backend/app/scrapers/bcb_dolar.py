from dataclasses import dataclass
from datetime import date, datetime, timedelta

import httpx


@dataclass
class DolarQuote:
    cotacao_compra: float
    cotacao_venda: float
    data_referencia: date


async def fetch_dolar_bcb(dia: date | None = None) -> DolarQuote:
    """Cotação PTAX do Banco Central (API Olinda gratuita)."""
    ref = dia or date.today()
    # BCB não publica PTAX em fins de semana — retrocede até achar dia útil
    for _ in range(7):
        data_param = ref.strftime("%m-%d-%Y")
        url = (
            "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/"
            f"CotacaoDolarDia(dataCotacao=@dataCotacao)?@dataCotacao='{data_param}'&$format=json"
        )
        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.get(url)
            resp.raise_for_status()
            payload = resp.json()
            values = payload.get("value", [])
            if values:
                # tipoBoletim 'Fechamento' preferencial
                fechamento = next(
                    (v for v in values if v.get("tipoBoletim") == "Fechamento"),
                    values[-1],
                )
                return DolarQuote(
                    cotacao_compra=float(fechamento["cotacaoCompra"]),
                    cotacao_venda=float(fechamento["cotacaoVenda"]),
                    data_referencia=ref,
                )
        ref -= timedelta(days=1)

    raise ValueError("PTAX indisponível nos últimos 7 dias")
