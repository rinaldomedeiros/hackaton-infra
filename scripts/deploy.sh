#!/usr/bin/env bash
set -euo pipefail

# Determina onde está o k8s
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$SCRIPT_DIR/../k8s"

# 0️⃣ Cache e carga das imagens no Minikube
# 0.1️⃣ Cache das imagens para startups futuras (requer minikube restart)
echo "⏳ Cacheando imagens no Minikube..."
minikube cache add postgres:16.2
minikube cache add bitnami/zookeeper:3.9
minikube cache add bitnami/kafka:3.5
minikube cache add redis:latest
minikube cache add registry.k8s.io/metrics-server/metrics-server:v0.7.2
minikube cache add hackaton-producer:latest
minikube cache add hackaton-consumer:latest
minikube cache add hackaton-gateway:latest
minikube cache add hackaton-security:latest
minikube cache add hackaton-registration:latest

# 0.2️⃣ Carga imediata das imagens para o runtime atual
echo "⏳ Carregando todas as imagens no Minikube..."
minikube image load postgres:16.2
minikube image load bitnami/zookeeper:3.9
minikube image load bitnami/kafka:3.5
minikube image load redis:latest
minikube image load registry.k8s.io/metrics-server/metrics-server:v0.7.2
minikube image load hackaton-producer:latest
minikube image load hackaton-consumer:latest
minikube image load hackaton-gateway:latest
minikube image load hackaton-security:latest
minikube image load hackaton-registration:latest

# 3️⃣ Deploy do PostgreSQL
echo "🚀 Aplicando Postgres..."
kubectl apply -R -f "$K8S_DIR/postgres"
kubectl --request-timeout=0 rollout status deployment/postgres --timeout=120s
kubectl --request-timeout=0 rollout status deployment/postgres-registration --timeout=120s

# 4️⃣ Deploy do Zookeeper
echo "🚀 Aplicando Zookeeper..."
kubectl apply -f "$K8S_DIR/kafka/zookeeper-deployment.yml" \
               -f "$K8S_DIR/kafka/zookeeper-service.yml"
kubectl --request-timeout=0 wait \
  --for=condition=ready pod -l app=kafka,component=zookeeper --timeout=300s

# 5️⃣ Deploy do Kafka Broker
echo "🚀 Aplicando Kafka..."
kubectl apply -f "$K8S_DIR/kafka/kafka-deployment.yml" \
               -f "$K8S_DIR/kafka/kafka-service.yml"
kubectl --request-timeout=0 wait \
  --for=condition=ready pod -l app=kafka,component=broker --timeout=300s

# 6️⃣ Deploy do Redis
echo "🚀 Aplicando Redis..."
kubectl apply -f "$K8S_DIR/redis"
kubectl --request-timeout=0 rollout status deployment/redis --timeout=120s
kubectl --request-timeout=0 wait \
  --for=condition=ready pod -l app=redis --timeout=300s

# 7️⃣ Deploy do Consumer
echo "🚀 Aplicando Consumer..."
kubectl apply -f "$K8S_DIR/consumer"
kubectl --request-timeout=0 rollout status deployment/consumer --timeout=120s
kubectl --request-timeout=0 apply -f "$K8S_DIR/consumer/consumer-hpa.yml"
kubectl --request-timeout=0 wait \
  --for=condition=ready pod -l app=consumer --timeout=300s

# 8️⃣ Deploy do Producer
echo "🚀 Aplicando Producer..."
kubectl apply -f "$K8S_DIR/producer"
kubectl --request-timeout=0 rollout status deployment/producer --timeout=120s

# 9️⃣ Deploy do Gateway
echo "🚀 Aplicando Gateway..."
kubectl apply -f "$K8S_DIR/gateway"
kubectl --request-timeout=0 rollout status deployment/gateway --timeout=120s

# 🔟 Deploy do Security
echo "🚀 Aplicando Security..."
kubectl apply -f "$K8S_DIR/security"
kubectl --request-timeout=0 rollout status deployment/security --timeout=120s

# 1️⃣1️⃣ Deploy do Registration
echo "🚀 Aplicando Registration..."
kubectl apply -f "$K8S_DIR/registration"
kubectl --request-timeout=0 rollout status deployment/registration --timeout=120s

# ✅ Resumo final
echo
kubectl get pods,svc,hpa
echo
echo "✅ Deploy completo!"

echo "⏳ Iniciando Port-Forward: localhost:8080 -> gateway-service:8080"
kubectl port-forward svc/gateway-service 30090:8080
