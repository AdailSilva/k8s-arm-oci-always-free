#!/bin/bash
# ─────────────────────────────────────────────────────────────
# deploy.sh — Deploys k8s-dashboard to the OCI cluster
# ─────────────────────────────────────────────────────────────
set -euo pipefail

NAMESPACE="k8s-dashboard"
REGISTRY="gru.ocir.io"
NAMESPACE_OCI="<OCI_REGISTRY_OBJECT_STORAGE_NAMESPACE>"   # OCI Object Storage namespace
OCI_REGISTRY_USER="<seu_email>"
PLATFORM="linux/arm64"

echo ">>> [1/10] Applying namespace and RBAC..."
kubectl apply -f kubernetes/01.create__Namespace.yaml
kubectl apply -f kubernetes/02.homepage-nginx__RBAC.yaml

echo ">>> [2/10] Creating OCI Registry pull secret..."
kubectl create secret docker-registry oci-registry-secret \
  --docker-server="${REGISTRY}" \
  --docker-username="${NAMESPACE_OCI}/${OCI_REGISTRY_USER}" \
  --docker-password="${OCI_REGISTRY_PASSWORD}" \
  --docker-email="${OCI_REGISTRY_USER}" \
  -n "${NAMESPACE}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ">>> [3/10] Building and pushing images (ARM64)..."

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

echo ">>> [4/10] Deploying backend..."
kubectl apply -f kubernetes/03.homepage-nginx__Backend_Deployment.yaml

echo ">>> [5/10] Deploying service backend..."
kubectl apply -f kubernetes/04.homepage-nginx__Backend_Service.yaml

echo ">>> [6/10] Deploying frontend..."
kubectl apply -f kubernetes/05.homepage-nginx__Frontend_Deployment.yaml

echo ">>> [7/10] Deploying service frontend..."
kubectl apply -f kubernetes/06.homepage-nginx__Frontend_Service.yaml

echo ">>> [8/10] Applying cert-manager..."
#kubectl apply -f kubernetes/07.homepage-nginx-cert-manager__v1.12.3__Components_Full.yaml

echo ">>> [9/10] Applying Let's Encrypt..."
#kubectl apply -f kubernetes/08.homepage-nginx-letsencrypt-issuer_with_e-mail_ACME_registration__ClusterIssuer.yaml

echo ">>> [10/10] Applying Ingress..."
kubectl apply -f kubernetes/09.homepage-nginx__Ingress.yaml

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
