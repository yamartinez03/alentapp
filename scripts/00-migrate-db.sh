#!/usr/bin/env bash
# Corre las migraciones de Prisma UNA VEZ, antes de levantar el backend de prod
# (la imagen de runtime no tiene npx, así que esto se hace desde la máquina local
# contra la base de datos dentro del cluster, vía port-forward).
# Correr parado en la raíz del repo de AlentApp.
set -euo pipefail

kubectl -n alentapp port-forward svc/db 5433:5432 &
PF_PID=$!
sleep 2

DATABASE_URL="postgres://admin:password123@localhost:5433/alentapp_db" \
  npx prisma@7.8.0 migrate deploy --config packages/api/prisma.config.ts

kill $PF_PID
echo "Migraciones aplicadas."