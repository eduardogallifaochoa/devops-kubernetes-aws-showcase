#!/usr/bin/env bash
set -euo pipefail

KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-showcase}"
INGRESS_MANIFEST_URL="https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml"

if ! kind get clusters | grep -qx "${KIND_CLUSTER_NAME}"; then
  kind create cluster --name "${KIND_CLUSTER_NAME}" --config k8s/kind-config.yaml
fi

echo "Installing ingress-nginx..."
kubectl apply -f "${INGRESS_MANIFEST_URL}"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo "Building local image..."
docker build -t fastapi-showcase:local .
kind load docker-image fastapi-showcase:local --name "${KIND_CLUSTER_NAME}"

echo "Applying Kubernetes manifests..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/dev-deployment.yaml
kubectl apply -f k8s/qa-deployment.yaml
kubectl apply -f k8s/ingress.yaml

kubectl rollout status deployment/api-dev -n showcase --timeout=180s
kubectl rollout status deployment/api-qa -n showcase --timeout=180s

echo "kind cluster is ready."
