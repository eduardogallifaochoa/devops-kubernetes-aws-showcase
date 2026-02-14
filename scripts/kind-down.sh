#!/usr/bin/env bash
set -euo pipefail

KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-showcase}"

if kind get clusters | grep -qx "${KIND_CLUSTER_NAME}"; then
  kubectl delete -f k8s/ingress.yaml --ignore-not-found=true || true
  kubectl delete -f k8s/dev-deployment.yaml --ignore-not-found=true || true
  kubectl delete -f k8s/qa-deployment.yaml --ignore-not-found=true || true
  kubectl delete -f k8s/namespace.yaml --ignore-not-found=true || true
  kubectl delete namespace ingress-nginx --ignore-not-found=true || true
  kind delete cluster --name "${KIND_CLUSTER_NAME}"
else
  echo "Cluster ${KIND_CLUSTER_NAME} does not exist."
fi
