# 🏠 Homepage — k8s.adailsilva.com.br

> Repositório da homepage do cluster Kubernetes ARM na Oracle Cloud (OCI Always Free).
> Organizado em duas implementações independentes: uma **estática** (NGINX) e uma **em tempo real** (Angular 19 + Spring Boot 3.4).

---

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Estrutura do Repositório](#estrutura-do-repositório)
- [01.static — Homepage Estática (NGINX)](#01static--homepage-estática-nginx)
- [02.real\_time — Dashboard em Tempo Real](#02real_time--dashboard-em-tempo-real)
  - [Arquitetura](#arquitetura)
  - [Pré-requisitos](#pré-requisitos)
  - [Desenvolvimento Local](#desenvolvimento-local)
  - [Build das Imagens ARM64](#build-das-imagens-arm64)
  - [Deploy no Cluster](#deploy-no-cluster)
  - [Endpoints da API](#endpoints-da-api)
  - [Troubleshooting](#troubleshooting)

---

## Visão Geral

Este repositório contém **duas versões** da homepage do cluster:

| Versão | Diretório | Stack | Descrição |
|---|---|---|---|
| **Estática** | `01.static/` | NGINX + HTML | Página de apresentação simples, sem backend |
| **Tempo real** | `02.real_time/` | Angular 19 + Spring Boot 3.4 | Dashboard interativo com dados reais do cluster |

Ambas são servidas no mesmo domínio (`k8s.adailsilva.com.br`) via Ingress NGINX com TLS automático (cert-manager + Let's Encrypt). A versão em tempo real **substitui** a estática quando implantada.

---

## Estrutura do Repositório

```
00.homepage/
│
├── .gitignore                          # Ignora target/, node_modules/, dist/, IDEs
│
├── 01.static/                          # ── Versão 1: Homepage estática ──────────────
│   ├── Dockerfile                      # FROM nginx:latest + index.html
│   ├── index.html                      # Página HTML com visual cyberpunk animado
│   ├── docker/
│   │   └── docker-compose.yaml         # Teste local com Docker Compose
│   ├── 00.UsefulScripts/
│   │   ├── 01.deploy_homepage-nginx_script.sh
│   │   └── 02.destroy_homepage-nginx_script.sh
│   ├── 00.useful_commands.txt
│   └── kubernetes/
│       ├── 01.homepage-nginx__Namespace.yaml          # Namespace oci-devops
│       ├── 02.homepage-nginx__Deployment.yaml         # Deployment NGINX ARM64
│       ├── 03.homepage-nginx__Service.yaml            # Service ClusterIP :80
│       ├── 04.homepage-nginx-cert-manager__v1.12.3__Components_Full.yaml
│       ├── 05.homepage-nginx-letsencrypt-issuer_with_e-mail_ACME_registration__ClusterIssuer.yaml
│       └── 06.homepage-nginx__Ingress.yaml            # Ingress TLS letsencrypt-prod
│
└── 02.real_time/                       # ── Versão 2: Dashboard em tempo real ────────
    ├── README.md                       # Este arquivo
    ├── 00.UsefulScripts/
    │   ├── 01.deploy.sh                # Build ARM64 + push OCI + kubectl apply
    │   └── 00.useful_commands.txt
    │
    ├── 01.k8s/                         # Manifests Kubernetes
    │   ├── 00.Namespace.yaml           # Namespace k8s-dashboard
    │   ├── 01.RBAC.yaml               # ServiceAccount + ClusterRole read-only
    │   ├── 02.Backend_Deployment.yaml  # Deployment Spring Boot
    │   ├── 03.Backend_Service.yaml     # Service ClusterIP :8080
    │   ├── 04.Frontend_Deployment.yaml # Deployment Angular + NGINX
    │   ├── 05.Frontend_Service.yaml    # Service ClusterIP :80
    │   ├── 06.Ingress.yaml            # Ingress NGINX com TLS Let's Encrypt
    │   └── 07.Registry_Secret_README.txt
    │
    ├── 02.k8s_dashboard_backend/       # Spring Boot 3.4 (Java 21)
    │   ├── .gitignore                  # Ignora target/, .idea/, etc.
    │   ├── Dockerfile                  # Multi-stage build ARM64
    │   ├── pom.xml
    │   └── src/main/java/com/adailsilva/k8sdashboard/
    │       ├── K8sDashboardApplication.java
    │       ├── config/
    │       │   ├── KubernetesConfig.java  # Cliente K8s: in-cluster ou kubeconfig
    │       │   └── CorsConfig.java
    │       ├── controller/
    │       │   └── KubernetesController.java  # REST /api/k8s/*
    │       ├── dto/                           # 9 DTOs de resposta (Lombok @Builder)
    │       │   ├── ClusterSummaryDto.java
    │       │   ├── NodeDto.java
    │       │   ├── PodDto.java
    │       │   ├── ServiceDto.java
    │       │   ├── PortDto.java
    │       │   ├── IngressDto.java
    │       │   ├── IngressRuleDto.java
    │       │   ├── IngressPathDto.java
    │       │   └── NamespaceDto.java
    │       └── service/
    │           └── KubernetesService.java     # Consulta a API K8s + Metrics Server
    │
    └── 03.k8s_dashboard_frontend/      # Angular 19 (standalone components)
        ├── .gitignore                  # Ignora node_modules/, dist/, .angular/
        ├── Dockerfile                  # Multi-stage: Node build + NGINX serve
        ├── nginx.conf                  # SPA routing + proxy /api/ → backend
        ├── angular.json
        ├── package.json
        ├── tsconfig.json
        ├── tsconfig.app.json
        └── src/
            ├── index.html
            ├── main.ts
            ├── styles.scss             # Reset global + scan-line overlay
            ├── environments/
            │   ├── environment.ts             # Dev: http://localhost:8080/api/k8s
            │   └── environment.production.ts  # Prod: /api/k8s (relativo)
            └── app/
                ├── app.component.ts    # Root shell — apenas <router-outlet>
                ├── app.config.ts       # provideRouter, provideHttpClient, provideAnimations
                ├── app.routes.ts       # Lazy load DashboardPage
                ├── core/
                │   ├── models/
                │   │   └── k8s.models.ts          # Interfaces TypeScript (espelho dos DTOs)
                │   └── services/
                │       └── kubernetes.service.ts   # HTTP + polling streams (timer + shareReplay)
                └── features/
                    └── dashboard/
                        ├── pages/
                        │   ├── dashboard.page.ts    # Orquestrador: signals + subscriptions
                        │   ├── dashboard.page.html  # Template completo
                        │   └── dashboard.page.scss  # Estilos da página
                        └── components/
                            ├── cluster-canvas/     # Canvas animado com nós reais
                            ├── terminal/           # Typewriter com kubectl real
                            ├── node-cards/         # Cards CPU/MEM por nó
                            ├── metrics-strip/      # Faixa de 4 métricas do cluster
                            ├── pods-table/         # Tabela de pods com pills
                            ├── services-table/     # Tabela de services
                            └── ingress-table/      # Tabela de ingresses
```

---

## 01.static — Homepage Estática (NGINX)

Página de apresentação do cluster com visual **cyberpunk animado** — canvas com nós e pacotes voando, terminal typewriter simulado, cards de métricas e tabela de pods. Todos os dados são **estáticos** (hardcoded no HTML).

### Deploy rápido

```bash
cd 01.static/00.UsefulScripts/

# Deploy
chmod +x 01.deploy_homepage-nginx_script.sh
bash 01.deploy_homepage-nginx_script.sh

# Verificar
kubectl get pods,svc,ingress -n oci-devops
kubectl get certificate -n oci-devops

# Remover
chmod +x 02.destroy_homepage-nginx_script.sh
bash 02.destroy_homepage-nginx_script.sh
```

### Teste local com Docker

```bash
cd 01.static/docker/
docker compose up
# → http://localhost:8080
```

### Build da imagem ARM64

```bash
cd 01.static/

docker login -u '<NAMESPACE>/<seu_email>' -p '<auth_token>' gru.ocir.io

docker buildx build \
  --platform linux/arm64 \
  -t gru.ocir.io/<NAMESPACE>/homepage-80_platform_linux-arm64:latest \
  --no-cache --push .
```

---

## 02.real_time — Dashboard em Tempo Real

Substitui a homepage estática por um **dashboard interativo** que consulta a API real do Kubernetes a cada 30 segundos, exibindo dados reais de nós, pods, services e ingresses com o mesmo visual cyberpunk da versão estática.

### Arquitetura

```
Navegador (Angular 19)
    │
    │  HTTPS :443 — Ingress NGINX + TLS Let's Encrypt
    ▼
┌──────────────────────────────────────────────────────────────┐
│  Namespace: k8s-dashboard                                    │
│                                                              │
│  ┌───────────────────────┐   ClusterIP   ┌────────────────┐ │
│  │  Frontend             │ ────────────▶ │  Backend       │ │
│  │  Angular 19 + NGINX   │  /api/* proxy │  Spring Boot   │ │
│  │  Port: 80             │               │  Port: 8080    │ │
│  └───────────────────────┘               └───────┬────────┘ │
│                                                  │          │
│                                       ServiceAccount        │
│                                       (RBAC read-only)      │
└──────────────────────────────────────────────────┼──────────┘
                                                   │
                                         kubernetes.default.svc
                                                   │
                                     ┌─────────────▼──────────┐
                                     │  Kubernetes API         │
                                     │  nodes, pods, services  │
                                     │  ingresses, namespaces  │
                                     │  Metrics Server (CPU/RAM│
                                     └────────────────────────┘
```

### Pré-requisitos

| Ferramenta | Versão mínima | Função |
|---|---|---|
| **Java** | `21` | Build Spring Boot |
| **Maven** | `>= 3.9` | Gerenciador Spring Boot |
| **Node.js** | `>= 22` | Build Angular |
| **npm** | `>= 10` | Gerenciador Angular |
| **Docker** + Buildx | `>= 24` | Build imagens ARM64 |
| **kubectl** | `>= 1.31` | Deploy no cluster |

---

### Desenvolvimento Local

#### Backend (Spring Boot)

```bash
cd 02.k8s_dashboard_backend/

# Usa ~/.kube/config automaticamente (fora do cluster)
SPRING_PROFILES_ACTIVE=dev mvn spring-boot:run

# Ou com kubeconfig específico
SPRING_PROFILES_ACTIVE=dev \
KUBECONFIG_PATH=/home/adailsilva/.kube/config \
  mvn spring-boot:run
```

Backend disponível em `http://localhost:8080`. Testar:

```bash
curl http://localhost:8080/api/k8s/summary                     | jq
curl http://localhost:8080/api/k8s/nodes                       | jq
curl http://localhost:8080/api/k8s/pods                        | jq
curl "http://localhost:8080/api/k8s/pods?namespace=oci-devops" | jq
curl http://localhost:8080/api/k8s/services                    | jq
curl http://localhost:8080/api/k8s/ingresses                   | jq
curl http://localhost:8080/api/k8s/namespaces                  | jq
```

#### Frontend (Angular)

```bash
cd 03.k8s_dashboard_frontend/

npm install
npm start
# → http://localhost:4200
# Chama automaticamente http://localhost:8080/api/k8s (environment.ts)
```

---

### Build das Imagens ARM64

```bash
# Autenticar no OCI Container Registry
docker login \
  -u '<DOCKER_OBJECT_STORAGE_NAMESPACE>/<seu_email>' \
  -p '<auth_token>' \
  gru.ocir.io

# ── Backend ────────────────────────────────────────────────────
docker buildx build \
  --platform linux/arm64 \
  -t gru.ocir.io/<DOCKER_OBJECT_STORAGE_NAMESPACE>/k8s-dashboard-backend_platform_linux-arm64:latest \
  --no-cache --push \
  ./02.k8s_dashboard_backend

# ── Frontend ───────────────────────────────────────────────────
docker buildx build \
  --platform linux/arm64 \
  -t gru.ocir.io/<DOCKER_OBJECT_STORAGE_NAMESPACE>/k8s-dashboard-frontend_platform_linux-arm64:latest \
  --no-cache --push \
  ./03.k8s_dashboard_frontend
```

---

### Deploy no Cluster

#### 1. Cadastrar o subdomínio no DNS

No Registro.br (Modo Avançado), adicione um registro `A` apontando para o IP do NLB:

```
dashboard.adailsilva.com.br → <IP_DO_NLB>
```

> Ative o Modo Avançado com antecedência — pode levar até 2 horas para ser processado.

#### 2. Substituir os placeholders nos manifests

```bash
cd 01.k8s/

# Domínio
sed -i 's/dashboard.seudominio.com.br/dashboard.adailsilva.com.br/g' 06.Ingress.yaml

# Namespace OCI (Object Storage Namespace)
NAMESPACE_OCI="<DOCKER_OBJECT_STORAGE_NAMESPACE>"
sed -i "s/<DOCKER_OBJECT_STORAGE_NAMESPACE>/${NAMESPACE_OCI}/g" \
  02.Backend_Deployment.yaml \
  04.Frontend_Deployment.yaml
```

#### 3. Criar o Secret de acesso ao OCI Registry

```bash
kubectl create secret docker-registry oci-registry-secret \
  --docker-server=gru.ocir.io \
  --docker-username='<DOCKER_OBJECT_STORAGE_NAMESPACE>/<seu_email>' \
  --docker-password='<auth_token>' \
  --docker-email='<seu_email>' \
  -n k8s-dashboard
```

#### 4. Aplicar os manifests na ordem correta

```bash
cd 01.k8s/

kubectl apply -f 00.Namespace.yaml
kubectl apply -f 01.RBAC.yaml
kubectl apply -f 02.Backend_Deployment.yaml
kubectl apply -f 03.Backend_Service.yaml
kubectl apply -f 04.Frontend_Deployment.yaml
kubectl apply -f 05.Frontend_Service.yaml
kubectl apply -f 06.Ingress.yaml
```

Ou use o script completo de uma vez:

```bash
cd 00.UsefulScripts/
chmod +x 01.deploy.sh

# Edite as variáveis no topo do script antes de executar
DOCKER_PASSWORD='<auth_token>' bash 01.deploy.sh
```

#### 5. Verificar o deploy

```bash
# Pods, services e ingress
kubectl get pods     -n k8s-dashboard
kubectl get services -n k8s-dashboard
kubectl get ingress  -n k8s-dashboard

# Certificado TLS (aguardar até 2 minutos)
kubectl get certificate -n k8s-dashboard
kubectl describe certificate -n k8s-dashboard

# Logs em tempo real
kubectl logs -l app=k8s-dashboard-backend  -n k8s-dashboard -f
kubectl logs -l app=k8s-dashboard-frontend -n k8s-dashboard -f

# Confirmar RBAC
kubectl auth can-i list pods \
  --as=system:serviceaccount:k8s-dashboard:k8s-dashboard-backend
# Deve retornar: yes
```

---

### Endpoints da API

| Método | Endpoint | Filtro | Descrição |
|---|---|---|---|
| `GET` | `/api/k8s/summary` | — | Contadores gerais do cluster |
| `GET` | `/api/k8s/nodes` | — | Nós com CPU/MEM via Metrics Server |
| `GET` | `/api/k8s/pods` | `?namespace=<ns>` | Pods (todos ou por namespace) |
| `GET` | `/api/k8s/services` | `?namespace=<ns>` | Services |
| `GET` | `/api/k8s/ingresses` | `?namespace=<ns>` | Ingresses |
| `GET` | `/api/k8s/namespaces` | — | Namespaces |
| `GET` | `/api/k8s/health` | — | Health check simples |
| `GET` | `/actuator/health` | — | Spring Boot Actuator |

---

### Troubleshooting

#### ❌ Backend `CrashLoopBackOff` — erro `Forbidden` na API K8s

O RBAC não está correto ou não foi aplicado.

```bash
kubectl describe clusterrolebinding k8s-dashboard-readonly-binding

kubectl auth can-i list pods \
  --as=system:serviceaccount:k8s-dashboard:k8s-dashboard-backend
# Deve retornar: yes

# Se retornar "no", reaplicar o RBAC:
kubectl apply -f 01.k8s/01.RBAC.yaml
```

#### ❌ Métricas CPU/MEM aparecem como `–`

O Metrics Server não está instalado ou não está respondendo.

```bash
kubectl get pods -n kube-system | grep metrics
kubectl top nodes   # deve listar CPU/MEM por nó
```

> Instale o Metrics Server seguindo a documentação do repositório `k8s-arm-oci-always-free` (módulo `01.metrics_server`).

#### ❌ Frontend `502 Bad Gateway` em `/api/`

O NGINX não está alcançando o backend via ClusterIP.

```bash
# Verificar se o Service existe e tem Endpoints
kubectl get svc     k8s-dashboard-backend-service -n k8s-dashboard
kubectl get endpoints k8s-dashboard-backend-service -n k8s-dashboard

# Logs do NGINX
kubectl logs -l app=k8s-dashboard-frontend -n k8s-dashboard
```

#### ❌ Pods em `ImagePullBackOff`

O Secret de pull do OCI Registry está ausente ou incorreto.

```bash
kubectl get secret oci-registry-secret -n k8s-dashboard
kubectl describe pod <nome-do-pod> -n k8s-dashboard | grep -A8 "Events"

# Recriar o secret
kubectl delete secret oci-registry-secret -n k8s-dashboard
kubectl create secret docker-registry oci-registry-secret \
  --docker-server=gru.ocir.io \
  --docker-username='<NAMESPACE>/<seu_email>' \
  --docker-password='<auth_token>' \
  --docker-email='<seu_email>' \
  -n k8s-dashboard
```

#### ❌ Let's Encrypt não emite o certificado TLS

O DNS ainda não propagou ou não aponta para o IP correto.

```bash
# Verificar propagação
dig +short dashboard.adailsilva.com.br
dig +short dashboard.adailsilva.com.br @8.8.8.8

# Status do desafio ACME
kubectl describe challenges -n k8s-dashboard
kubectl describe certificate -n k8s-dashboard
```

---

<div align="center">

**🏠 Homepage · ☸️ Kubernetes · 🦾 ARM · ☁️ OCI Always Free**

`01.static` — NGINX estático · `02.real_time` — Angular 19 + Spring Boot 3.4

</div>
