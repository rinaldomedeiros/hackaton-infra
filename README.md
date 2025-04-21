# Projeto Hackaton Infra

Este README traz o **fluxo mínimo** para rodar localmente a aplicação **Producer** em um cluster Kubernetes (Minikube), usando o script de deploy já preparado.

---

## Pré‑requisitos

- Java 17 e Maven
- Docker (Desktop)
- Minikube e kubectl

---

## Passos

1. **Clonar o repositório**
   ```bash
   git clone [https://<seu-repo>/hackaton-producer.git](https://github.com/rinaldomedeiros/hackaton-producer)
   cd hackaton-producer
   ```

2. **Buildar o JAR e a imagem Docker**
   ```bash
   mvn clean package -DskipTests
   docker build -t hackaton-producer-myapp:latest .
   ```

3. **Executar o script de deploy**
   ```bash
   # dê permissão se necessário e rode:
   chmod +x scripts/deploy.sh
   cd scripts
   ./deploy.sh
   ```
   O `deploy.sh` vai:
   - Iniciar Minikube (com metrics‑server)
   - Carregar sua imagem para o cluster
   - Aplicar PostgreSQL, Zookeeper, Kafka e a aplicação
   - Aguardar todos os componentes ficarem prontos

4. **Acessar a aplicação**

   - **Port‑forward** (recomendado):
     ```bash
     kubectl port-forward svc/myapp-service 8080:8080
     ```
     Então abra outra aba e execute:
     ```bash
     curl http://localhost:8080/videos
     ```

   - **NodePort** (se preferir):
     ```bash
     curl http://$(minikube ip):30080/videos
     ```

---

## Limpeza de recursos

Para remover o cluster e apagar tudo:
```bash
minikube delete
```

---

Pronto! Com esses passos você terá a **Producer** rodando em Minikube de forma rápida e automatizada.    

