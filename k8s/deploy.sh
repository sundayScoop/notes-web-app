#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if ! minikube status >/dev/null 2>&1; then
  echo "==> Starting minikube"
  minikube start
fi

echo "==> Building notes-web-app image"
docker build -t notes-web-app "$ROOT_DIR"

echo "==> Loading image into minikube"
minikube image load notes-web-app

echo "==> Creating TLS secret for nginx (idempotent)"
kubectl create secret generic nginx-certs \
  --from-file=selfsigned.crt="$ROOT_DIR/nginx/certs/selfsigned.crt" \
  --from-file=selfsigned.key="$ROOT_DIR/nginx/certs/selfsigned.key" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "==> Applying manifests"
kubectl apply -f "$SCRIPT_DIR"

echo "==> Waiting for rollouts"
kubectl rollout status deployment/webapp-deployment
kubectl rollout status deployment/mongo-express-deployment
kubectl rollout status deployment/nginx-deployment
kubectl rollout status statefulset/mongo

echo
echo "==> Done. Access points:"
NODE_IP="$(minikube ip)"
echo "  webapp via nginx (HTTPS): https://${NODE_IP}:30443"
echo "  webapp via nginx (HTTP redirect): http://${NODE_IP}:30080"
echo "  mongo-express UI: http://${NODE_IP}:32001"
