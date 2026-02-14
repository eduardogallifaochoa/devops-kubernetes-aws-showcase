#!/usr/bin/env bash
set -euo pipefail

KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-showcase}"

echo "Stopping and removing Docker Compose services..."
docker compose down -v || true

if command -v kind >/dev/null 2>&1 && command -v kubectl >/dev/null 2>&1; then
  echo "Tearing down kind cluster '${KIND_CLUSTER_NAME}' if it exists..."
  ./scripts/kind-down.sh || true
else
  echo "Skipping kind teardown because kind or kubectl is not installed."
fi

echo "Pruning unused local Docker resources..."
docker image prune -f || true
docker volume prune -f || true

echo "Local teardown complete."
echo "Reminder: GHCR and AWS resources are not deleted by this local command."
