#!/bin/bash -x

# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

# 1. Install container runtime - containerd

# 1.1. containerd prerequisites
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

# 1.2. Add Docker apt repository
sudo apt-get install --yes \
  ca-certificates \
  apt-transport-https \
  curl \
  gnupg \
  lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get -y remove needrestart

sudo apt-get clean
sudo apt-get update
sudo apt-get upgrade --yes
sudo apt-get autoremove --yes
sudo apt-get autoclean --yes

sudo systemctl daemon-reload

# 1.3. Install containerd
sudo apt-get install --yes containerd.io

# 1.4. Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo systemctl restart containerd

# 1.5. Enable systemd cgroup driver in containerd
# (it must mutch cgroup driver of kubelet, which is systemd by default)
if ! grep -q 'SystemdCgroup = true' /etc/containerd/config.toml; then
  if grep -q 'SystemdCgroup = false' /etc/containerd/config.toml; then
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
  else
    sudo sed -i 's/\[plugins\."io\.containerd\.grpc\.v1\.cri"\.containerd\.runtimes\.runc\.options\]/&\n SystemdCgroup = true/' /etc/containerd/config.toml
  fi
fi

sudo systemctl restart containerd

# 2. Install kubeadm
sudo apt-get --yes install curl gnupg2 software-properties-common apt-transport-https ca-certificates

sudo systemctl daemon-reload

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get clean
sudo apt-get update
sudo apt-get upgrade --yes
sudo apt-get autoremove --yes
sudo apt-get autoclean --yes

# 2.1. Kubernetes pre-reqs (kubeadm preflight)
# conntrack é obrigatório para kubeadm init/join em praticamente todos os cenários
sudo apt-get update
sudo apt-get install --yes \
  conntrack \
  socat \
  ebtables \
  iptables

# 2.2. Install kubelet/kubeadm/kubectl
sudo apt install --yes kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl