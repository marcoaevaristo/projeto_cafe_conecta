from datetime import date, datetime

from sqlalchemy import Date, DateTime, Integer, Numeric, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class CotacaoCepea(Base):
    __tablename__ = "cotacoes_cepea"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tipo: Mapped[str] = mapped_column(String(20), nullable=False)
    preco: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    unidade: Mapped[str] = mapped_column(String(60), nullable=False)
    data_referencia: Mapped[date] = mapped_column(Date, nullable=False)
    variacao_pct: Mapped[float | None] = mapped_column(Numeric(8, 3))
    fonte: Mapped[str] = mapped_column(String(80), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class CotacaoNoticias(Base):
    __tablename__ = "cotacoes_noticias"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tipo: Mapped[str] = mapped_column(String(40), nullable=False)
    preco: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    unidade: Mapped[str] = mapped_column(String(60), nullable=False)
    data_referencia: Mapped[date] = mapped_column(Date, nullable=False)
    variacao_pct: Mapped[float | None] = mapped_column(Numeric(8, 3))
    fonte: Mapped[str] = mapped_column(String(100), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class CotacaoDolar(Base):
    __tablename__ = "cotacoes_dolar"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    cotacao_compra: Mapped[float] = mapped_column(Numeric(12, 4), nullable=False)
    cotacao_venda: Mapped[float] = mapped_column(Numeric(12, 4), nullable=False)
    data_referencia: Mapped[date] = mapped_column(Date, unique=True, nullable=False)
    fonte: Mapped[str] = mapped_column(String(80), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class CotacaoB3(Base):
    __tablename__ = "cotacoes_b3"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    contrato: Mapped[str] = mapped_column(String(80), nullable=False)
    simbolo: Mapped[str | None] = mapped_column(String(20))
    preco: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    variacao_pct: Mapped[float | None] = mapped_column(Numeric(8, 3))
    moeda: Mapped[str] = mapped_column(String(10), nullable=False)
    data_referencia: Mapped[date] = mapped_column(Date, nullable=False)
    fonte: Mapped[str] = mapped_column(String(80), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class ScraperLog(Base):
    __tablename__ = "scraper_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    fonte: Mapped[str] = mapped_column(String(40), nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False)
    mensagem: Mapped[str | None] = mapped_column(Text)
    registros_inseridos: Mapped[int] = mapped_column(Integer, default=0)
    executado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
