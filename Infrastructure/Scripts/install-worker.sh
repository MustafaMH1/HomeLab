#!/bin/sh
# install-worker.sh
#
# Installs the K3s agent on a worker node and joins it to k3s-master.
# Run this AFTER cgroup-fix.sh + reboot and setup-storage.sh,
# on each worker node.
#
# Usage:
#   NODE_IP=192.168.1.71 ./install-worker.sh   # on k3s-worker1
#   NODE_IP=192.168.1.72 ./install-worker.sh   # on k3s-worker2
#
# Env vars (override as needed):
#   K3S_TOKEN     Cluster join token          (default: myhomelabtoken123)
#   K3S_URL       Master API server URL       (default: https://192.168.1.70:6443)
#   NODE_IP       This node's static IP       (required)

set -e

K3S_TOKEN="${K3S_TOKEN:-myhomelabtoken123}"
K3S_URL="${K3S_URL:-https://192.168.1.70:6443}"
NODE_IP="${NODE_IP:?Set NODE_IP to this worker's static IP, e.g. 192.168.1.71}"

echo "[install-worker] Installing curl/bash prerequisites ..."
apk update
apk add curl bash

echo "[install-worker] Joining ${NODE_IP} to cluster at ${K3S_URL} ..."
curl -sfL https://get.k3s.io | K3S_TOKEN="${K3S_TOKEN}" K3S_URL="${K3S_URL}" sh -s - agent \
  --node-ip="${NODE_IP}"

echo "[install-worker] Enabling k3s-agent at boot ..."
rc-update add k3s-agent default

echo "[install-worker] Done. Confirm from the master with:"
echo "    kubectl get nodes -o wide"
