#!/usr/bin/env bash
set -euo pipefail

# Determina automaticamente onde está este script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$SCRIPT_DIR/../k8s"

echo "⏳ Iniciando Minikube..."
minikube start
minikube addons enable metrics-server

echo "⏳ Carregando imagem da aplicação no Minikube..."
minikube image load hackaton-producer-myapp:latest

# 1️⃣ Deploy do PostgreSQL
echo "🚀 Aplicando manifests do PostgreSQL..."
kubectl apply -f "$K8S_DIR/postgres"
echo "⏳ Aguardando Postgres ficar Ready..."
kubectl --request-timeout=0 rollout status deployment/postgres-deployment --timeout=120s

# 2️⃣ Deploy do Zookeeper
echo "🚀 Aplicando manifests do Zookeeper..."
kubectl apply -f "$K8S_DIR/kafka/zookeeper-deployment.yml" \
               -f "$K8S_DIR/kafka/zookeeper-service.yml"
echo "⏳ Aguardando Pod do Zookeeper ficar Ready (até 5m)..."
kubectl --request-timeout=0 wait \
  --for=condition=ready pod -l app=kafka,component=zookeeper \
  --timeout=300s

# 3️⃣ Deploy do Kafka Broker
echo "🚀 Aplicando manifests do Kafka broker..."
kubectl apply -f "$K8S_DIR/kafka/kafka-deployment.yml" \
               -f "$K8S_DIR/kafka/kafka-service.yml"
echo "⏳ Aguardando Pod do Kafka broker ficar Ready (até 5m)..."
kubectl --request-timeout=0 wait \
  --for=condition=ready pod -l app=kafka,component=broker \
  --timeout=300s

# 4️⃣ Deploy da aplicação
echo "🚀 Aplicando manifests da aplicação MyApp..."
kubectl apply -f "$K8S_DIR/myapp"
echo "⏳ Aguardando MyApp ficar Ready..."
kubectl --request-timeout=0 rollout status deployment/myapp-deployment --timeout=120s

# 5️⃣ Resumo final
echo
kubectl get pods,svc,hpa
echo
echo "✅ Deploy completo! Acesse em: http://$(minikube ip):30080"
