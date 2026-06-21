from datetime import date, datetime

from pydantic import BaseModel, ConfigDict


class CotacaoItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    tipo: str
    preco: float
    unidade: str
    data_referencia: date
    variacao_pct: float | None = None
    fonte: str


class DolarItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    cotacao_compra: float
    cotacao_venda: float
    data_referencia: date
    fonte: str


class B3Item(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    contrato: str
    simbolo: str | None = None
    preco: float
    variacao_pct: float | None = None
    moeda: str
    data_referencia: date
    fonte: str


class HistoricoPonto(BaseModel):
    data: date
    preco: float
    variacao_pct: float | None = None


class CotacoesAtualResponse(BaseModel):
    atualizado_em: datetime
    cepea: list[CotacaoItem]
    noticias: list[CotacaoItem]
    dolar: DolarItem | None
    b3: list[B3Item]


class HistoricoResponse(BaseModel):
    fonte: str
    tipo: str
    pontos: list[HistoricoPonto]


class ScraperStatusResponse(BaseModel):
    ok: bool
    mensagem: str
    detalhes: dict[str, int]
