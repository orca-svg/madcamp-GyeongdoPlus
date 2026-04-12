# Backend Deployment

## Local container stack

```bash
cd backend
docker compose -f docker-compose.local.yml up --build
```

This starts:

- PostgreSQL on `localhost:5432`
- Redis on `localhost:6379`
- Backend on `http://localhost:3000`

The container entrypoint runs `prisma migrate deploy` before starting the app, so the health endpoint should become available at `/health` once the stack is ready.

## Local verification

```bash
cd backend
npm run build
npm test -- --runInBand
npm run db:migrate:status
curl http://127.0.0.1:3000/health
```

For e2e tests in restricted sandboxes, the HTTP listen step may require elevated permissions even when the test itself is correct.

## Production image behavior

- The Docker image builds NestJS in a dedicated build stage.
- Runtime starts through `scripts/start-prod.sh`.
- `RUN_PRISMA_MIGRATIONS=false` can disable automatic `prisma migrate deploy` if the target environment applies migrations separately.

## EC2 workflow expectations

The GitHub Actions workflow expects these secrets:

- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`
- `EC2_HOST`
- `EC2_USER`
- `EC2_SSH_KEY`
- `DATABASE_URL`
- `DIRECT_URL`
- `JWT_SECRET`
- `REDIS_PASSWORD`
- `KAKAO_CLIENT_ID`
- `KAKAO_CALLBACK_URL`
- `KAKAO_CLIENT_SECRET`
