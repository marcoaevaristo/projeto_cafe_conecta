# ☕ Café Conecta v3.0 — Flutter App

## 🚀 COMO EXECUTAR NO VS CODE

### PASSO 1 — Instale o Flutter SDK

**Windows:**
1. Acesse https://flutter.dev/docs/get-started/install/windows
2. Baixe o .zip e extraia em `C:\flutter` (não use Program Files)
3. Adicione `C:\flutter\bin` ao PATH do sistema:
   - Pesquise "Variáveis de ambiente" → Path → Novo → `C:\flutter\bin`
4. Reinicie o terminal

**macOS:**
```bash
brew install flutter
```
Ou baixe o .zip em flutter.dev e adicione ao PATH no `~/.zshrc`:
```bash
export PATH="$HOME/flutter/bin:$PATH"
```

**Linux:**
```bash
sudo snap install flutter --classic
```

### PASSO 2 — Verifique a instalação
```bash
flutter doctor
```
Todos os itens devem aparecer com ✓ verde.

### PASSO 3 — Instale o VS Code e extensões
1. Baixe o VS Code em https://code.visualstudio.com
2. Abra o VS Code → `Ctrl+Shift+X`
3. Pesquise e instale:
   - **Flutter** (Dart Code)
   - **Dart** (Dart Code)

### PASSO 4 — Configure um emulador Android

1. Instale o Android Studio: https://developer.android.com/studio
2. Abra o Android Studio → More Actions → Virtual Device Manager
3. Create Device → Pixel 6 → Next → Android 14 (API 34) → Finish
4. Clique ▶ para iniciar o emulador

**Ou use um dispositivo físico:**
- Android: Configurações → Sobre o telefone → toque 7x em "Número da versão"
- Ative: Opções do desenvolvedor → Depuração USB → conecte via USB

### PASSO 5 — Execute o projeto

```bash
# 1. Entre na pasta
cd cafe_conecta_flutter

# 2. Instale dependências
flutter pub get

# 3. Execute
flutter run
```

**No VS Code:**
- `File → Open Folder` → selecione `cafe_conecta_flutter`
- Pressione `F5` ou `Run → Start Debugging`
- Escolha o dispositivo/emulador na barra inferior

---

## 👤 Usuários de teste (senha: 123456)

| Tipo      | E-mail                             |
|-----------|------------------------------------|
| Corretor  | joao@cafesuldeminas.com.br         |
| Corretor  | cooperativa@cerrado.com.br         |
| Comprador | ana@torrefacao.com.br              |

---

## 📦 DEPENDÊNCIAS

Todas instaladas com `flutter pub get`:

| Pacote              | Uso                                    |
|---------------------|----------------------------------------|
| google_fonts        | Playfair Display + DM Sans             |
| provider            | Gerenciamento de estado                |
| sqflite             | Banco SQLite local                     |
| path                | Caminhos do banco                      |
| crypto              | Hash de senha SHA-256                  |
| fl_chart            | Gráficos (dashboard + histórico)       |
| flutter_map         | Mapa de disponibilidade (OpenStreetMap)|
| latlong2            | Coordenadas geográficas                |
| intl                | Formatação R$ e datas                  |
| url_launcher        | WhatsApp e telefone                    |
| mask_text_input_formatter | Máscaras de input              |
| shimmer             | Efeito de carregamento                 |

---

## 📱 TELAS DO APP v3.0

| Tela                  | Versão | Descrição                                      |
|-----------------------|--------|------------------------------------------------|
| Login / Cadastro      | v1     | Autenticação completa                          |
| Dashboard             | ✨ v3  | KPIs, gráfico de preços, funil, pizza          |
| Catálogo              | v2     | Score filter slider + chips                    |
| Mapa                  | ✨ v3  | Flutter Map com marcadores e card de lote      |
| Alertas               | v2     | Toggle on/off + criação por bottom sheet       |
| Propostas             | ✨ v3  | Aceitar / Recusar / Contraproposta (4 passos)  |
| Mensagens / Chat      | v1     | Chat em tempo real local                       |
| Avaliações            | ✨ v3  | Estrelas, barras de distribuição, comentários  |
| Histórico de Preços   | v2     | Gráfico fl_chart por região e período          |
| **Cotações de Mercado** | ✨ v3.1 | CEPEA, Notícias Agrícolas, Dólar PTAX, B3/ICE |
| Perfil                | v3     | Estrelas de reputação + mini stats             |
| Meus Anúncios         | v1     | Gestão por status                              |
| Novo Anúncio          | v1     | Cadastro de lote                               |
| Nova Proposta         | v2     | Fluxo 4 etapas com número oficial              |

---

## 🗄️ BANCO DE DADOS (SQLite local)

Arquivo: `cafe_conecta_v3.db` — criado automaticamente.

**Tabelas:**
- `usuarios` — com media_avaliacao e total_avaliacoes
- `cafes` — com lat/lng para o mapa
- `favoritos`, `mensagens`, `alertas`
- `propostas` — com status: aguardando/aceita/recusada/contraproposta
- `historico_precos` — 6 meses de dados por região
- `avaliacoes` ✨ nova — notas 1-5 com comentários

---

## ❓ PROBLEMAS COMUNS

**"flutter: command not found"**
→ Adicione o caminho `bin/` do Flutter SDK ao PATH e reinicie o terminal.

**"No devices found"**
→ Inicie o emulador no Android Studio ou conecte dispositivo físico via USB.

**"Gradle build failed"**
```bash
flutter clean
flutter pub get
flutter run
```

**"MissingPluginException"**
```bash
flutter clean && flutter pub get
```

**Mapa não carrega**
→ Verifique conexão com internet (OpenStreetMap requer rede).

**Cotações não carregam**
→ Suba a API com `docker compose up -d` e execute o app com:
```bash
flutter run --dart-define=COTACOES_API_URL=http://localhost:8000
```

---

## 📈 COTAÇÕES DE MERCADO (API Python + PostgreSQL)

Backend com scraping automático a cada 6 horas:

| Fonte | Dado |
|-------|------|
| CEPEA/ESALQ | Arábica + Conilon |
| Notícias Agrícolas | Preço físico |
| Banco Central | Dólar PTAX |
| Investing.com | Futuros ICE (Arábica/Conilon) |

```bash
# Subir API + PostgreSQL (tabelas criadas automaticamente)
docker compose up -d --build

# App Flutter apontando para a API
flutter run --dart-define=COTACOES_API_URL=http://localhost:8000
```

Deploy na nuvem: veja [DEPLOY.md](DEPLOY.md) e [render.yaml](render.yaml).

---

## 📁 ESTRUTURA

```
cafe_conecta_flutter/
├── lib/
│   ├── main.dart
│   ├── models/cafe_model.dart          # Todos os modelos
│   ├── services/
│   │   ├── database_service.dart       # SQLite CRUD completo
│   │   ├── cotacoes_service.dart       # API de cotações (HTTP)
│   │   └── app_state.dart              # Provider global
│   ├── utils/theme.dart                # Cores e fontes
│   ├── widgets/cafe_card.dart          # Card + EmptyState
│   └── screens/
│       ├── login_screen.dart
│       ├── cadastro_screen.dart
│       ├── main_screen.dart            # Bottom nav 7 abas
│       ├── dashboard_screen.dart       ✨ v3
│       ├── home_screen.dart            v2 score filter
│       ├── mapa_screen.dart            ✨ v3
│       ├── alertas_screen.dart         v2
│       ├── propostas_screen.dart       ✨ v3 contraproposta
│       ├── nova_proposta_screen.dart   v2
│       ├── avaliacoes_screen.dart      ✨ v3
│       ├── historico_precos_screen.dart v2
│       ├── cotacoes_screen.dart        ✨ v3.1
│       ├── detalhes_cafe_screen.dart
│       ├── favoritos_screen.dart
│       ├── mensagens_screen.dart
│       ├── conversa_screen.dart
│       ├── perfil_screen.dart          v3
│       ├── meus_anuncios_screen.dart
│       └── novo_anuncio_screen.dart
├── backend/                            # API Python FastAPI + scrapers
│   ├── app/
│   ├── sql/init.sql                    # Schema PostgreSQL
│   └── Dockerfile
├── docker-compose.yml
├── render.yaml                         # Deploy Render.com
├── DEPLOY.md
├── pubspec.yaml
└── README.md
```
