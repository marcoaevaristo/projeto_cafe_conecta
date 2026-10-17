# ☕ Café Conecta — Backend API

## 1. Instalar dependências

```bash
cd cafe_backend
pip install -r requirements.txt
```

## 2. Configurar conexão com PostgreSQL

Abra `database.py` e ajuste a senha na linha:

```python
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:SUA_SENHA@localhost:5432/cafe_conecta"
)
```

Ou crie um arquivo `.env`:
```
DATABASE_URL=postgresql://postgres:123456@localhost:5432/cafe_conecta
```

## 3. Rodar localmente

```bash
uvicorn main:app --reload --port 8000
```

## 4. Testar se está funcionando

Abra no navegador:
```
http://localhost:8000
```

Deve aparecer:
```json
{"app": "Café Conecta API", "status": "online", "versao": "1.0.0"}
```

## 5. Testar rota de login

No navegador ou Postman:
```
POST http://localhost:8000/auth/login
Body: {"email": "joao@cafesuldeminas.com.br", "senha": "123456"}
```

## 6. Testar listagem de cafés

```
GET http://localhost:8000/cafes
```

Deve retornar o café de teste inserido no PostgreSQL.

## 7. Documentação automática

O FastAPI gera documentação interativa automaticamente:
```
http://localhost:8000/docs
```

Você pode testar TODAS as rotas direto pelo navegador ali!

## 8. Deploy no Vercel

```bash
npm i -g vercel
vercel login
vercel
```

Adicione a variável de ambiente `DATABASE_URL` no painel do Vercel apontando para seu PostgreSQL (use Neon se quiser acesso externo).

## Rotas disponíveis

| Método | Rota | Descrição |
|---|---|---|
| POST | /auth/login | Login |
| POST | /auth/cadastro | Cadastro |
| GET | /cafes | Lista cafés (filtros: tipo, regiao, score_minimo) |
| GET | /cafes/{id} | Detalhe de um café |
| POST | /cafes | Criar anúncio |
| GET | /cafes/usuario/{id} | Cafés de um usuário |
| POST | /propostas | Criar proposta |
| GET | /propostas/usuario/{id} | Propostas do usuário |
| PATCH | /propostas/{id} | Atualizar status |
| POST | /mensagens | Enviar mensagem |
| GET | /mensagens/conversa | Histórico de conversa |
| POST | /avaliacoes | Criar avaliação |
| GET | /avaliacoes/usuario/{id} | Avaliações recebidas |
| POST | /alertas | Criar alerta |
| GET | /alertas/usuario/{id} | Alertas do usuário |
| POST | /favoritos | Toggle favorito |
| GET | /dashboard/{id} | Dados do dashboard |
