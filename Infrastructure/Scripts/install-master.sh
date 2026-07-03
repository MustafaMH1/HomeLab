#!/bin/sh
# install-master.sh
#
# Installs the K3s control plane (server) on k3s-master.
# Run this AFTER cgroup-fix.sh + reboot, on the master node only.
#
# Env vars (override as needed):
#   K3S_TOKEN     Cluster join token          (default: myhomelabtoken123)
#   NODE_IP       This node's static IP       (default: 192.168.1.70)

set -e

K3S_TOKEN="${K3S_TOKEN:-myhomelabtoken123}"
NODE_IP="${NODE_IP:-192.168.1.70}"

echo "[install-master] Installing curl/bash prerequisites ..."
apk update
apk add curl bash

echo "[install-master] Installing K3s server on ${NODE_IP} ..."
curl -sfL https://get.k3s.io | K3S_TOKEN="${K3S_TOKEN}" sh -s - server \
  --node-ip="${NODE_IP}" \
  --bind-address="${NODE_IP}" \
  --write-kubeconfig-mode=644

echo "[install-master] Done. Verify with:"
echo "    kubectl get nodes -o wide"
echo ""
echo "[install-master] Node token for workers is at /var/lib/rancher/k3s/server/node-token"
