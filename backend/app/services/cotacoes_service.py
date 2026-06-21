from datetime import date, datetime, timedelta

from sqlalchemy import desc, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from app.models import CotacaoB3, CotacaoCepea, CotacaoDolar, CotacaoNoticias, ScraperLog
from app.schemas import (
    B3Item,
    CotacaoItem,
    CotacoesAtualResponse,
    DolarItem,
    HistoricoPonto,
    HistoricoResponse,
)
from app.scrapers.bcb_dolar import fetch_dolar_bcb
from app.scrapers.cepea import fetch_cepea
from app.scrapers.investing_b3 import fetch_investing_futuros
from app.scrapers.noticias_agricolas import fetch_noticias_agricolas


def _log_scraper(db: Session, fonte: str, status: str, msg: str, count: int = 0):
    db.add(
        ScraperLog(
            fonte=fonte,
            status=status,
            mensagem=msg,
            registros_inseridos=count,
        )
    )


async def run_all_scrapers(db: Session) -> dict[str, int]:
    totals: dict[str, int] = {}

    # CEPEA
    try:
        quotes = await fetch_cepea()
        count = 0
        for q in quotes:
            stmt = insert(CotacaoCepea).values(
                tipo=q.tipo,
                preco=q.preco,
                unidade=q.unidade,
                data_referencia=q.data_referencia,
                variacao_pct=q.variacao_pct,
                fonte="CEPEA/ESALQ",
            ).on_conflict_do_update(
                index_elements=["tipo", "data_referencia"],
                set_={
                    "preco": q.preco,
                    "variacao_pct": q.variacao_pct,
                    "created_at": datetime.utcnow(),
                },
            )
            db.execute(stmt)
            count += 1
        db.commit()
        _log_scraper(db, "cepea", "ok", f"{count} cotações CEPEA", count)
        totals["cepea"] = count
    except Exception as exc:
        db.rollback()
        _log_scraper(db, "cepea", "erro", str(exc))
        totals["cepea"] = 0

    # Notícias Agrícolas
    try:
        quotes = await fetch_noticias_agricolas()
        count = 0
        for q in quotes:
            stmt = insert(CotacaoNoticias).values(
                tipo=q.tipo,
                preco=q.preco,
                unidade=q.unidade,
                data_referencia=q.data_referencia,
                variacao_pct=q.variacao_pct,
                fonte="Notícias Agrícolas",
            ).on_conflict_do_update(
                index_elements=["tipo", "data_referencia"],
                set_={
                    "preco": q.preco,
                    "variacao_pct": q.variacao_pct,
                    "created_at": datetime.utcnow(),
                },
            )
            db.execute(stmt)
            count += 1
        db.commit()
        _log_scraper(db, "noticias", "ok", f"{count} cotações Notícias Agrícolas", count)
        totals["noticias"] = count
    except Exception as exc:
        db.rollback()
        _log_scraper(db, "noticias", "erro", str(exc))
        totals["noticias"] = 0

    # Dólar BCB
    try:
        q = await fetch_dolar_bcb()
        stmt = insert(CotacaoDolar).values(
            cotacao_compra=q.cotacao_compra,
            cotacao_venda=q.cotacao_venda,
            data_referencia=q.data_referencia,
            fonte="Banco Central (PTAX)",
        ).on_conflict_do_update(
            index_elements=["data_referencia"],
            set_={
                "cotacao_compra": q.cotacao_compra,
                "cotacao_venda": q.cotacao_venda,
                "created_at": datetime.utcnow(),
            },
        )
        db.execute(stmt)
        db.commit()
        _log_scraper(db, "dolar", "ok", "PTAX atualizada", 1)
        totals["dolar"] = 1
    except Exception as exc:
        db.rollback()
        _log_scraper(db, "dolar", "erro", str(exc))
        totals["dolar"] = 0

    # Investing / B3 futuros
    try:
        quotes = await fetch_investing_futuros()
        count = 0
        for q in quotes:
            stmt = insert(CotacaoB3).values(
                contrato=q.contrato,
                simbolo=q.simbolo,
                preco=q.preco,
                variacao_pct=q.variacao_pct,
                moeda=q.moeda,
                data_referencia=q.data_referencia,
                fonte="Investing.com",
            ).on_conflict_do_update(
                index_elements=["contrato", "data_referencia"],
                set_={
                    "preco": q.preco,
                    "variacao_pct": q.variacao_pct,
                    "created_at": datetime.utcnow(),
                },
            )
            db.execute(stmt)
            count += 1
        db.commit()
        _log_scraper(db, "b3", "ok", f"{count} futuros", count)
        totals["b3"] = count
    except Exception as exc:
        db.rollback()
        _log_scraper(db, "b3", "erro", str(exc))
        totals["b3"] = 0

    db.commit()
    return totals


def get_cotacoes_atual(db: Session) -> CotacoesAtualResponse:
    cepea_rows = db.scalars(
        select(CotacaoCepea).order_by(desc(CotacaoCepea.data_referencia)).limit(10)
    ).all()
    cepea_latest: dict[str, CotacaoCepea] = {}
    for row in cepea_rows:
        if row.tipo not in cepea_latest:
            cepea_latest[row.tipo] = row

    noticias_rows = db.scalars(
        select(CotacaoNoticias).order_by(desc(CotacaoNoticias.data_referencia)).limit(10)
    ).all()
    noticias_latest: dict[str, CotacaoNoticias] = {}
    for row in noticias_rows:
        if row.tipo not in noticias_latest:
            noticias_latest[row.tipo] = row

    dolar = db.scalar(select(CotacaoDolar).order_by(desc(CotacaoDolar.data_referencia)).limit(1))

    b3_rows = db.scalars(
        select(CotacaoB3).order_by(desc(CotacaoB3.data_referencia)).limit(10)
    ).all()
    b3_latest: dict[str, CotacaoB3] = {}
    for row in b3_rows:
        if row.contrato not in b3_latest:
            b3_latest[row.contrato] = row

    return CotacoesAtualResponse(
        atualizado_em=datetime.utcnow(),
        cepea=[
            CotacaoItem(
                tipo=r.tipo,
                preco=float(r.preco),
                unidade=r.unidade,
                data_referencia=r.data_referencia,
                variacao_pct=float(r.variacao_pct) if r.variacao_pct is not None else None,
                fonte=r.fonte,
            )
            for r in cepea_latest.values()
        ],
        noticias=[
            CotacaoItem(
                tipo=r.tipo,
                preco=float(r.preco),
                unidade=r.unidade,
                data_referencia=r.data_referencia,
                variacao_pct=float(r.variacao_pct) if r.variacao_pct is not None else None,
                fonte=r.fonte,
            )
            for r in noticias_latest.values()
        ],
        dolar=(
            DolarItem(
                cotacao_compra=float(dolar.cotacao_compra),
                cotacao_venda=float(dolar.cotacao_venda),
                data_referencia=dolar.data_referencia,
                fonte=dolar.fonte,
            )
            if dolar
            else None
        ),
        b3=[
            B3Item(
                contrato=r.contrato,
                simbolo=r.simbolo,
                preco=float(r.preco),
                variacao_pct=float(r.variacao_pct) if r.variacao_pct is not None else None,
                moeda=r.moeda,
                data_referencia=r.data_referencia,
                fonte=r.fonte,
            )
            for r in b3_latest.values()
        ],
    )


def get_historico(db: Session, fonte: str, tipo: str, dias: int = 30) -> HistoricoResponse:
    since = date.today() - timedelta(days=dias)
    pontos: list[HistoricoPonto] = []

    if fonte == "cepea":
        rows = db.scalars(
            select(CotacaoCepea)
            .where(CotacaoCepea.tipo == tipo, CotacaoCepea.data_referencia >= since)
            .order_by(CotacaoCepea.data_referencia)
        ).all()
        pontos = [
            HistoricoPonto(
                data=r.data_referencia,
                preco=float(r.preco),
                variacao_pct=float(r.variacao_pct) if r.variacao_pct is not None else None,
            )
            for r in rows
        ]
    elif fonte == "noticias":
        rows = db.scalars(
            select(CotacaoNoticias)
            .where(CotacaoNoticias.tipo.ilike(f"%{tipo}%"), CotacaoNoticias.data_referencia >= since)
            .order_by(CotacaoNoticias.data_referencia)
        ).all()
        pontos = [
            HistoricoPonto(
                data=r.data_referencia,
                preco=float(r.preco),
                variacao_pct=float(r.variacao_pct) if r.variacao_pct is not None else None,
            )
            for r in rows
        ]
    elif fonte == "b3":
        rows = db.scalars(
            select(CotacaoB3)
            .where(CotacaoB3.contrato.ilike(f"%{tipo}%"), CotacaoB3.data_referencia >= since)
            .order_by(CotacaoB3.data_referencia)
        ).all()
        pontos = [
            HistoricoPonto(
                data=r.data_referencia,
                preco=float(r.preco),
                variacao_pct=float(r.variacao_pct) if r.variacao_pct is not None else None,
            )
            for r in rows
        ]
    elif fonte == "dolar":
        rows = db.scalars(
            select(CotacaoDolar)
            .where(CotacaoDolar.data_referencia >= since)
            .order_by(CotacaoDolar.data_referencia)
        ).all()
        pontos = [
            HistoricoPonto(
                data=r.data_referencia,
                preco=float(r.cotacao_venda),
                variacao_pct=None,
            )
            for r in rows
        ]

    return HistoricoResponse(fonte=fonte, tipo=tipo, pontos=pontos)
