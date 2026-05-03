#!/bin/bash
# ─────────────────────────────────────────────────────────────
# deploy.sh — Deploys k8s-dashboard to the OCI cluster
# ─────────────────────────────────────────────────────────────
set -euo pipefail

NAMESPACE="k8s-dashboard"
REGISTRY="gru.ocir.io"
NAMESPACE_OCI="<DOCKER_OBJECT_STORAGE_NAMESPACE>"   # OCI Object Storage namespace
DOCKER_USER="<seu_email>"
PLATFORM="linux/arm64"

echo ">>> [1/6] Applying namespace and RBAC..."
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/01-rbac.yaml

echo ">>> [2/6] Creating OCI Registry pull secret..."
kubectl create secret docker-registry oci-registry-secret \
  --docker-server="${REGISTRY}" \
  --docker-username="${NAMESPACE_OCI}/${DOCKER_USER}" \
  --docker-password="${DOCKER_PASSWORD}" \
  --docker-email="${DOCKER_USER}" \
  -n "${NAMESPACE}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ">>> [3/6] Building and pushing images (ARM64)..."

# Backend
docker buildx build \
  --platform "${PLATFORM}" \
  -t "${REGISTRY}/${NAMESPACE_OCI}/k8s-dashboard-backend_platform_linux-arm64:latest" \
  --no-cache --push \
  ./k8s-dashboard-backend

# Frontend
docker buildx build \
  --platform "${PLATFORM}" \
  -t "${REGISTRY}/${NAMESPACE_OCI}/k8s-dashboard-frontend_platform_linux-arm64:latest" \
  --no-cache --push \
  ./k8s-dashboard-frontend

echo ">>> [4/6] Deploying backend..."
kubectl apply -f k8s/02-backend-deployment.yaml

echo ">>> [5/6] Deploying frontend..."
kubectl apply -f k8s/03-frontend-deployment.yaml

echo ">>> [6/6] Applying Ingress..."
kubectl apply -f k8s/04-ingress.yaml

echo ""
echo ">>> Waiting for rollout..."
kubectl rollout status deployment/k8s-dashboard-backend  -n "${NAMESPACE}" --timeout=120s
kubectl rollout status deployment/k8s-dashboard-frontend -n "${NAMESPACE}" --timeout=60s

echo ""
echo "✅ k8s-dashboard deployed successfully!"
echo "   Frontend: https://dashboard.seudominio.com.br"
echo "   API:      https://dashboard.seudominio.com.br/api/k8s/summary"
echo ""
kubectl get pods -n "${NAMESPACE}"
