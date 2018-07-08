#!/bin/sh
#
# Program: This script will install and download packages.
# History: 2018/07/07 k2r2.bai release.

set -eu

: ${WITH_CTL:="false"}
: ${WITH_CFSSL:="false"}

# install docker
curl -fsSL "https://get.docker.com/" | sh

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# apply sysctl envs
sudo sysctl -p /etc/sysctl.d/k8s.conf

# close swap
sudo swapoff -a && sudo sysctl -w vm.swappiness=0
sudo sed '/swap.img/d' -i /etc/fstab

# download cni bin
sudo mkdir -p /opt/cni/bin && cd /opt/cni/bin
CNI_URL="https://github.com/containernetworking/plugins/releases/download"
sudo wget -qO- --show-progress "${CNI_URL}/v0.7.1/cni-plugins-amd64-v0.7.1.tgz" | tar -zx

# download kubelet and kubectl
export KUBE_URL=https://storage.googleapis.com/kubernetes-release/release/v1.11.0/bin/linux/amd64
sudo wget "${KUBE_URL}/kubelet" -O /usr/local/bin/kubelet
sudo chmod +x /usr/local/bin/kubelet

if [[ ${WITH_CTL} == "true" ]]; then
  sudo wget "${KUBE_URL}/kubectl" -O /usr/local/bin/kubectl
  sudo chmod +x /usr/local/bin/kubectl
fi

# download cfssl tool
if [[ ${WITH_CFSSL} == "true" ]]; then
  CFSSL_URL="https://pkg.cfssl.org/R1.2"
  sudo wget "${CFSSL_URL}/cfssl_linux-amd64" -O /usr/local/bin/cfssl
  sudo wget "${CFSSL_URL}/cfssljson_linux-amd64" -O /usr/local/bin/cfssljson
  sudo chmod +x /usr/local/bin/cfssl /usr/local/bin/cfssljson
fi
