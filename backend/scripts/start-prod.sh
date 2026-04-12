#!/bin/sh

set -eu

if [ "${RUN_PRISMA_MIGRATIONS:-true}" = "true" ]; then
  if find prisma/migrations -mindepth 1 -maxdepth 1 -type d | grep -q .; then
    npx prisma migrate deploy
  else
    npx prisma db push
  fi
fi

exec node dist/main
