# Deploy — Café Conecta

## Arquitetura

```
Flutter App  ──HTTP──►  API Python (FastAPI)  ──►  PostgreSQL
                           │
                    Scrapers automáticos
                    (CEPEA, Notícias Agrícolas,
                     BCB PTAX, Investing)
```

## 1. Subir localmente com Docker

```bash
# Na raiz do projeto
docker compose up -d --build
```

Serviços:
- **API:** http://localhost:8000
- **Docs:** http://localhost:8000/docs
- **PostgreSQL:** localhost:5432 (user: `cafe`, senha: `cafe123`, db: `cafe_conecta`)

As tabelas são criadas automaticamente via `backend/sql/init.sql` na primeira inicialização do Postgres.

Forçar nova coleta manualmente:

```bash
curl -X POST http://localhost:8000/api/cotacoes/atualizar \
  -H "X-Admin-Token: change-me-in-production"
```

## 2. Executar o app Flutter apontando para a API

```bash
flutter pub get
flutter run --dart-define=COTACOES_API_URL=http://localhost:8000
```

Para emulador Android, use `http://10.0.2.2:8000` em vez de `localhost`.

## 3. Deploy na nuvem (Render.com)

1. Faça push para [projeto_cafe_conecta](https://github.com/marcoaevaristo/projeto_cafe_conecta)
2. Crie conta em [Render](https://render.com)
3. **New → Blueprint** e selecione o repositório (usa `render.yaml`)
4. Após deploy, copie a URL da API (ex: `https://cafe-conecta-api.onrender.com`)
5. Execute o app:

```bash
flutter run --dart-define=COTACOES_API_URL=https://SUA-API.onrender.com
```

## 4. Variáveis de ambiente (API)

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `DATABASE_URL` | Conexão PostgreSQL | `postgresql://cafe:cafe123@postgres:5432/cafe_conecta` |
| `CORS_ORIGINS` | Origens permitidas (vírgula) | `*` |
| `SCRAPER_INTERVAL_HOURS` | Intervalo de coleta | `6` |
| `ADMIN_TOKEN` | Token para POST `/api/cotacoes/atualizar` | `change-me-in-production` |

## 5. Endpoints da API

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/health` | Health check |
| GET | `/api/cotacoes/atual` | Cotações atuais (CEPEA, Notícias, Dólar, B3) |
| GET | `/api/cotacoes/historico?fonte=cepea&tipo=arabica&dias=30` | Histórico para gráfico |
| POST | `/api/cotacoes/atualizar` | Dispara scrapers (header `X-Admin-Token`) |

## 6. Tabelas PostgreSQL

- `cotacoes_cepea` — Arábica e Conilon (CEPEA/ESALQ)
- `cotacoes_noticias` — Preço físico (Notícias Agrícolas)
- `cotacoes_dolar` — PTAX Banco Central
- `cotacoes_b3` — Futuros ICE (Investing.com)
- `scraper_logs` — Log de execuções

Schema completo: `backend/sql/init.sql`
