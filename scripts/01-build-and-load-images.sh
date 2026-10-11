#!/usr/bin/env bash
# Builds de PRODUCCIÓN (más livianos y rápidos que los de dev).
# Se puede ejecutar desde cualquier directorio porque resuelve la raíz del repo.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="${CLUSTER_NAME:-lens-demo}"

for cmd in docker kind; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Falta la dependencia '$cmd' en PATH." >&2
    exit 1
  fi
done

if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  echo "El cluster '$CLUSTER_NAME' no existe; creándolo..."
  kind create cluster --config "$REPO_ROOT/kind-cluster.yaml" --name "$CLUSTER_NAME"
fi

docker build -t alentapp-backend:prod -f "$REPO_ROOT/packages/api/Dockerfile.prod" "$REPO_ROOT"
docker build -t alentapp-frontend:prod -f "$REPO_ROOT/packages/web/Dockerfile.prod" "$REPO_ROOT"

kind load docker-image alentapp-backend:prod --name "$CLUSTER_NAME"
kind load docker-image alentapp-frontend:prod --name "$CLUSTER_NAME"

echo "Imágenes de prod cargadas en el cluster kind '$CLUSTER_NAME'."