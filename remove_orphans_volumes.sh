#!/bin/bash

# Script para remover volumes órfãos no Docker
# Autor: [Seu Nome]
# Versão: 1.0

# Cores para mensagens
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para verificar se o Docker está instalado e rodando
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Erro: Docker não está instalado.${NC}"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        echo -e "${RED}Erro: Docker não está rodando.${NC}"
        exit 1
    fi
}

# Função principal
main() {
    check_docker

    echo -e "${YELLOW}=== Remoção de Volumes Órfãos no Docker ===${NC}"

    # Obter lista de volumes órfãos
    ORPHANED_VOLUMES=$(docker volume ls -qf dangling=true)

    if [ -z "$ORPHANED_VOLUMES" ]; then
        echo -e "${GREEN}Nenhum volume órfão encontrado.${NC}"
        exit 0
    fi

    echo -e "${YELLOW}Os seguintes volumes órfãos serão removidos:${NC}"
    echo "$ORPHANED_VOLUMES" | while read volume; do
        echo " - $volume"
    done

    # Confirmação do usuário
    read -p "Deseja realmente remover estes volumes? [s/N] " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}Operação cancelada pelo usuário.${NC}"
        exit 0
    fi

    # Remover volumes
    echo "$ORPHANED_VOLUMES" | while read volume; do
        echo -n "Removendo volume $volume... "
        if docker volume rm "$volume" &> /dev/null; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}FALHOU${NC}"
        fi
    done

    echo -e "${GREEN}Processo concluído.${NC}"
}

main "$@"