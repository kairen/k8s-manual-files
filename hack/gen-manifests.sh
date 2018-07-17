#!/bin/sh
#
# Program: Generate kubernetes static pod files.
# History: 2018/07/07 k2r2.bai release.

set -eu

: ${NODES:="k8s-m1 k8s-m2 k8s-m3"}
: ${ADVERTISE_VIP:="172.22.132.9"}
: ${MANIFESTS_TPML_DIR:="master/manifests"}
: ${ENCRYPT_TPML_DIR:="master/encryption"}
: ${ADUIT_TPML_DIR:="master/audit"}
: ${FILES:="etcd.yml haproxy.yml keepalived.yml kube-apiserver.yml kube-controller-manager.yml kube-scheduler.yml"}

RED='\033[0;31m'
NC='\033[0m'
MANIFESTS_PATH="/etc/kubernetes/manifests"
ENCRYPT_PATH="/etc/kubernetes/encryption"
ADUIT_PATH="/etc/kubernetes/audit"
HOST_START=$(ip route get 8.8.8.8 | awk '{print $NF; exit}')
ENCRYPT_SECRET=$(openssl rand -hex 16)

ETCD_SERVERS=""
UNICAST_PEERS=""
for NODE in ${NODES}; do
  IP=$(ssh ${NODE} "ip route get 8.8.8.8" | awk '{print $NF; exit}')
  ETCD_SERVERS="${ETCD_SERVERS}https:\/\/${IP}:2379,"
  UNICAST_PEERS="${UNICAST_PEERS}'${IP}',"
  HOST_END=${IP}
done
ETCD_SERVERS=$(echo ${ETCD_SERVERS} | sed 's/.$//')
UNICAST_PEERS=$(echo ${UNICAST_PEERS} | sed 's/,$//')

# generate manifests
i=0
for NODE in ${NODES}; do
  ssh ${NODE} "sudo mkdir -p ${MANIFESTS_PATH} ${ENCRYPT_PATH} ${ADUIT_PATH}"
  for FILE in ${FILES}; do
    scp ${MANIFESTS_TPML_DIR}/${FILE} ${NODE}:${MANIFESTS_PATH}/${FILE} 2>&1 > /dev/null
  done

  # configure keepalived
  NIC=$(ssh ${NODE} "ip route get 8.8.8.8" | awk '{print $5; exit}')
  PRIORITY=150
  if [ ${i} -eq 0 ]; then
    PRIORITY=100
  fi
  ssh ${NODE} "sed -i 's/\${ADVERTISE_VIP}/${ADVERTISE_VIP}/g' ${MANIFESTS_PATH}/keepalived.yml;
               sed -i 's/\${ADVERTISE_VIP_NIC}/${NIC}/g' ${MANIFESTS_PATH}/keepalived.yml;
               sed -i 's/\${UNICAST_PEERS}/${UNICAST_PEERS}/g' ${MANIFESTS_PATH}/keepalived.yml;
               sed -i 's/\${PRIORITY}/${PRIORITY}/g' ${MANIFESTS_PATH}/keepalived.yml"

  # configure kue-apiserver
  ssh ${NODE} "sed -i 's/\${ADVERTISE_VIP}/${ADVERTISE_VIP}/g' ${MANIFESTS_PATH}/kube-apiserver.yml;
               sed -i 's/\${ETCD_SERVERS}/${ETCD_SERVERS}/g' ${MANIFESTS_PATH}/kube-apiserver.yml;"

  # configure encryption
  scp ${ENCRYPT_TPML_DIR}/config.yml ${NODE}:${ENCRYPT_PATH}/config.yml 2>&1 > /dev/null
  ssh ${NODE} "sed -i 's/\${ENCRYPT_SECRET}/${ENCRYPT_SECRET}/g' ${ENCRYPT_PATH}/config.yml"

  # configure audit
  scp ${ADUIT_TPML_DIR}/policy.yml ${NODE}:${ADUIT_PATH}/policy.yml 2>&1 > /dev/null

  echo "${RED}${NODE}${NC} manifests generated..."
  i=$((i+1))
done
