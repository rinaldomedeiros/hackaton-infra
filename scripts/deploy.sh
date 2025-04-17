#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POSTGRES_DIR="$SCRIPT_DIR/../k8s/postgres"
MYAPP_DIR="$SCRIPT_DIR/../k8s/myapp"

minikube start
minikube addons enable metrics-server

minikube image load hackaton-producer-myapp:latest

echo "🚀 Applying PostgreSQL PVC..."
kubectl apply -f "$POSTGRES_DIR/postgres-pvc.yml"

echo "🚀 Applying PostgreSQL Deployment..."
kubectl apply -f "$POSTGRES_DIR/postgres-deployment.yml"

echo "🚀 Applying PostgreSQL Service..."
kubectl apply -f "$POSTGRES_DIR/postgres-service.yml"

echo "⏳ Waiting for Postgres to be ready..."
kubectl rollout status deployment/postgres-deployment --timeout=120s

echo "🚀 Applying MyApp manifests..."
kubectl apply -f "$MYAPP_DIR"

echo "⏳ Waiting for MyApp to be ready..."
kubectl rollout status deployment/myapp-deployment --timeout=120s

echo; kubectl get pods,svc,hpa; echo
echo "✅ Deploy completo! Acesse: http://$(minikube ip):30080"
