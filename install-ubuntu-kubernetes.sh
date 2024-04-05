#!/bin/bash

# Disable swap
sudo sed -e '/swap/ s/^#*/#/' -i /etc/fstab
sudo swapoff -a

# Install Docker (https://docs.docker.com/engine/install/ubuntu/)
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo apt-mark hold docker-ce docker-ce-cli containerd.io

# Configure Docker (https://v1-22.docs.kubernetes.io/docs/setup/production-environment/container-runtimes/#docker)
mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# Install kubeadm (https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo mkdir -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Initialize Kubernetes (https://v1-22.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint "m-csd3325-cluster-temp2.westeurope.cloudapp.azure.com:6443" 
sudo mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo kubectl taint nodes --all node-role.kubernetes.io/master-  ####PENDING####

# Install a Pod network add-on 
FLANNEL_VERSION="0.15.1"
sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v${FLANNEL_VERSION}/Documentation/kube-flannel.yml

# Download and install Helm (https://helm.sh)
HELM_VERSION="3.8.0"
sudo curl -LO https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz
sudo tar -zxvf helm-v${HELM_VERSION}-linux-amd64.tar.gz
sudo cp linux-amd64/helm /usr/local/bin/
sudo rm -rf helm-v${HELM_VERSION}-linux-amd64.tar.gz linux-amd64
sudo helm plugin install https://github.com/databus23/helm-diff
