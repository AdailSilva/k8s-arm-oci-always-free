# ☸️ Kubernetes on ARM — OCI Always Free

> Implantação **totalmente automatizada** de um cluster Kubernetes em arquitetura **ARM (AArch64)** na Oracle Cloud Infrastructure, utilizando exclusivamente os recursos **Always Free** — sem nenhum custo.
> A infraestrutura é provisionada como código via **Terraform** / **OpenTofu**, e as aplicações são gerenciadas com manifests Kubernetes organizados por módulo.

---

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Arquitetura](#arquitetura)
- [Módulos de Infraestrutura](#módulos-de-infraestrutura)
- [Aplicações Padrão do Cluster](#aplicações-padrão-do-cluster)
  - [00. Homepage (nginx)](#00-homepage-nginx)
  - [01. Metrics Server](#01-metrics-server)
  - [02. UDP Health Check — NLB OCI](#02-udp-health-check--nlb-oci)
- [Pré-requisitos](#pré-requisitos)
- [Recursos Always Free Utilizados](#recursos-always-free-utilizados)
- [Tecnologias e Componentes](#tecnologias-e-componentes)
- [Estrutura do Repositório](#estrutura-do-repositório)
- [Configuração de DNS — Subdomínios Obrigatórios](#configuração-de-dns--subdomínios-obrigatórios)
  - [Quando cadastrar os subdomínios](#quando-cadastrar-os-subdomínios)
  - [Subdomínios necessários neste projeto](#subdomínios-necessários-neste-projeto)
  - [Exemplo prático — Registro .com.br (Registro.br)](#exemplo-prático--registro-combr-registrobr)
  - [Verificar a propagação do DNS](#verificar-a-propagação-do-dns)
  - [Atualizar os subdomínios nos manifestos](#atualizar-os-subdomínios-nos-manifestos-antes-do-deploy)
- [Configuração Inicial](#configuração-inicial)
- [Implantação da Infraestrutura](#implantação-da-infraestrutura)
- [Implantando as Aplicações Padrão](#implantando-as-aplicações-padrão)
- [Pré-requisito: OCI File Storage Service (FSS)](#pré-requisito-oci-file-storage-service-fss)
  - [Por que o FSS é necessário](#por-que-o-fss-é-necessário)
  - [Criando o FSS no console OCI](#criando-o-fss-no-console-oci)
  - [Script de montagem e preparação dos diretórios](#script-de-montagem-e-preparação-dos-diretórios)
  - [Como executar em todos os nós](#como-executar-em-todos-os-nós)
  - [Tornar a montagem permanente (fstab)](#tornar-a-montagem-permanente-fstab)
- [Mapa de Serviços e Links de Acesso](#mapa-de-serviços-e-links-de-acesso)
  - [Serviços HTTP/HTTPS — acesso pelo navegador](#serviços-httphttps--acesso-pelo-navegador)
  - [Serviços de rede — acesso direto via IP/porta](#serviços-de-rede--acesso-direto-via-ipporta)
  - [Serviços internos ao cluster — port-forward](#serviços-internos-ao-cluster--acesso-via-kubectl)
- [Acesso ao Cluster](#acesso-ao-cluster)
- [CI/CD com GitHub Actions](#cicd-com-github-actions)
- [OCI Container Registry](#oci-container-registry)
- [Destruindo a Infraestrutura](#destruindo-a-infraestrutura)
- [Troubleshooting](#troubleshooting)
- [Contribuindo](#contribuindo)
- [Licença](#licença)

---

## Visão Geral

Este projeto provisiona um cluster Kubernetes completo e funcional na **Oracle Cloud Infrastructure (OCI)** sem nenhum custo, aproveitando o plano **Always Free** da Oracle — que inclui instâncias ARM Ampere A1 com até 4 OCPUs e 24 GB de RAM por conta.

A infraestrutura é composta por 1 nó Control Plane e 3 nós Worker em arquitetura **ARM (AArch64)**, gerenciada inteiramente como código via **Terraform** / **OpenTofu**, e inclui três aplicações de infraestrutura base que compõem o ambiente operacional mínimo do cluster:

- **Homepage** — página de apresentação do domínio, servida via NGINX com TLS automático pelo cert-manager e Let's Encrypt
- **Metrics Server** — coleta de métricas de CPU e memória dos nós e pods, necessário para o Kubernetes Dashboard e para o `kubectl top`
- **UDP Health Check** — servidor UDP em Java que responde a requisições `PING/PONG`, necessário para liberar as verificações de saúde UDP no Network Load Balancer da OCI e manter o Overall Health `OK`

---

## Arquitetura

```
Internet
    │
    ▼
┌──────────────────────────────────────────────────────────────┐
│              IP Público Reservado (OCI)                      │
│                                                              │
│          Network Load Balancer (Always Free)                 │
│   ┌──────────────────────────────────────────────────────┐   │
│   │  TCP :22    → leader        (SSH)                    │   │
│   │  TCP :6443  → leader        (kubectl / API Server)   │   │
│   │  TCP :80    → workers       (NodePort 30080 - HTTP)  │   │
│   │  TCP :443   → workers       (NodePort 30443 - HTTPS) │   │
│   │  UDP :1700  → workers       (UDP Health Check)       │   │
│   │  UDP :1710  → workers       (UDP Health Check)       │   │
│   └──────────────────────────────────────────────────────┘   │
│                                                              │
│   Virtual Cloud Network (VCN) — 10.0.0.0/16                 │
│   ┌──────────────────────────────────────────────────────┐   │
│   │  Subnet Pública — 10.0.0.0/24                       │   │
│   │                                                      │   │
│   │  ┌──────────────────────────────────────────────┐   │   │
│   │  │  leader (Control Plane)                      │   │   │
│   │  │  VM.Standard.A1.Flex · Ubuntu 24.04 ARM64    │   │   │
│   │  │  1 OCPU · 3 GB RAM · 50 GB Boot Volume       │   │   │
│   │  └──────────────────────────────────────────────┘   │   │
│   │                                                      │   │
│   │  ┌────────────┐  ┌────────────┐  ┌────────────┐    │   │
│   │  │  worker-0  │  │  worker-1  │  │  worker-2  │    │   │
│   │  │  A1.Flex   │  │  A1.Flex   │  │  A1.Flex   │    │   │
│   │  │  1 OCPU    │  │  1 OCPU    │  │  1 OCPU    │    │   │
│   │  │  7 GB RAM  │  │  7 GB RAM  │  │  7 GB RAM  │    │   │
│   │  │  50 GB     │  │  50 GB     │  │  50 GB     │    │   │
│   │  └────────────┘  └────────────┘  └────────────┘    │   │
│   └──────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘

Total ARM: 4 OCPUs + 24 GB RAM → exatamente no limite Always Free

Namespace oci-devops
├── Homepage (nginx-deployment)         → k8s.seudominio.com.br/
├── UDP Health Check :1700 (DaemonSet)  → Libera porta UDP 1700 no NLB
└── UDP Health Check :1710 (DaemonSet)  → Libera porta UDP 1710 no NLB

Namespace kube-system
└── Metrics Server                      → kubectl top / Kubernetes Dashboard
```

> O acesso SSH aos workers é feito via **SSH jump** através do `leader`, que serve como bastion host. O Load Balancer roteia a porta 22 diretamente ao `leader`.

---

## Módulos de Infraestrutura

O código Terraform é organizado em módulos executados sequencialmente:

| Módulo | Diretório | Responsabilidade |
|---|---|---|
| `compartment` | `./compartment` | Cria o compartimento OCI `k8s-on-arm-oci-always-free` |
| `network` | `./network` | VCN, subnet pública, Security Lists, Load Balancer, IP reservado |
| `compute` | `./compute` | Instâncias ARM: 1 leader + 3 workers (Ubuntu 24.04 AArch64) |
| `k8s` | `./k8s` | Bootstrap via kubeadm, join dos workers, CNI Flannel, kubeconfig |
| `k8s_scaffold` | `./k8s-scaffold` | Apps de scaffolding: Ingress NGINX, cert-manager, Dashboard, LetsEncrypt |
| `oci-infra_ci_cd` | `./oci_artifacts_container_repository` | Repositórios ARM64 no OCI Container Registry |

---

## Aplicações Padrão do Cluster

Após a infraestrutura estar de pé, três aplicações são implantadas manualmente no namespace **`oci-devops`** usando os manifests organizados em `00.homepage/`, `01.metrics_server/` e `02.udp_health_check-nlb_oci/`. Cada uma possui scripts de deploy e destroy prontos.

### 00. Homepage (nginx)

Serve a página de apresentação do domínio principal do cluster, acessível via HTTPS com certificado TLS emitido automaticamente pelo **cert-manager + Let's Encrypt**.

**Fluxo de acesso:**
```
https://k8s.seudominio.com.br
    → NLB :443
    → NodePort 30443 (workers)
    → Ingress NGINX
    → Service nginx-service :80 (ClusterIP)
    → Pod nginx-deployment (imagem ARM64 do OCI Container Registry)
```

**Tecnologias:** NGINX, cert-manager v1.12.3, Let's Encrypt (produção e staging), Ingress NGINX

**Imagem:** `gru.ocir.io/<namespace>/homepage-80_platform_linux-arm64:latest`

**Kubernetes resources (namespace `oci-devops`):**

| Kind | Nome | Descrição |
|---|---|---|
| `Namespace` | `oci-devops` | Namespace principal das aplicações do projeto |
| `Deployment` | `nginx-deployment` | 1 réplica do NGINX servindo o `index.html` |
| `Service` | `nginx-service` | ClusterIP na porta 80 |
| `Ingress` | `nginx-ingress` | TLS via `letsencrypt-prod`, host `k8s.seudominio.com.br` |
| `ClusterIssuer` | `letsencrypt-prod` | Emissão de certificados via ACME HTTP-01 |
| `ClusterIssuer` | `letsencrypt-staging` | Ambiente de testes do Let's Encrypt |

**Deploy / Destroy:**
```bash
cd 00.homepage/00.UsefulScripts/

chmod +x 01.deploy_homepage-nginx_script.sh
bash 01.deploy_homepage-nginx_script.sh

# Para remover:
chmod +x 02.destroy_homepage-nginx_script.sh
bash 02.destroy_homepage-nginx_script.sh
```

**Build da imagem (ARM64) para o OCI Container Registry:**
```bash
# Autenticar no OCI Registry
docker login -u <namespace>/<seu_email> -p "<auth_token>" gru.ocir.io

# Build e push para ARM64
docker buildx build \
  --platform linux/arm64 \
  -t gru.ocir.io/<namespace>/homepage-80_platform_linux-arm64:latest \
  --no-cache --push .
```

---

### 01. Metrics Server

Instala o **Metrics Server** no cluster, habilitando a coleta de métricas de uso de CPU e memória de nós e pods. É um pré-requisito para o funcionamento pleno do **Kubernetes Dashboard** e do comando `kubectl top`.

> O Metrics Server é configurado com `--kubelet-insecure-tls` e `--kubelet-preferred-address-types=InternalIP` para funcionar corretamente com as instâncias ARM da OCI, onde os certificados do kubelet não possuem SAN validável externamente.

**Kubernetes resources (namespace `kube-system`):**

| Kind | Nome | Versão da imagem |
|---|---|---|
| `ServiceAccount` | `metrics-server` | — |
| `ClusterRole` | `system:aggregated-metrics-reader` + `metrics-server` | — |
| `ClusterRoleBinding` | `metrics-server` | — |
| `RoleBinding` | `metrics-server-auth-reader` | — |
| `Deployment` | `metrics-server` | `registry.k8s.io/metrics-server/metrics-server:v0.7.2` |
| `Service` | `metrics-server` | ClusterIP :443 |
| `APIService` | `v1beta1.metrics.k8s.io` | Registra a API de métricas no cluster |

**Deploy / Destroy:**
```bash
cd 01.metrics_server/00.UsefulScripts/

chmod +x 01.deploy_metrics_server_script.sh
bash 01.deploy_metrics_server_script.sh

# Para remover:
chmod +x 02.destroy_metrics_server_script.sh
bash 02.destroy_metrics_server_script.sh
```

**Verificar funcionamento:**
```bash
kubectl top nodes
kubectl top pods -A
```

---

### 02. UDP Health Check — NLB OCI

#### Por que este serviço é necessário

O **Network Load Balancer (NLB) da Oracle Cloud** monitora continuamente a saúde de cada listener configurado. Para cada porta — incluindo portas UDP — o NLB executa verificações de saúde periódicas nos backends (os nós workers). Enquanto essas verificações não passarem, o status do NLB fica em **`Overall Health: Critical`** no console da OCI, e o tráfego destinado àquelas portas não é roteado.

O problema com UDP é que, ao contrário do TCP, não há handshake — o NLB precisa que a aplicação escutando na porta responda ativamente a um pacote de verificação. Sem uma resposta, o backend é marcado como **unhealthy** e a porta permanece bloqueada, mantendo o Overall Health em estado crítico mesmo com o cluster e as outras portas TCP funcionando perfeitamente.

```
Estado sem o UDP Health Check:
┌─────────────────────────────────────────────┐
│  NLB Overall Health: ⚠️  CRITICAL            │
│                                             │
│  Listener TCP  :22   → ✅ Healthy           │
│  Listener TCP  :6443 → ✅ Healthy           │
│  Listener TCP  :80   → ✅ Healthy           │
│  Listener TCP  :443  → ✅ Healthy           │
│  Listener UDP  :1700 → ❌ Critical          │  ← sem resposta UDP
│  Listener UDP  :1710 → ❌ Critical          │  ← sem resposta UDP
└─────────────────────────────────────────────┘

Estado com o UDP Health Check implantado:
┌─────────────────────────────────────────────┐
│  NLB Overall Health: ✅ OK                  │
│                                             │
│  Listener TCP  :22   → ✅ Healthy           │
│  Listener TCP  :6443 → ✅ Healthy           │
│  Listener TCP  :80   → ✅ Healthy           │
│  Listener TCP  :443  → ✅ Healthy           │
│  Listener UDP  :1700 → ✅ Healthy           │  ← PONG recebido
│  Listener UDP  :1710 → ✅ Healthy           │  ← PONG recebido
└─────────────────────────────────────────────┘
```

> ⚠️ **O Overall Health do NLB só fica `OK` quando todos os listeners estão saudáveis.** Enquanto as portas UDP 1700 e 1710 estiverem sem resposta, o status permanece `Critical` — mesmo que todo o tráfego TCP esteja fluindo normalmente. Este serviço é, portanto, **obrigatório** para um ambiente operacional limpo na OCI.

#### Como funciona

O `UdpHealthCheckServer.java` é um servidor UDP minimalista em Java que:
1. Abre um socket UDP na porta configurada
2. Aguarda um pacote com a mensagem `PING`
3. Responde imediatamente com `PONG` ao remetente
4. Repete o ciclo indefinidamente

```
Ciclo de verificação do NLB (a cada ~10 segundos):

NLB OCI
 ├── Listener UDP :1700
 │     ├── Health Check → envia "PING" UDP para worker-0 :1700
 │     │                       └── UdpHealthCheckServer (hostNetwork: true)
 │     │                               └── recebe "PING" → responde "PONG"
 │     │                                       └── ✅ worker-0 marcado como Healthy
 │     ├── Health Check → envia "PING" UDP para worker-1 :1700
 │     │                       └── UdpHealthCheckServer (hostNetwork: true)
 │     │                               └── recebe "PING" → responde "PONG"
 │     │                                       └── ✅ worker-1 marcado como Healthy
 │     └── Health Check → envia "PING" UDP para worker-2 :1700
 │                             └── UdpHealthCheckServer (hostNetwork: true)
 │                                     └── recebe "PING" → responde "PONG"
 │                                             └── ✅ worker-2 marcado como Healthy
 │
 └── Listener UDP :1710
       ├── Health Check → envia "PING" UDP para worker-0 :1710  → ✅ Healthy
       ├── Health Check → envia "PING" UDP para worker-1 :1710  → ✅ Healthy
       └── Health Check → envia "PING" UDP para worker-2 :1710  → ✅ Healthy

Resultado: todos os 6 backends (3 workers × 2 portas) Healthy → Overall Health: ✅ OK
```

O uso de `hostNetwork: true` nos pods é intencional e essencial: faz com que o servidor UDP escute diretamente no IP da interface de rede do nó worker, tornando-o alcançável pelo NLB sem intermediação do kube-proxy — que não funciona com UDP da mesma forma que com TCP.

#### Kubernetes resources (namespace `oci-devops`)

| Kind | Nome | Porta | Réplicas / Escopo | Descrição |
|---|---|---|---|---|
| `Deployment` | `udp-app-with-healthcheck-1700-deployment` | UDP 1700 | 1 réplica | Pod com `hostNetwork: true` |
| `DaemonSet` | `udp-app-with-healthcheck-1700-daemon-set` | UDP 1700 | Todos os workers | Garante presença em cada nó |
| `Service` | `udp-1700-app-service` | UDP 1700 | ClusterIP | Seletor para o Deployment |
| `Service` | `udp-1700-daemon-set-service` | UDP 1700 | ClusterIP | Seletor para o DaemonSet |
| `Deployment` | `udp-app-with-healthcheck-1710-deployment` | UDP 1710 | 1 réplica | Pod com `hostNetwork: true` |
| `DaemonSet` | `udp-app-with-healthcheck-1710-daemon-set` | UDP 1710 | Todos os workers | Garante presença em cada nó |
| `Service` | `udp-1710-app-service` | UDP 1710 | ClusterIP | Seletor para o Deployment |
| `Service` | `udp-1710-daemon-set-service` | UDP 1710 | ClusterIP | Seletor para o DaemonSet |

#### Imagens no OCI Container Registry

```
gru.ocir.io/<DOCKER_OBJECT_STORAGE_NAMESPACE>/udp-health-check-server-1700_platform_linux-arm64:latest
gru.ocir.io/<DOCKER_OBJECT_STORAGE_NAMESPACE>/udp-health-check-server-1710_platform_linux-arm64:latest
```

#### Passo 1 — Build das imagens ARM64

Antes de implantar, as imagens precisam existir no OCI Container Registry.

```bash
# Habilitar suporte a ARM64 no Docker (apenas uma vez por máquina)
docker run --privileged --rm tonistiigi/binfmt --install all

# Autenticar no OCI Container Registry
docker login -u '<DOCKER_OBJECT_STORAGE_NAMESPACE>/<seu_email>' \
             -p '<auth_token>' \
             gru.ocir.io

# Entrar na pasta da aplicação UDP
cd 02.udp_health_check-nlb_oci/

# Build e push — imagem para a porta 1700
docker buildx build \
  --platform linux/arm64 \
  -t gru.ocir.io/<DOCKER_OBJECT_STORAGE_NAMESPACE>/udp-health-check-server-1700_platform_linux-arm64:latest \
  --no-cache --push .

# Build e push — imagem para a porta 1710
docker buildx build \
  --platform linux/arm64 \
  -t gru.ocir.io/<DOCKER_OBJECT_STORAGE_NAMESPACE>/udp-health-check-server-1710_platform_linux-arm64:latest \
  --no-cache --push .
```

#### Passo 2 — Criar o Secret de acesso ao OCI Registry

O Kubernetes precisa de credenciais para fazer pull das imagens privadas do OCI Registry:

```bash
# Criar o namespace se ainda não existir
kubectl create namespace oci-devops --dry-run=client -o yaml | kubectl apply -f -

# Criar o Secret de autenticação no namespace oci-devops
kubectl create secret docker-registry oci-registry-secret \
  --docker-server=gru.ocir.io \
  --docker-username='<DOCKER_OBJECT_STORAGE_NAMESPACE>/<seu_email>' \
  --docker-password='<auth_token>' \
  --docker-email='<seu_email>' \
  -n oci-devops

# Confirmar a criação
kubectl get secret oci-registry-secret -n oci-devops
```

#### Passo 3 — Implantar os serviços UDP

```bash
cd 02.udp_health_check-nlb_oci/00.UsefulScripts/

chmod +x 01.deploy_udp_health_check_server_nlb_oci_script.sh
bash 01.deploy_udp_health_check_server_nlb_oci_script.sh
```

Ou aplicar os manifests manualmente na ordem correta:

```bash
cd 02.udp_health_check-nlb_oci/kubernetes/

kubectl apply -f 01.create__Namespace.yaml
kubectl apply -f 02.udp-health-check-server-1700__Deployment.yaml    -n oci-devops
kubectl apply -f 03.udp-health-check-server-1700__Service.yaml        -n oci-devops
kubectl apply -f 04.udp-health-check-server-1700__DaemonSet.yaml      -n oci-devops
kubectl apply -f 05.udp-health-check-server-1700__Service-DaemonSet.yaml -n oci-devops
kubectl apply -f 06.udp-health-check-server-1710__Deployment.yaml    -n oci-devops
kubectl apply -f 07.udp-health-check-server-1710__Service.yaml        -n oci-devops
kubectl apply -f 08.udp-health-check-server-1710__DaemonSet.yaml      -n oci-devops
kubectl apply -f 09.udp-health-check-server-1710__Service-DaemonSet.yaml -n oci-devops
```

#### Passo 4 — Verificar o estado dos pods

```bash
# Listar todos os pods do namespace oci-devops
kubectl get pods -n oci-devops -o wide

# Verificar os DaemonSets (deve haver 1 pod por worker = 3 pods por DaemonSet)
kubectl get daemonset -n oci-devops

# Saída esperada:
# NAME                                      DESIRED   CURRENT   READY   NODE SELECTOR
# udp-app-with-healthcheck-1700-daemon-set  3         3         3       <none>
# udp-app-with-healthcheck-1710-daemon-set  3         3         3       <none>

# Descrever um pod para confirmar hostNetwork: true
kubectl describe pod -l app=udp-1700 -n oci-devops | grep -A2 "Host Network"
```

#### Passo 5 — Testar o PING/PONG manualmente

Para confirmar que o servidor está respondendo antes de aguardar o NLB:

```bash
# A partir de qualquer máquina com acesso à rede (substituir pelo IP de um worker)
echo "PING" | nc -u -w2 <IP_DO_WORKER> 1700
# Resposta esperada: PONG

echo "PING" | nc -u -w2 <IP_DO_WORKER> 1710
# Resposta esperada: PONG

# Ou a partir de dentro do cluster (em um pod de debug)
kubectl run debug --image=busybox --restart=Never -it --rm -- \
  sh -c 'echo "PING" | nc -u -w2 <IP_DO_WORKER> 1700'
```

#### Passo 6 — Confirmar o Overall Health no console da OCI

Após implantar os serviços e aguardar de 1 a 2 minutos para o NLB executar as verificações:

1. Acesse o **Console OCI** → **Networking → Load Balancers → Network Load Balancers**
2. Selecione o NLB do cluster (`k8s-arm-oci-always-free` ou o nome configurado)
3. Verifique o campo **Overall Health** — deve exibir `OK` (verde)
4. Em **Backend Sets**, confirme que todos os backends nas portas 1700 e 1710 estão com status `Healthy`

#### Remover os serviços UDP

```bash
cd 02.udp_health_check-nlb_oci/00.UsefulScripts/

chmod +x 02.destroy_udp_health_check_server_nlb_oci_script.sh
bash 02.destroy_udp_health_check_server_nlb_oci_script.sh
```

> ⚠️ Remover estes serviços sem antes remover os listeners UDP do NLB fará o **Overall Health voltar para `Critical`** imediatamente.

---

## Pré-requisitos

### Conta Oracle Cloud

- Conta ativa na [Oracle Cloud](https://cloud.oracle.com) com o plano **Always Free** disponível
- Tenancy OCID, User OCID, API Key Fingerprint e chave privada configurados
- Verifique os limites da sua região em **Governance → Limits, Quotas and Usage** — o limite de 4 OCPUs ARM é compartilhado por toda a conta

### Ferramentas Locais

| Ferramenta | Versão Mínima | Descrição |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | `>= 1.3` | Provisionamento IaC (ou use OpenTofu) |
| [OpenTofu](https://opentofu.org/docs/intro/install/) | `>= 1.6` | Fork open-source do Terraform |
| [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) | `>= 3.x` | Interação com a OCI via terminal |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | `>= 1.31` | Gerenciamento do cluster |
| [Docker](https://docs.docker.com/engine/install/) com Buildx | `>= 24.x` | Build de imagens ARM64 via `docker buildx` |
| [Git](https://git-scm.com/) | `>= 2.x` | Controle de versão |

> O projeto usa o **provider OCI** `>= 6.35.0` e o **provider null** `3.1.0`.

### Chave SSH (Ed25519)

```bash
ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C "seu_email@seudominio.com"
```

Caminhos esperados:
- **Linux/macOS:** `~/.ssh/id_ed25519` e `~/.ssh/id_ed25519.pub`
- **Windows:** `C:\Users\..\.ssh\id_ed25519` e `C:\Users\..\.ssh\id_ed25519.pub`

### Chave de API OCI

```bash
mkdir -p ~/.oci
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem
```

Adicione `oci_api_key_public.pem` em **Identity → Users → (seu usuário) → API Keys → Add API Key** e copie o fingerprint exibido.

---

## Recursos Always Free Utilizados

| Recurso OCI | Shape / Tipo | Configuração | Qtd |
|---|---|---|---|
| **Instância ARM (leader)** | `VM.Standard.A1.Flex` | 1 OCPU · 3 GB RAM · 50 GB Boot Volume | 1 |
| **Instância ARM (workers)** | `VM.Standard.A1.Flex` | 1 OCPU · 7 GB RAM · 50 GB Boot Volume | 3 |
| **Network Load Balancer** | Always Free NLB | 10 Mbps | 1 |
| **IP Público Reservado** | `RESERVED` | Fixo, persistente mesmo após destroy | 1 |
| **Virtual Cloud Network** | VCN + Subnet Pública | CIDR `10.0.0.0/16` / `10.0.0.0/24` | 1 |
| **OCI Container Registry** | Always Free | Repositórios de imagens ARM64 | Ilimitado* |

**Total ARM:** 4 OCPUs + 24 GB RAM — exatamente no limite Always Free.

> ⚠️ O **IP Público Reservado** e as **instâncias de compute** possuem `prevent_destroy = true` no código Terraform, protegendo contra destruição acidental. Para removê-los é necessário editar os arquivos `.tf` antes de executar o `destroy`.

---

## Tecnologias e Componentes

### Infraestrutura

| Tecnologia | Detalhe | Função |
|---|---|---|
| **Terraform / OpenTofu** | OCI Provider `>= 6.35.0`, null `3.1.0` | IaC — provisionamento completo |
| **Oracle Cloud (OCI)** | Ampere A1 ARM | Plataforma de nuvem |
| **Ubuntu Server** | `24.04 LTS (AArch64)` | SO das instâncias |
| **Image OCI** | `Canonical-Ubuntu-24.04-aarch64-2026.02.28-0` | Imagem base utilizada |

### Kubernetes (Bootstrap)

| Componente | Versão | Função |
|---|---|---|
| **kubeadm** | `v1.31` (canal estável) | Bootstrap do cluster |
| **kubelet** | `v1.31` | Agente em cada nó |
| **kubectl** | `v1.31` | CLI de gerenciamento |
| **containerd** | Via Docker APT | Container runtime (CRI) |
| **Flannel** | Última estável | CNI — rede dos Pods (`10.244.0.0/16`) |

> O `kubeadm init` usa `--ignore-preflight-errors=NumCPU,Mem` para contornar os requisitos mínimos padrão, viabilizando o uso das shapes Always Free.

### Aplicações do Scaffold (Terraform)

| Aplicação | Namespace | Função |
|---|---|---|
| **NGINX Ingress Controller** | `ingress-nginx` | Ingress HTTP/HTTPS (NodePort 30080/30443) |
| **cert-manager** | `cert-manager` | Gerenciamento automático de certificados TLS |
| **Let's Encrypt Issuer** | `cert-manager` | Certificados HTTPS gratuitos via ACME |
| **Kubernetes Dashboard** | `kubernetes-dashboard` | Interface Web do cluster |

### Aplicações Padrão (Manifests)

| Aplicação | Namespace | Versão / Imagem | Função |
|---|---|---|---|
| **Homepage (NGINX)** | `oci-devops` | `nginx:latest` (ARM64) | Página de apresentação do domínio |
| **Metrics Server** | `kube-system` | `metrics-server:v0.7.2` | Métricas de CPU/RAM para Dashboard e `kubectl top` |
| **UDP Health Check :1700** | `oci-devops` | Java (ARM64, OCI Registry) | Libera porta UDP 1700 no NLB (PING/PONG) |
| **UDP Health Check :1710** | `oci-devops` | Java (ARM64, OCI Registry) | Libera porta UDP 1710 no NLB (PING/PONG) |

---

## Estrutura do Repositório

```
.
├── README.md
├── LICENSE
│
├── main.tf                          # Orquestra todos os módulos Terraform
├── inputs.tf                        # Variáveis globais
├── providers.tf                     # Providers OCI (>= 6.35.0) e null (3.1.0)
├── variables.auto.tfvars            # Suas credenciais reais (não versionar!)
├── variables.auto.tfvars.example    # Template para novos usuários
│
├── compartment/                     # Módulo: Compartimento OCI
├── network/                         # Módulo: VCN, Subnet, LB, IP
├── compute/                         # Módulo: VMs ARM leader + workers
├── k8s/                             # Módulo: Bootstrap Kubernetes
│   └── scripts/                     # Scripts de init/join/reset/network
├── k8s-scaffold/                    # Módulo: Apps de scaffolding
│   └── apps/                        # YAMLs: Ingress, cert-manager, Dashboard
├── oci_artifacts_container_repository/  # Módulo: OCI Container Registry
│
├── 00.homepage/                     # App: Página inicial do domínio
│   ├── Dockerfile                   # FROM nginx:latest + index.html
│   ├── index.html                   # Página HTML da homepage
│   ├── ci_cd.yaml                   # GitHub Actions: build ARM64 + deploy
│   ├── docker/                      # docker-compose para teste local
│   ├── 00.UsefulScripts/            # Scripts de deploy e destroy
│   │   ├── 01.deploy_homepage-nginx_script.sh
│   │   └── 02.destroy_homepage-nginx_script.sh
│   └── kubernetes/
│       ├── 01.homepage-nginx__Namespace.yaml          # Namespace oci-devops
│       ├── 02.homepage-nginx__Deployment.yaml         # Deployment NGINX ARM64
│       ├── 03.homepage-nginx__Service.yaml            # Service ClusterIP :80
│       ├── 04.homepage-nginx-cert-manager__...yaml    # cert-manager v1.12.3 completo
│       ├── 05.homepage-nginx-letsencrypt-issuer__...yaml  # ClusterIssuers prod + staging
│       └── 06.homepage-nginx__Ingress.yaml            # Ingress TLS letsencrypt-prod
│
├── 01.metrics_server/               # App: Metrics Server
│   ├── 00.UsefulScripts/
│   │   ├── 01.deploy_metrics_server_script.sh
│   │   └── 02.destroy_metrics_server_script.sh
│   └── kubernetes/
│       ├── 00.metrics-server__Full.yaml               # Manifesto único completo
│       ├── 01.metrics-server__Namespace.yaml
│       ├── 02.metrics-server__ServiceAccount.yaml
│       ├── 03.metrics-server__ClusterRole.yaml
│       ├── 04.metrics-server__RoleBinding.yaml
│       ├── 05.metrics-server__ClusterRoleBinding.yaml
│       ├── 06.metrics-server__Deployment.yaml         # metrics-server:v0.7.2
│       ├── 07.metrics-server__Service.yaml
│       └── 08.metrics-server__ApiService.yaml         # v1beta1.metrics.k8s.io
│
├── 02.udp_health_check-nlb_oci/     # App: UDP Health Check para NLB OCI
│   ├── 00.UsefulScripts/
│   │   ├── 01.deploy_udp_health_check_server_nlb_oci_script.sh
│   │   └── 02.destroy_udp_health_check_server_nlb_oci_script.sh
│   └── kubernetes/
│       ├── 01.create__Namespace.yaml
│       ├── 02.udp-health-check-server-1700__Deployment.yaml   # hostNetwork: true
│       ├── 03.udp-health-check-server-1700__Service.yaml      # UDP ClusterIP :1700
│       ├── 04.udp-health-check-server-1700__DaemonSet.yaml    # 1 pod por worker
│       ├── 05.udp-health-check-server-1700__Service-DaemonSet.yaml
│       ├── 06.udp-health-check-server-1710__Deployment.yaml
│       ├── 07.udp-health-check-server-1710__Service.yaml      # UDP ClusterIP :1710
│       ├── 08.udp-health-check-server-1710__DaemonSet.yaml    # 1 pod por worker
│       ├── 09.udp-health-check-server-1710__Service-DaemonSet.yaml
│       ├── Dockerfile                                # Build da imagem Java ARM64
│       └── UdpHealthCheckServer.java                 # Servidor UDP PING/PONG em Java
```

---

## Configuração de DNS — Subdomínios Obrigatórios

### Por que o registro DNS é obrigatório

Todos os serviços expostos via HTTPS neste cluster dependem do **cert-manager + Let's Encrypt** para emissão automática de certificados TLS. O Let's Encrypt usa o desafio **ACME HTTP-01**: ele acessa uma URL específica no seu domínio para provar que você é o dono antes de emitir o certificado.

Isso significa que **cada subdomínio precisa existir no seu DNS público e apontar para o IP do Load Balancer antes do deploy dos serviços**. Se o registro não existir ou ainda não propagou, o cert-manager ficará em loop tentando emitir o certificado e o Ingress não servirá HTTPS.

```
Let's Encrypt (ACME HTTP-01)
    │
    ├── Acessa http://k8s.seudominio.com.br/.well-known/acme-challenge/...
    │         └── Resolve DNS → deve apontar para o IP do Load Balancer OCI
    │                  └── NLB :80 → worker NodePort 30080 → Ingress NGINX → cert-manager
    │                          └── ✅ Desafio aprovado → certificado emitido
    │
    └── Se o DNS não existir ou não apontar para o NLB → ❌ timeout → certificado não emitido
```



### Quando cadastrar os subdomínios

O momento ideal é **durante a execução do `tofu apply` (ou `terraform apply`)**, não depois. O módulo `network` — segundo a ser executado — provisiona o IP Público Reservado e o Load Balancer em poucos segundos após o início do apply. Assim que o IP aparecer no console OCI, você já pode cadastrar os registros DNS, e a propagação ocorrerá em paralelo ao restante do provisionamento do cluster.

```
tofu apply -parallelism=1
     │
     ├── ~30s → NLB + IP criados  ← 📌 CADASTRE OS REGISTROS DNS AQUI
     │                                  (propagação TTL=300 leva ~5 minutos)
     ├── ~5min  → VMs provisionadas
     ├── ~10min → cluster Kubernetes operacional
     ├── ~15min → cert-manager tenta emitir certificados
     │               └── ✅ DNS já propagado → certificados emitidos
     └── ~20-30min → apply concluído com tudo pronto
```

> Veja como obter o IP durante o apply na seção [Como obter o IP durante o apply](#como-obter-o-ip-durante-o-apply), dentro de **Implantação da Infraestrutura → Terraform → Passo 6**.

---

### Subdomínios necessários neste projeto

Abaixo estão todos os subdomínios que precisam ser cadastrados no seu provedor DNS, apontando para o **IP Público Reservado** do Load Balancer OCI:

| Subdomínio | Serviço | Tipo de registro | TTL sugerido |
|---|---|---|---|
| `k8s.seudominio.com.br` | Homepage NGINX + Kubernetes Dashboard | `A` | 300 |

> Todos os registros são do tipo `A` apontando para o mesmo IP — o IP Público Reservado do NLB, obtido com `terraform output -raw cluster_public_ip`.

---

### Como obter o IP do Load Balancer

```bash
# Via output do Terraform/OpenTofu
terraform output -raw cluster_public_ip

# Via kubectl (após o cluster estar de pé)
kubectl get service -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Também disponível no console OCI:
# Networking → Load Balancers → Network Load Balancers → (seu NLB) → IP Address
```

---

### Exemplo prático — Registro `.com.br` (Registro.br)

No Registro.br, o gerenciamento de DNS é feito em **registro.br → Domínios → (seu domínio) → Editar zona DNS**.

> ⚠️ **Atenção — Modo Avançado obrigatório:** por padrão, o painel do Registro.br opera no **modo básico**, que não permite cadastrar subdomínios personalizados. Para adicionar os registros `A` necessários para este cluster, é preciso ativar o **Modo Avançado** na seção de zona DNS.
>
> Acesse: [registro.br → Painel → Domínios → (seu domínio) → DNS → Configurar zona DNS](https://registro.br/painel/dominios/) e procure pela opção **"Modo Avançado"** ou **"Edição avançada de zona"**.
>
> **A ativação do modo avançado pode levar em média 2 horas para ser processada pelo Registro.br** — portanto, ative-o com antecedência, idealmente antes mesmo de iniciar o provisionamento do cluster, para que quando o IP do NLB estiver disponível o painel já esteja liberado para edição.

```
Fluxo recomendado de tempo:

Dia anterior (ou horas antes):
└── Ativar Modo Avançado no Registro.br  ← aguardar ~2 horas para processar

Durante o tofu apply (~30 segundos após iniciar):
└── NLB + IP criados → cadastrar os registros A na zona DNS
        └── propagação TTL=300 (~5 minutos)

Ao final do apply (~20-30 min):
└── Cluster pronto + DNS propagado + certificados TLS emitidos ✅
```

Para cada subdomínio, adicione uma entrada do tipo `A`:

```
Registro.br — Zona DNS de seudominio.com.br
┌──────────────────────────────────────────┬──────┬───────────────────┬─────┐
│ Nome                                     │ Tipo │ Valor             │ TTL │
├──────────────────────────────────────────┼──────┼───────────────────┼─────┤
│ k8s                                      │  A   │ <IP_DO_NLB>       │ 300 │
└──────────────────────────────────────────┴──────┴───────────────────┴─────┘
```

> No Registro.br, o campo "Nome" aceita apenas o prefixo do subdomínio — sem o domínio raiz. Ou seja, para criar `k8s.seudominio.com.br`, preencha o campo Nome com `k8s` apenas.

**Passo a passo no painel do Registro.br:**

1. Acesse [registro.br](https://registro.br) e faça login
2. Clique em **Domínios** e selecione o seu domínio
3. Acesse **DNS → Configurar zona DNS**
4. Ative o **Modo Avançado** (se ainda não estiver ativo) — aguarde até 2 horas para o processamento
5. Com o modo avançado ativo, clique em **Adicionar entrada** para cada subdomínio
6. Selecione o tipo `A`, preencha o **Nome** (ex: `k8s`) e o **Valor** com o IP do NLB
7. Clique em **Salvar**
8. Aguarde a propagação (TTL de 300 segundos = 5 minutos para a maioria dos resolvedores)

---

### Verificar a propagação do DNS

Antes de fazer o deploy dos serviços, confirme que o registro propagou:

```bash
# Verificar cada subdomínio — todos devem retornar o IP do NLB
dig +short k8s.seudominio.com.br

# Verificar de um servidor DNS público (confirma propagação global)
dig +short k8s.seudominio.com.br @8.8.8.8    # Google DNS
dig +short k8s.seudominio.com.br @1.1.1.1    # Cloudflare DNS

# Verificar propagação completa via ferramenta online:
# https://dnschecker.org
```

**Resultado esperado:** todos os subdomínios devem retornar o mesmo IP do Load Balancer OCI.

---

### Outros provedores de DNS

A lógica é a mesma independente do provedor. A única diferença é a interface:

| Provedor | Onde acessar |
|---|---|
| **Registro.br** | registro.br → Domínios → Editar zona DNS |
| **Cloudflare** | dash.cloudflare.com → DNS → Records → Add record |
| **GoDaddy** | godaddy.com → Meus Domínios → DNS → Adicionar registro |
| **AWS Route 53** | console.aws.amazon.com → Route 53 → Hosted zones → Create record |
| **Google Domains** | domains.google → DNS → Gerenciar registros personalizados |

> Se estiver usando o **OCI DNS** (Oracle Cloud Infrastructure DNS), os registros podem ser criados diretamente no console em **Networking → DNS Management → Zones → (sua zona) → Add Record**.

---

### Atualizar os subdomínios nos manifestos antes do deploy

Os arquivos Ingress do projeto precisam ser editados com seus subdomínios reais **antes** de aplicar os manifests. Localize e substitua em cada arquivo:

**Homepage:**
```bash
# Arquivo: 00.homepage/kubernetes/06.homepage-nginx__Ingress.yaml
# Substituir: k8s.adailsilva.com.br → k8s.seudominio.com.br
sed -i 's/k8s.adailsilva.com.br/k8s.seudominio.com.br/g' \
  00.homepage/kubernetes/06.homepage-nginx__Ingress.yaml
```

**Variável do Terraform (cluster principal):**
```hcl
# variables.auto.tfvars
cluster_public_dns_name = "k8s.seudominio.com.br"
```

---

## Configuração Inicial

### 1. Clone o repositório

```bash
git clone https://github.com/AdailSilva/Kubernetes_at_Oracle_Cloud_Always_Free.git
cd Kubernetes_at_Oracle_Cloud_Always_Free
```

### 2. Configure as variáveis

```bash
cp variables.auto.tfvars.example variables.auto.tfvars
```

Edite `variables.auto.tfvars`:

```hcl
# ─── OCI API ───────────────────────────────────────────────────────────────
tenancy_ocid     = "ocid1.tenancy.oc1..xxxxxxxxxx"
user_ocid        = "ocid1.user.oc1..xxxxxxxxxx"
fingerprint      = "xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
private_key_path = "/home/seu_usuario/.oci/oci_api_key.pem"
# Windows: private_key_path = "C:\\Users\\...\\.oci\\oci-tf.pem"
# private_key_password = ""   # descomente se a chave tiver senha
region           = "sa-saopaulo-1"

# ─── SSH ───────────────────────────────────────────────────────────────────
# Gerado com: ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519
ssh_key_path     = "/home/seu_usuario/.ssh/id_ed25519"
ssh_key_pub_path = "/home/seu_usuario/.ssh/id_ed25519.pub"
# Windows:
# ssh_key_path     = "C:\\Users\\...\\.ssh\\id_ed25519"
# ssh_key_pub_path = "C:\\Users\\...\\.ssh\\id_ed25519.pub"

# ─── Cluster ───────────────────────────────────────────────────────────────
# Necessário para TLS com Let's Encrypt. Mudanças causam recriação do cluster.
cluster_public_dns_name = "k8s.seudominio.com.br"

# E-mail para registro no Let's Encrypt
letsencrypt_registration_email = "seu_email@seudominio.com"

# ─── Debug / Configurações locais ──────────────────────────────────────────
# Cria admin-user no Dashboard e exibe o token no output do Terraform
debug_create_cluster_admin = true

# Sobrescreve ~/.kube/config local com o kubeconfig do cluster
linux_overwrite_local_kube_config = true
# Windows: windows_overwrite_local_kube_config = true
```

### Referência completa de variáveis

| Variável | Tipo | Obrigatória | Default | Descrição |
|---|---|---|---|---|
| `tenancy_ocid` | string | ✅ | — | OCID da tenancy OCI |
| `user_ocid` | string | ✅ | — | OCID do usuário OCI |
| `fingerprint` | string | ✅ | — | Fingerprint da API Key |
| `private_key_path` | string | ✅ | — | Caminho da chave privada OCI |
| `private_key_password` | string | — | `""` | Senha da chave privada OCI |
| `region` | string | ✅ | — | Região OCI (ex: `sa-saopaulo-1`) |
| `ssh_key_path` | string | ✅ | — | Chave privada SSH para as VMs |
| `ssh_key_pub_path` | string | ✅ | — | Chave pública SSH para as VMs |
| `cluster_public_dns_name` | string | — | `null` | DNS público do cluster |
| `letsencrypt_registration_email` | string | ✅ | — | E-mail para certificados TLS |
| `debug_create_cluster_admin` | bool | — | `false` | Cria admin-user e exibe token |
| `linux_overwrite_local_kube_config` | bool | — | `false` | Sobrescreve `~/.kube/config` |

---

## Implantação da Infraestrutura

> Todos os comandos abaixo funcionam tanto com **Terraform** quanto com **OpenTofu**. Escolha a ferramenta de sua preferência — a sintaxe e o comportamento são equivalentes. OpenTofu é o fork open-source mantido pela comunidade; Terraform é mantido pela HashiCorp sob licença BSL.

---

### Terraform

#### 1. Instalar o Terraform

```bash
# Linux (Ubuntu/Debian)
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# macOS (Homebrew)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Verificar instalação
terraform version
```

#### 2. Inicializar o projeto

Baixa os providers declarados (`oci >= 6.35.0`, `null 3.1.0`) e prepara o diretório de trabalho:

```bash
terraform init
```

#### 3. Formatar o código (opcional)

Aplica formatação padrão em todos os arquivos `.tf`:

```bash
terraform fmt -recursive
```

#### 4. Validar a configuração

Verifica erros de sintaxe e configuração sem acessar a API da OCI:

```bash
terraform validate
```

#### 5. Visualizar o plano de execução

Exibe todos os recursos que serão criados, modificados ou destruídos:

```bash
terraform plan
```

Para salvar o plano em arquivo (útil para revisão antes de aplicar em produção):

```bash
terraform plan -out=tfplan
```

#### 6. Aplicar a infraestrutura

```bash
terraform apply
```

Aplicar sem confirmação interativa (use com cuidado):

```bash
terraform apply -auto-approve
```

Aplicar a partir de um plano salvo anteriormente:

```bash
terraform apply tfplan
```

Aplicar com paralelismo limitado a **1 operação por vez**:

```bash
terraform apply -parallelism=1
```

> Por padrão, o Terraform (e o OpenTofu) executam até **10 operações em paralelo**. O flag `-parallelism=1` força a criação dos recursos de forma **estritamente sequencial**, um por vez. Isso é especialmente útil neste projeto porque a API do Network Load Balancer da OCI é suscetível a race conditions ao criar múltiplos listeners, backend sets e backends simultaneamente — o que pode causar erros intermitentes do tipo `409-Conflict` ou `412-PreconditionFailed`. Usar `-parallelism=1` resolve esses conflitos ao garantir que cada recurso do NLB seja criado e confirmado antes do próximo iniciar. A desvantagem é que o tempo total de provisionamento aumenta; use esta opção apenas quando o `apply` padrão falhar com erros de concorrência na OCI.

> 💡 **Momento ideal para cadastrar os subdomínios no DNS:** o módulo `network` é o segundo a ser executado e provisiona o IP Público Reservado e o Load Balancer em poucos segundos após o início do `apply`. Você **não precisa aguardar os 15–30 minutos** do provisionamento completo — assim que a criação do NLB aparecer nos logs do Terraform/OpenTofu, o IP já estará disponível no console OCI e pode ser copiado para cadastrar os registros DNS. Dessa forma, quando o cluster terminar de subir, os subdomínios já estarão propagados e o cert-manager conseguirá emitir os certificados TLS imediatamente. Veja a seção [Como obter o IP durante o apply](#como-obter-o-ip-durante-o-apply) logo abaixo.

#### Como obter o IP durante o apply

Enquanto o `terraform apply` ou `tofu apply` ainda está em execução, abra um **segundo terminal** e use qualquer uma das opções abaixo para obter o IP imediatamente após os recursos de rede serem criados:

**Opção 1 — Console OCI (mais rápido, sem dependências):**
1. Acesse **OCI Console → Networking → Load Balancers → Network Load Balancers**
2. O NLB `k8s-arm-oci-always-free` (ou o nome configurado) aparecerá com status `Creating` em segundos
3. Clique nele — o **IP Address** já estará preenchido mesmo com o NLB ainda provisionando
4. Copie o IP e vá direto ao painel do seu provedor DNS para criar os registros

**Opção 2 — OCI CLI (no segundo terminal):**
```bash
# Listar os IPs públicos reservados da sua tenancy
oci network public-ip list \
  --compartment-id <COMPARTMENT_OCID> \
  --scope REGION \
  --query 'data[?"lifecycle-state"==`AVAILABLE`].{"IP": "ip-address", "Nome": "display-name"}' \
  --output table

# Ou buscar diretamente o IP do NLB pelo nome
oci nlb network-load-balancer list \
  --compartment-id <COMPARTMENT_OCID> \
  --query 'data.items[0]."ip-addresses"[0]."ip-address"' \
  --raw-output
```

**Opção 3 — Terraform/OpenTofu state (após o módulo network concluir):**
```bash
# Enquanto o apply ainda corre, em outro terminal, dentro do diretório do projeto:
terraform output cluster_public_ip 2>/dev/null || \
  terraform state show module.network.oci_core_public_ip.cluster_public_ip \
  | grep "ip_address"

# OpenTofu:
tofu output cluster_public_ip 2>/dev/null || \
  tofu state show module.network.oci_core_public_ip.cluster_public_ip \
  | grep "ip_address"
```

**Fluxo recomendado:**

```
tofu apply -parallelism=1  (Terminal 1 — deixa rodando)
     │
     ├── ~30s → módulo network concluído → NLB + IP criados
     │               └── Terminal 2: copie o IP do console OCI
     │                       └── Cadastre os registros DNS no Registro.br
     │                               (propagação leva ~5 minutos com TTL=300)
     │
     ├── ~5min → módulo compute concluído → VMs provisionadas
     ├── ~10min → módulo k8s concluído → cluster Kubernetes operacional
     ├── ~15min → módulo k8s_scaffold → cert-manager tenta emitir certificados
     │               └── ✅ DNS já propagado → certificados emitidos com sucesso
     └── ~20-30min → apply concluído
```

> Cadastrar os registros DNS **durante o apply** — e não depois — é a forma mais eficiente de garantir que os certificados TLS estejam prontos assim que o cluster terminar de subir, sem precisar aguardar propagação adicional.

#### 7. Consultar os outputs após a implantação

```bash
# Todos os outputs de uma vez
terraform output

# Outputs específicos
terraform output cluster_public_ip       # IP público do Load Balancer
terraform output cluster_public_address  # DNS do cluster
terraform output admin_token             # Token do Dashboard (se debug_create_cluster_admin = true)
```

Para extrair um valor em texto puro (útil em scripts):

```bash
terraform output -raw cluster_public_ip
terraform output -raw admin_token
```

#### 8. Consultar o estado atual

Listar todos os recursos gerenciados:

```bash
terraform state list
```

Inspecionar um recurso específico:

```bash
terraform state show <resource_address>
# Exemplo:
terraform state show module.compute.oci_core_instance.leader
```

#### 9. Destruir a infraestrutura

```bash
terraform destroy
```

Destruir sem confirmação interativa:

```bash
terraform destroy -auto-approve
```

---

### OpenTofu

#### 1. Instalar o OpenTofu

```bash
# Linux (Ubuntu/Debian) — via repositório oficial
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh | bash -s -- --install-method deb

# macOS (Homebrew)
brew install opentofu

# Windows (Winget)
winget install OpenTofu.OpenTofu

# Verificar instalação
tofu version
```

#### 2. Inicializar o projeto

Baixa os providers declarados e prepara o diretório de trabalho:

```bash
tofu init
```

Forçar o re-download dos providers (útil após atualização de versão):

```bash
tofu init -upgrade
```

#### 3. Formatar o código (opcional)

```bash
tofu fmt -recursive
```

#### 4. Validar a configuração

```bash
tofu validate
```

#### 5. Visualizar o plano de execução

```bash
tofu plan
```

Salvar o plano em arquivo:

```bash
tofu plan -out=tfplan
```

#### 6. Aplicar a infraestrutura

```bash
tofu apply
```

Aplicar sem confirmação interativa:

```bash
tofu apply -auto-approve
```

Aplicar a partir de um plano salvo:

```bash
tofu apply tfplan
```

Aplicar com paralelismo limitado a **1 operação por vez**:

```bash
tofu apply -parallelism=1
```

> Por padrão, o OpenTofu (e o Terraform) executam até **10 operações em paralelo**. O flag `-parallelism=1` força a criação dos recursos de forma **estritamente sequencial**, um por vez. Isso é especialmente útil neste projeto porque a API do Network Load Balancer da OCI é suscetível a race conditions ao criar múltiplos listeners, backend sets e backends simultaneamente — o que pode causar erros intermitentes do tipo `409-Conflict` ou `412-PreconditionFailed`. Usar `-parallelism=1` resolve esses conflitos ao garantir que cada recurso do NLB seja criado e confirmado antes do próximo iniciar. A desvantagem é que o tempo total de provisionamento aumenta; use esta opção apenas quando o `apply` padrão falhar com erros de concorrência na OCI.

> 💡 **Momento ideal para cadastrar os subdomínios no DNS:** o módulo `network` conclui em poucos segundos após o início do `apply` e o IP do Load Balancer já está disponível no console OCI antes do cluster terminar de subir. Cadastre os registros DNS nesse intervalo para que a propagação ocorra em paralelo ao provisionamento. Veja o fluxo detalhado na seção [Como obter o IP durante o apply](#como-obter-o-ip-durante-o-apply) acima (seção Terraform — o procedimento é idêntico para OpenTofu).

#### 7. Consultar os outputs após a implantação

```bash
# Todos os outputs de uma vez
tofu output

# Outputs específicos
tofu output cluster_public_ip
tofu output cluster_public_address
tofu output admin_token
```

Extrair valor em texto puro:

```bash
tofu output -raw cluster_public_ip
tofu output -raw admin_token
```

#### 8. Consultar o estado atual

```bash
tofu state list
tofu state show <resource_address>
```

#### 9. Destruir a infraestrutura

```bash
tofu destroy
```

Destruir sem confirmação interativa:

```bash
tofu destroy -auto-approve
```

---

### Comandos adicionais úteis (ambas as ferramentas)

Estes comandos têm sintaxe idêntica no Terraform e no OpenTofu, bastando trocar `terraform` por `tofu`:

```bash
# Limitar o paralelismo a 1 operação por vez (evita race conditions no NLB da OCI)
terraform apply -parallelism=1
tofu apply -parallelism=1

# Combinar com -target para recriar um módulo de forma segura e sequencial
terraform apply -parallelism=1 -target=module.k8s_scaffold
tofu apply -parallelism=1 -target=module.k8s_scaffold

# Recarregar apenas um módulo específico (útil para recriar recursos isolados)
terraform apply -target=module.k8s
tofu apply -target=module.k8s

# Recarregar apenas um recurso específico
terraform apply -target=module.compute.oci_core_instance.leader
tofu apply -target=module.compute.oci_core_instance.leader

# Importar um recurso existente na OCI para o estado do Terraform/OpenTofu
terraform import <resource_address> <resource_ocid>
tofu import <resource_address> <resource_ocid>

# Remover um recurso do estado sem destruí-lo na OCI
terraform state rm <resource_address>
tofu state rm <resource_address>

# Verificar diferenças entre o estado e a infraestrutura real
terraform refresh
tofu refresh

# Exibir o grafo de dependências entre módulos (requer graphviz)
terraform graph | dot -Tsvg > grafo.svg
tofu graph | dot -Tsvg > grafo.svg
```

---

### Sequência de execução dos módulos

Independente da ferramenta, a ordem de provisionamento é sempre:

```
compartment → network → compute → k8s → k8s_scaffold → oci-infra_ci_cd
```

Cada módulo depende do anterior via `depends_on`. O Terraform e o OpenTofu gerenciam essa ordem automaticamente.

> ⏱️ O processo completo leva entre **15 e 30 minutos**:
> - Recursos OCI (compartimento, rede, VMs): ~5 min
> - Bootstrap do Control Plane (kubeadm init): ~5 min
> - Join dos 3 Workers (paralelo): ~10 min
> - Instalação das aplicações scaffold: ~5 min

---

## Implantando as Aplicações Padrão

Após a infraestrutura estar operacional, execute as aplicações na seguinte ordem recomendada:

### 1. Metrics Server

```bash
cd 01.metrics_server/00.UsefulScripts/
bash 01.deploy_metrics_server_script.sh

# Verificar:
kubectl top nodes
kubectl get pods -n kube-system | grep metrics
```

### 2. UDP Health Check

> Necessário antes de adicionar listeners UDP no NLB para que o health check passe.

```bash
# Criar o Secret de acesso ao OCI Registry
kubectl create secret docker-registry oci-registry-secret \
  --docker-server=gru.ocir.io \
  --docker-username='<namespace>/<seu_email>' \
  --docker-password='<auth_token>' \
  --docker-email='<seu_email>' \
  -n oci-devops

cd 02.udp_health_check-nlb_oci/00.UsefulScripts/
bash 01.deploy_udp_health_check_server_nlb_oci_script.sh

# Verificar:
kubectl get pods -n oci-devops
kubectl get daemonset -n oci-devops
```

### 3. Homepage

```bash
# Garantir que o Secret de Registry exista no namespace oci-devops
kubectl get secret oci-registry-secret -n oci-devops

cd 00.homepage/00.UsefulScripts/
bash 01.deploy_homepage-nginx_script.sh

# Verificar:
kubectl get pods,svc,ingress -n oci-devops
kubectl get certificate -n oci-devops
```

---
## Acesso ao Cluster

O `kubeconfig` externo é salvo em `.terraform/.kube/config-external`. Se `linux_overwrite_local_kube_config = true`, é copiado automaticamente para `~/.kube/config`.

```bash
# Verificar todos os nós
kubectl get nodes -o wide

# Saída esperada:
# NAME       STATUS   ROLES           AGE   VERSION   OS-IMAGE
# leader     Ready    control-plane   10m   v1.31.x   Ubuntu 24.04 LTS
# worker-0   Ready    worker          8m    v1.31.x   Ubuntu 24.04 LTS
# worker-1   Ready    worker          8m    v1.31.x   Ubuntu 24.04 LTS
# worker-2   Ready    worker          8m    v1.31.x   Ubuntu 24.04 LTS

# Verificar pods de todos os namespaces relevantes
kubectl get pods -n kube-system        # Sistema + Metrics Server
kubectl get pods -n ingress-nginx      # Ingress Controller
kubectl get pods -n cert-manager       # Gerenciador de certificados TLS
kubectl get pods -n oci-devops         # Homepage + UDP Health Check


# Verificar certificados TLS em todos os namespaces
kubectl get certificate -A

# Verificar Ingress em todos os namespaces
kubectl get ingress -A
```

### Acesso SSH

```bash
# Acesso direto ao leader (porta 22 do Load Balancer)
ssh -i ~/.ssh/id_ed25519 ubuntu@<IP_PUBLICO_RESERVADO>

# Acesso a um worker (via jump através do leader)
ssh -i ~/.ssh/id_ed25519 \
    -J ubuntu@<IP_PUBLICO_RESERVADO> \
    ubuntu@<IP_PRIVADO_WORKER>
```

### Kubernetes Dashboard

Acessível em `https://<cluster_public_dns_name>/dashboard`.

```bash
# Obter o token de acesso
terraform output admin_token
```

---

## CI/CD com GitHub Actions

O projeto inclui um workflow de CI/CD em `00.homepage/ci_cd.yaml` que automatiza o build da imagem Docker ARM64 e o deploy da homepage no cluster Kubernetes a cada push na branch `master` com alterações dentro da pasta `app/`. O pipeline também pode ser disparado manualmente via `workflow_dispatch`.

### Gatilhos do pipeline

```yaml
on:
  push:
    branches:
      - master
    paths:
      - app/**        # Só dispara quando há mudanças na pasta app/
  workflow_dispatch:  # Permite execução manual pela interface do GitHub
```

### Etapas do pipeline

| # | Step | Descrição |
|---|---|---|
| 1 | **Checkout** | Clona o repositório no runner (com `fetch-depth: 0` para buscar todas as tags Git) |
| 2 | **Calcular próxima versão** | Lê a última tag Git no formato `X.Y`, incrementa o minor automaticamente (ou o major se `workflow_dispatch` com `version_type: major`) |
| 3 | **Criar tag Git** | Cria e faz push da nova tag de versão no repositório usando o `GH_PAT` |
| 4 | **Set up QEMU** | Habilita emulação ARM64 no runner x86 |
| 5 | **Set up Docker Buildx** | Configura o builder multi-plataforma |
| 6 | **Install OCI CLI** | Instala o OCI CLI e escreve as credenciais a partir dos Secrets |
| 7 | **Install kubectl** | Instala o `kubectl` e configura o kubeconfig do cluster |
| 8 | **Currently running services** | Exibe os pods em `oci-devops` antes do deploy |
| 9 | **Login to Docker registry** | Autentica no OCI Container Registry |
| 10 | **Available platforms** | Lista as plataformas disponíveis no Buildx |
| 11 | **Build** | Faz build e push da imagem com duas tags: a versão calculada (ex: `0.3`) e `latest` |
| 12 | **Deploy to K8S** | Aplica o manifesto `02.homepage-nginx__Deployment.yaml` no cluster |
| 13 | **Restart nginx** | Executa `rollout restart` no Deployment `nginx` em `oci-devops` |
| 14 | **Limpar imagens unknown** | Remove do OCI Registry os manifestos intermediários sem tag (`unknown`) gerados pelo build multi-plataforma |

### Secrets do repositório GitHub

Todos os valores abaixo devem ser cadastrados em **Settings → Secrets and variables → Actions → New repository secret** no seu repositório.

| Secret | Valor esperado | Como obter |
|---|---|---|
| `OCI_CONFIG` | Conteúdo completo do arquivo `~/.oci/config` | Gerado automaticamente ao configurar a OCI CLI (`oci setup config`) |
| `OCI_KEY_FILE` | Conteúdo da chave privada OCI (`oci_api_key.pem`) | Arquivo gerado em `~/.oci/oci_api_key.pem` |
| `KUBECONFIG` | Conteúdo do kubeconfig externo do cluster | Gerado pelo Terraform em `.terraform/.kube/config-external` após o `apply` |
| `DOCKER_URL` | URL do OCI Container Registry | Ex: `gru.ocir.io` (varia por região) |
| `DOCKER_USERNAME` | Username de autenticação no OCI Registry | Formato: `<namespace>/<seu_email>` — ex: `griszz3l82u1/adail101@hotmail.com` |
| `DOCKER_PASSWORD` | Auth token do OCI Registry | Gerado em **OCI Console → Identity → Users → Auth Tokens → Generate Token** |
| `DOCKER_OBJECT_STORAGE_NAMESPACE` | Namespace do OCI Object Storage | Encontrado em **OCI Console → Object Storage → Namespace** ou via `oci os ns get` |
| `GH_PAT` | Personal Access Token do GitHub com escopo `repo` | Gerado em **GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)** |
| `OCI_COMPARTMENT_ID` | OCID do compartment onde o Container Registry está | Encontrado em **OCI Console → Identity & Security → Compartments** ou nos detalhes do repositório no Container Registry |

### Como obter cada Secret

**`OCI_CONFIG`** — exiba e copie o conteúdo do arquivo de configuração da OCI CLI:
```bash
cat ~/.oci/config
```
O arquivo tem o formato abaixo. O campo `key_file` deve apontar para `/home/runner/.oci/key.pem` (caminho usado pelo runner no GitHub Actions):
```ini
[DEFAULT]
user=ocid1.user.oc1..xxxxxxxxxx
fingerprint=xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx
tenancy=ocid1.tenancy.oc1..xxxxxxxxxx
region=sa-saopaulo-1
key_file=/home/runner/.oci/key.pem
```

**`OCI_KEY_FILE`** — exiba e copie o conteúdo da chave privada:
```bash
cat ~/.oci/oci_api_key.pem
```

**`KUBECONFIG`** — após o `terraform apply`, exiba o kubeconfig externo:
```bash
cat .terraform/.kube/config-external
# ou, se você usou linux_overwrite_local_kube_config = true:
cat ~/.kube/config
```

**`DOCKER_URL`** — URL do OCI Registry de acordo com a região:

| Região OCI | URL do Registry |
|---|---|
| São Paulo (`sa-saopaulo-1`) | `gru.ocir.io` |
| Ashburn (`us-ashburn-1`) | `iad.ocir.io` |
| Phoenix (`us-phoenix-1`) | `phx.ocir.io` |
| Frankfurt (`eu-frankfurt-1`) | `fra.ocir.io` |

**`DOCKER_OBJECT_STORAGE_NAMESPACE`** — obtenha via OCI CLI:
```bash
oci os ns get --query 'data' --raw-output
```

**`DOCKER_PASSWORD` (Auth Token)** — gere no console OCI:
1. Acesse **Identity & Security → Users → (seu usuário)**
2. Clique em **Auth Tokens → Generate Token**
3. Copie o token gerado (ele é exibido apenas uma vez)

**`GH_PAT` (Personal Access Token do GitHub)** — necessário para que o pipeline crie e faça push de tags Git de versionamento (ex: `0.1`, `0.2`, `1.0`) no repositório. O `GITHUB_TOKEN` padrão do Actions não tem permissão de escrita em tags, por isso é obrigatório criar um token pessoal:

1. Acesse seu perfil no GitHub → clique na foto → **Settings**
2. No menu lateral esquerdo, role até o fim → **Developer settings**
3. **Personal access tokens → Tokens (classic)**
4. Clique em **Generate new token → Generate new token (classic)**
5. Preencha:
   - **Note:** `GH_PAT` (ou qualquer nome descritivo)
   - **Expiration:** escolha um prazo (ex: `90 days` ou `No expiration`)
   - **Scopes:** marque apenas ✅ `repo` — já inclui permissão de escrita em tags e branches
6. Clique em **Generate token** e **copie o valor gerado** (ele é exibido apenas uma vez)
7. Adicione como Secret no repositório com o nome `GH_PAT`

> O pipeline usa o `GH_PAT` no step de `Checkout` (`token: ${{ secrets.GH_PAT }}`) e no step **Criar tag Git**, que executa `git push origin <versão>`. Sem este token, o push de tags falhará com erro de permissão.

**`OCI_COMPARTMENT_ID`** — OCID do compartment onde o OCI Container Registry está provisionado. Necessário para que o OCI CLI liste e delete as imagens `unknown` geradas pelo build multi-plataforma:

**Opção 1 — Via console OCI (Identity):**
1. Acesse [cloud.oracle.com](https://cloud.oracle.com) e faça login
2. Menu (☰) → **Identity & Security → Compartments**
3. Clique no compartment onde seu Container Registry está (geralmente o mesmo criado pelo Terraform: `k8s-on-arm-oci-always-free`, ou o compartment root)
4. Copie o **OCID** exibido na página — tem o formato:
```
ocid1.compartment.oc1..aaaaaaaaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Opção 2 — Via console OCI (Container Registry):**
1. Menu (☰) → **Developer Services → Container Registry**
2. Clique no repositório `homepage-80_platform_linux-arm64`
3. Na página de detalhes, o campo **Compartment OCID** exibe o valor diretamente

**Opção 3 — Via OCI CLI:**
```bash
# Lista todos os compartments e seus OCIDs
oci iam compartment list --query 'data[*].{"name":name,"id":id}' --output table
```

Adicione o OCID como Secret no repositório com o nome `OCI_COMPARTMENT_ID`.

### Como o pipeline constrói e implanta a imagem

O step de **Build** usa o Docker Buildx para criar a imagem simultaneamente para `linux/amd64` e `linux/arm64`, fazendo push direto ao OCI Registry:

```bash
docker build --push \
  --platform linux/amd64,linux/arm64 \
  -t gru.ocir.io/<DOCKER_OBJECT_STORAGE_NAMESPACE>/homepage-80_platform_linux-arm64:latest \
  app/.
```

O step de **Deploy** substitui o placeholder `<DOCKER_OBJECT_STORAGE_NAMESPACE>` no manifesto com o valor real antes de aplicar:

```bash
sed -i 's/<DOCKER_OBJECT_STORAGE_NAMESPACE>/${{ secrets.DOCKER_OBJECT_STORAGE_NAMESPACE }}/g' \
  app/02.homepage-nginx__Deployment.yaml

kubectl apply -f app/02.homepage-nginx__Deployment.yaml -n oci-devops
```

Por fim, o **Restart** força o rollout para que os pods sejam recriados com a nova imagem:

```bash
kubectl rollout restart deployment nginx -n oci-devops
```

### Estrutura esperada da pasta `app/`

O workflow monitora mudanças em `app/**` e espera encontrar:

```
app/
├── Dockerfile                          # FROM nginx:latest + index.html
├── index.html                          # Conteúdo da homepage
└── 02.homepage-nginx__Deployment.yaml  # Manifesto com placeholder <DOCKER_OBJECT_STORAGE_NAMESPACE>
```

O manifesto de Deployment deve conter o placeholder que será substituído pelo pipeline:

```yaml
containers:
  - name: nginx
    image: gru.ocir.io/<DOCKER_OBJECT_STORAGE_NAMESPACE>/homepage-80_platform_linux-arm64:latest
```

### Verificar a execução do pipeline

Após um push ou execução manual, acompanhe em **Actions → CI/CD** no GitHub. Para verificar no cluster:

```bash
# Checar o status do rollout
kubectl rollout status deployment/nginx -n oci-devops

# Ver os pods atualizados
kubectl get pods -n oci-devops -o wide

# Ver os eventos recentes
kubectl describe deployment nginx -n oci-devops
```

---

## OCI Container Registry

O módulo `oci-infra_ci_cd` cria repositórios privados no **OCI Container Registry** para armazenar imagens Docker **ARM64** do cluster:

| Repositório | Arquitetura | Aplicação |
|---|---|---|
| `homepage-80_platform_linux-arm64` | ARM64 | Homepage NGINX |
| `udp-health-check-server-1700_platform_linux-arm64` | ARM64 | UDP Health Check porta 1700 |
| `udp-health-check-server-1710_platform_linux-arm64` | ARM64 | UDP Health Check porta 1710 |

Novos repositórios podem ser adicionados em `oci_artifacts_container_repository/oci_artifacts_container_repository.tf`.

---

## Destruindo a Infraestrutura

> ⚠️ As instâncias de compute e o IP reservado possuem `prevent_destroy = true`. Edite os respectivos arquivos `.tf` antes de executar o destroy se quiser remover todos os recursos.

```bash
terraform destroy   # ou: tofu destroy
```

O script `reset.sh` é executado automaticamente em cada nó antes da destruição, realizando uma limpeza ordenada do cluster Kubernetes.

---

## Troubleshooting

### ❌ `Out of capacity for shape VM.Standard.A1.Flex`

A região está sem capacidade ARM disponível.

**Solução:** Mude a variável `region` para `us-ashburn-1` ou `us-phoenix-1` e execute `terraform apply` novamente.

---

### ❌ `NotAuthenticated` — Falha na autenticação OCI

**Solução:** Confirme que o `fingerprint` no `.tfvars` é idêntico ao exibido no console OCI após o upload da API Key. Verifique também o caminho correto da chave privada.

---

### ❌ Nós em estado `NotReady`

O CNI (Flannel) pode não ter inicializado ainda.

```bash
kubectl describe node <nome-do-no>
kubectl get pods -n kube-flannel -o wide

# Ver logs de inicialização na VM
ssh -i ~/.ssh/id_ed25519 ubuntu@<IP_PUBLICO> \
  "sudo tail -100 /var/log/cloud-init-output.log"
```

---

### ❌ Preflight errors no `kubeadm init` (NumCPU / Mem)

Já contornado automaticamente com `--ignore-preflight-errors=NumCPU,Mem` no script `setup-control-plane.sh`.

---

### ❌ Let's Encrypt não emite certificado

A causa mais comum é que o registro DNS do subdomínio ainda não existe ou ainda não propagou. O cert-manager usa o desafio **ACME HTTP-01**, que exige que o subdomínio resolva para o IP do NLB no momento da verificação.

**1. Confirmar que o DNS está propagado e aponta para o IP correto:**

```bash
# Obter o IP do NLB
terraform output -raw cluster_public_ip

# Verificar cada subdomínio — deve retornar o IP do NLB
dig +short k8s.seudominio.com.br

# Confirmar propagação via DNS público
dig +short k8s.seudominio.com.br @8.8.8.8
dig +short k8s.seudominio.com.br @1.1.1.1
```

> Se o DNS não retornar o IP correto, cadastre ou corrija o registro no seu provedor (ex: Registro.br) e aguarde a propagação. Consulte a seção [Configuração de DNS — Subdomínios Obrigatórios](#configuração-de-dns--subdomínios-obrigatórios).

**2. Verificar o status do certificado e do desafio ACME:**

```bash
# Status geral dos certificados em todos os namespaces
kubectl get certificate -A

# Detalhes do certificado — procure por "Message" e "Reason"


# Detalhes do desafio HTTP-01 — procure pelo campo "Presented" e "Reason"
kubectl describe challenges -A

# Verificar o CertificateRequest
kubectl describe certificaterequest -A
```

**3. Verificar se o Ingress NGINX está roteando o desafio corretamente:**

```bash
# O cert-manager cria um Ingress temporário durante o desafio
kubectl get ingress -A | grep cm-acme

# Os pods do Ingress devem estar Running
kubectl get pods -n ingress-nginx
```

**4. Verificar se o subdomínio está correto no manifesto Ingress:**

```bash
# O host no Ingress deve bater exatamente com o registro DNS

```

---

### ❌ Pods com `ImagePullBackOff` no namespace `oci-devops`

O Secret de acesso ao OCI Registry pode estar faltando ou incorreto.

```bash
# Verificar se o Secret existe
kubectl get secret oci-registry-secret -n oci-devops

# Recriar o Secret
kubectl delete secret oci-registry-secret -n oci-devops
kubectl create secret docker-registry oci-registry-secret \
  --docker-server=gru.ocir.io \
  --docker-username='<namespace>/<seu_email>' \
  --docker-password='<auth_token>' \
  --docker-email='<seu_email>' \
  -n oci-devops
```

---

### ❌ NLB Overall Health: Critical — portas UDP 1700 ou 1710

O **Overall Health do NLB fica `Critical`** enquanto qualquer listener não tiver backends saudáveis. Para as portas UDP, a causa mais comum é que o `UdpHealthCheckServer` não está rodando ou não está acessível diretamente no IP do nó.

**1. Verificar se os pods estão Running:**

```bash
kubectl get pods -n oci-devops -o wide
kubectl get daemonset -n oci-devops

# Todos os DaemonSets devem ter DESIRED = CURRENT = READY = 3
```

**2. Confirmar que `hostNetwork: true` está ativo:**

```bash
kubectl get pod <nome-do-pod-udp-1700> -n oci-devops -o jsonpath='{.spec.hostNetwork}'
# Saída esperada: true
```

**3. Testar o PING/PONG diretamente nos workers:**

```bash
# Obter os IPs dos workers
kubectl get nodes -o wide | grep worker

# Testar porta 1700
echo "PING" | nc -u -w2 <IP_DO_WORKER> 1700
# Resposta esperada: PONG

# Testar porta 1710
echo "PING" | nc -u -w2 <IP_DO_WORKER> 1710
# Resposta esperada: PONG
```

**4. Verificar as Security Lists da subnet no console OCI:**

As portas UDP 1700 e 1710 precisam estar liberadas nas **Ingress Rules** da Security List da subnet pública:

- Protocolo: `UDP`
- Porta de destino: `1700` e `1710`
- Origem: `0.0.0.0/0` (ou o CIDR do NLB)

**5. Verificar os logs do pod:**

```bash
kubectl logs -l app=udp-1700 -n oci-devops --tail=50
# Log esperado: "UDP Health Check Server listening on port 1700..."
```

**6. Reimplantar se necessário:**

```bash
kubectl rollout restart deployment udp-app-with-healthcheck-1700-deployment -n oci-devops
kubectl rollout restart deployment udp-app-with-healthcheck-1710-deployment -n oci-devops
```

**7. Confirmar a recuperação no console OCI:**

Após corrigir o problema, aguarde 1 a 2 minutos e acesse **Networking → Load Balancers → Network Load Balancers → (seu NLB) → Overall Health**. O status deve mudar de `Critical` para `OK`.

---

### ❌ Timeout de SSH durante o `terraform apply`

O Load Balancer pode levar alguns minutos para propagar os listeners. O Terraform aguarda automaticamente (timeout de 5 minutos). Se persistir, re-execute `terraform apply` — o processo é idempotente.

---

## Contribuindo

Contribuições são bem-vindas! Para contribuir:

1. Faça um **fork** do repositório
2. Crie uma branch: `git checkout -b feat/minha-melhoria`
3. Faça commits claros seguindo [Conventional Commits](https://www.conventionalcommits.org/pt-br/)
4. Faça push: `git push origin feat/minha-melhoria`
5. Abra um **Pull Request** descrevendo a mudança e a motivação

---

## Licença

Este projeto está licenciado sob a **MIT License**. Veja o arquivo [LICENSE](LICENSE) para os termos completos.

---

<div align="center">

**☸️ Kubernetes · 🦾 ARM · ☁️ Oracle Cloud · 🆓 Always Free**

Feito para a comunidade brasileira de Cloud e DevOps.

</div>
