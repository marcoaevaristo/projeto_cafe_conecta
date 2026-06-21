from contextlib import asynccontextmanager

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from app.config import settings
from app.database import SessionLocal, get_db
from app.schemas import CotacoesAtualResponse, HistoricoResponse, ScraperStatusResponse
from app.services.cotacoes_service import get_cotacoes_atual, get_historico, run_all_scrapers

scheduler = AsyncIOScheduler()


async def _scheduled_scrape():
    db = SessionLocal()
    try:
        await run_all_scrapers(db)
    finally:
        db.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    scheduler.add_job(
        _scheduled_scrape,
        "interval",
        hours=settings.scraper_interval_hours,
        id="scraper_job",
        replace_existing=True,
    )
    scheduler.start()
    # Primeira coleta na subida
    db = SessionLocal()
    try:
        await run_all_scrapers(db)
    finally:
        db.close()
    yield
    scheduler.shutdown()


app = FastAPI(
    title="Café Conecta — API de Cotações",
    version="1.0.0",
    lifespan=lifespan,
)

origins = [o.strip() for o in settings.cors_origins.split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins if origins != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok", "service": "cafe-conecta-cotacoes"}


@app.get("/api/cotacoes/atual", response_model=CotacoesAtualResponse)
def cotacoes_atual(db: Session = Depends(get_db)):
    return get_cotacoes_atual(db)


@app.get("/api/cotacoes/historico", response_model=HistoricoResponse)
def cotacoes_historico(
    fonte: str = "cepea",
    tipo: str = "arabica",
    dias: int = 30,
    db: Session = Depends(get_db),
):
    if fonte not in ("cepea", "noticias", "dolar", "b3"):
        raise HTTPException(400, "fonte inválida")
    return get_historico(db, fonte=fonte, tipo=tipo, dias=min(dias, 365))


@app.post("/api/cotacoes/atualizar", response_model=ScraperStatusResponse)
async def atualizar_cotacoes(
    db: Session = Depends(get_db),
    x_admin_token: str | None = Header(default=None),
):
    if x_admin_token != settings.admin_token:
        raise HTTPException(401, "Token admin inválido")
    totals = await run_all_scrapers(db)
    ok = any(v > 0 for v in totals.values())
    return ScraperStatusResponse(
        ok=ok,
        mensagem="Scrapers executados",
        detalhes=totals,
    )
