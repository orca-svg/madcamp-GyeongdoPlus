# Backend

## Setup

```bash
cd backend
npm install
cp .env.example .env
npm run prisma:generate
```

Fill the database, Redis, and JWT values in `.env`.

## Run

```bash
npm run db:migrate:deploy
npm run build
npm run start:dev
```

For a local host-run override:

```bash
cp .env.local.example .env.local
```

## Local Docker Stack

```bash
cd backend
docker compose -f docker-compose.local.yml up --build
```

This starts PostgreSQL, Redis, and the backend together. The backend container runs Prisma migrations automatically before boot.

## Smoke Checks

```bash
npm test -- --runInBand
npm run test:e2e -- --runInBand
curl http://127.0.0.1:3000/health
```

For the Docker stack:

```bash
curl http://127.0.0.1:3000/health
docker compose -f docker-compose.local.yml logs backend
```

## Environment

The backend loads environment files in this order:

1. `.env.local`
2. `.env`

You can also override the file path with `ENV_FILE=...`.

Supported deployment-oriented variables:

- `HOST`
- `PORT`
- `RUN_PRISMA_MIGRATIONS`
- `CORS_ORIGINS`
- `SWAGGER_ENABLED`

## Health Endpoint

`GET /health` returns a lightweight readiness payload and is safe to use for local smoke tests, container health checks, and deployment probes.
