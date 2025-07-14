#!/bin/bash
set -e

# Load .env variables into the shell
if [ ! -f .env ]; then
  echo ".env file not found!"
  exit 1
fi
export $(grep -v '^#' .env | xargs)

echo "Creating gitea-admin-secret..."
kubectl create secret generic gitea-admin-secret \
  --from-literal=DB_URL="$APP1_DB_URL" \
  --from-literal=JWT_SECRET="$JWT_SECRET" \
  --namespace "gitea" --dry-run=client -o yaml | kubectl apply -f -

echo "Creating app2-secret..."
kubectl create secret generic app2-secret \
  --from-literal=DB_URL="$APP2_DB_URL" \
  --namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "Creating redis-secret..."
kubectl create secret generic redis-secret \
  --from-literal=REDIS_URL="$REDIS_URL" \
  --namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secrets created or updated successfully in namespace '$NAMESPACE'"
