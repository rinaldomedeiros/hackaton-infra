#!/bin/bash

# ===========================================================================================
# Para utilizar esse arquivo, copie os arquivos .sh desse projeto para a este novo diretório,
# faça o checkout de todos os projetos para o mesmo diretório.
# ===========================================================================================

# Script para limpar containers, imagens e volumes específicos e reconstruir aplicações Docker
# Autor: Eduardo Lima
# Data: 19/04/2025
# Descrição: Este script limpa containers, imagens e volumes específicos associados a aplicações Docker
# e, em seguida, reconstrói e inicia as aplicações na ordem especificada.
# Uso: ./rebuild_all.sh
# Certifique-se de que o script tenha permissões de execução
# chmod +x rebuild_all.sh
# Dependências: docker, docker compose

echo "Usando Bash versão: $BASH_VERSION"
echo "Usando Docker versão: $(docker --version)"
echo "Usando Docker Compose versão: $(docker compose version)" 


# Ordem de execução das aplicações
APPS=("hackaton-infra" "hackaton-registration" "hackaton-security" "hackaton-producer" "hackaton-consumer" "hackaton-gateway")

# Mapeamento: aplicação -> lista de containers
declare -A CONTAINERS_MAP

CONTAINERS_MAP["hackaton-infra"]        ="zookeeper kafka kafka-ui"
CONTAINERS_MAP["hackaton-registration"] ="userservice_psql registration"
CONTAINERS_MAP["hackaton-security"]     ="security"
CONTAINERS_MAP["hackaton-producer"]     ="producer_db producer"
CONTAINERS_MAP["hackaton-consumer"]     ="redis consumer"
CONTAINERS_MAP["hackaton-gateway"]      ="gateway"

# Função para parar e remover containers associados
remove_containers() {
  local containers=($1)
  for container in "${containers[@]}"; do
    if docker ps -a --format '{{.Names}}' | grep -q "^$container\$"; then
      echo "🗑️  Removendo container: $container"
      docker rm -f "$container"
    else
      echo "ℹ️  Container $container não encontrado."
    fi
  done
}

# Função para limpar aplicação
cleanup_app() {
  local APP_DIR=$1
  local CONTAINERS=$2
  local IMAGE_NAME="${APP_DIR}-myapp"

  echo "🔻 Limpando aplicação: $APP_DIR"

  # Remover containers explicitamente
  remove_containers "$CONTAINERS"

  if docker images --format '{{.Repository}}' | grep -q "^$IMAGE_NAME$"; then
    echo "🧯 Removendo imagem: $IMAGE_NAME"
    docker rmi -f "$IMAGE_NAME"
  else
    echo "ℹ️  Imagem $IMAGE_NAME não encontrada. Pulando..."
  fi

  cd "$APP_DIR" || { echo "❌ Não foi possível acessar $APP_DIR"; exit 1; }

  cd - > /dev/null
}

# Função para buildar e subir containers
build_and_up_app() {
  local APP_DIR=$1
  echo "🚀 Subindo aplicação: $APP_DIR"

  cd "$APP_DIR" || { echo "❌ Não foi possível acessar $APP_DIR"; exit 1; }

  # Verifica build Maven
  if [ -f "pom.xml" ]; then
      echo -e "\n[Build Maven]"
      echo "Arquivo pom.xml encontrado"        
      mvn clean install -Dspring.profiles.active=docker -DskipTests || { echo "ERRO: Build Maven falhou"; cd ..; return 1; }
  else
      echo -e "\n[Build Maven]"
      echo "Pom.xml não encontrado, pulando build Maven"
  fi

  echo "📦 Subindo containers..."
  docker compose up -d

  cd - > /dev/null
}

# Execução principal
echo "====================================="
echo "⚙️  Iniciando rebuild completo das aplicações"
echo "====================================="

for APP in "${APPS[@]}"; do
  CONTAINERS="${CONTAINERS_MAP[$APP]}"
  cleanup_app "$APP" "$CONTAINERS"

done

if [ -f "./remove_orphans_volumes.sh" ]; then
  ./remove_orphans_volumes.sh
else
  echo "❌ Script start-db.sh não encontrado!"
fi

for APP in "${APPS[@]}"; do
  build_and_up_app "$APP"
done

echo "✅ Rebuild completo concluído!"
