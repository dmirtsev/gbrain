# Deploy GBrain to Coolify

This fork is used as a deployable GBrain HTTP MCP server for Coolify.

## Role

GBrain is the memory / retrieval / synthesis layer.
Hermes Agent should run as a separate service and connect to this GBrain service via HTTP MCP.

## Coolify service

Create a new Application in Coolify:

- Repository: `dmirtsev/gbrain`
- Branch: `master`
- Build pack: Dockerfile
- Domain: `gbrain.astrogeoagent.ru`
- Internal port: `3131`

## Persistent volume

Add a persistent volume:

```text
/data
```

The Dockerfile sets:

```env
GBRAIN_HOME=/data/.gbrain
```

## Required environment variables

Use Coolify Environment Variables. Do not commit secrets to GitHub.

```env
PORT=3131
PUBLIC_URL=https://gbrain.astrogeoagent.ru
GBRAIN_DATABASE_URL=postgresql://USER:PASSWORD@postgres:5432/gbrain
OPENAI_API_KEY=...
```

Optional:

```env
ANTHROPIC_API_KEY=...
ZEROENTROPY_API_KEY=...
GBRAIN_EMBEDDING_MODEL=openai:text-embedding-3-small
GBRAIN_CHAT_MODEL=openai:gpt-4o-mini
```

GBrain also accepts `DATABASE_URL`, but `GBRAIN_DATABASE_URL` is clearer for this service.

## Start command

The Dockerfile starts:

```bash
bun run src/cli.ts serve --http --port ${PORT:-3131} --bind 0.0.0.0 --public-url ${PUBLIC_URL:-http://localhost:3131}
```

## Database preparation

Use the existing PostgreSQL + pgvector container, but create a separate database for GBrain.

```bash
docker exec -it postgres-idr1a5izq12b1irzq3r0gvzd psql -U astro_admin -d postgres -c "CREATE DATABASE gbrain;"

docker exec -it postgres-idr1a5izq12b1irzq3r0gvzd psql -U astro_admin -d gbrain -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

## First deploy checks

Health / server check:

```bash
curl https://gbrain.astrogeoagent.ru/health
```

Admin dashboard:

```text
https://gbrain.astrogeoagent.ru/admin
```

On first start, GBrain prints an admin bootstrap token in stderr. Open the Coolify logs, copy the token, and paste it into the admin dashboard.

## MCP endpoint

The remote MCP endpoint is expected at:

```text
https://gbrain.astrogeoagent.ru/mcp
```

## Client registration

Register clients in `/admin`, or by CLI if you exec into the container.

For the future Hermes Agent client, use approximately:

```bash
gbrain auth register-client hermes-agent \
  --grant-types client_credentials \
  --scopes "read write" \
  --source default \
  --federated-read default
```

For the multi-user AstroFest / Hermes architecture, prefer source-scoped clients and keep domain ACL/retrieval policy outside the GBrain core.

## Architecture note

Do not put private AstroFest business logic, client data, secrets, or retrieval policy into this public fork.

Use this fork for:

- Docker/Coolify deployability
- small upstream-friendly patches
- configuration examples without secrets

Keep private domain logic in a separate private repository, such as `hermes-control-layer`.
