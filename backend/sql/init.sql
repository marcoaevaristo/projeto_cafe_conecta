-- Café Conecta — schema PostgreSQL para cotações de mercado
-- Executado automaticamente pelo Docker na primeira inicialização

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- CEPEA (Arábica + Conilon)
CREATE TABLE IF NOT EXISTS cotacoes_cepea (
    id SERIAL PRIMARY KEY,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('arabica', 'conilon')),
    preco NUMERIC(12, 2) NOT NULL,
    unidade VARCHAR(60) NOT NULL DEFAULT 'saca 60kg',
    data_referencia DATE NOT NULL,
    variacao_pct NUMERIC(8, 3),
    fonte VARCHAR(80) NOT NULL DEFAULT 'CEPEA/ESALQ',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tipo, data_referencia)
);

CREATE INDEX IF NOT EXISTS idx_cepea_tipo_data ON cotacoes_cepea (tipo, data_referencia DESC);

-- Notícias Agrícolas (preço físico)
CREATE TABLE IF NOT EXISTS cotacoes_noticias (
    id SERIAL PRIMARY KEY,
    tipo VARCHAR(40) NOT NULL,
    preco NUMERIC(12, 2) NOT NULL,
    unidade VARCHAR(60) NOT NULL DEFAULT 'saca 60kg',
    data_referencia DATE NOT NULL,
    variacao_pct NUMERIC(8, 3),
    fonte VARCHAR(100) NOT NULL DEFAULT 'Notícias Agrícolas',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tipo, data_referencia)
);

CREATE INDEX IF NOT EXISTS idx_noticias_tipo_data ON cotacoes_noticias (tipo, data_referencia DESC);

-- Dólar PTAX (Banco Central)
CREATE TABLE IF NOT EXISTS cotacoes_dolar (
    id SERIAL PRIMARY KEY,
    cotacao_compra NUMERIC(12, 4) NOT NULL,
    cotacao_venda NUMERIC(12, 4) NOT NULL,
    data_referencia DATE NOT NULL UNIQUE,
    fonte VARCHAR(80) NOT NULL DEFAULT 'Banco Central (PTAX)',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dolar_data ON cotacoes_dolar (data_referencia DESC);

-- B3 / Futuros (Investing)
CREATE TABLE IF NOT EXISTS cotacoes_b3 (
    id SERIAL PRIMARY KEY,
    contrato VARCHAR(80) NOT NULL,
    simbolo VARCHAR(20),
    preco NUMERIC(12, 2) NOT NULL,
    variacao_pct NUMERIC(8, 3),
    moeda VARCHAR(10) NOT NULL DEFAULT 'USD',
    data_referencia DATE NOT NULL,
    fonte VARCHAR(80) NOT NULL DEFAULT 'Investing.com',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (contrato, data_referencia)
);

CREATE INDEX IF NOT EXISTS idx_b3_contrato_data ON cotacoes_b3 (contrato, data_referencia DESC);

-- Log de execuções do scraper
CREATE TABLE IF NOT EXISTS scraper_logs (
    id SERIAL PRIMARY KEY,
    fonte VARCHAR(40) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('ok', 'erro', 'parcial')),
    mensagem TEXT,
    registros_inseridos INT NOT NULL DEFAULT 0,
    executado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_scraper_logs_executado ON scraper_logs (executado_em DESC);
