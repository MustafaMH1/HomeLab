#!/bin/sh
# setup-storage.sh
#
# Formats and mounts the secondary data disk (/dev/sdb) on K3s worker nodes,
# mapping it directly to the K3s local-path-provisioner storage directory
# so persistent volumes land on the dedicated HDD pool instead of the
# small OS SSD.
#
# Run on WORKER nodes only (k3s-worker1, k3s-worker2).
# Assumes the data disk is attached via the SATA bus as /dev/sdb
# and is currently raw/unpartitioned.
#
# WARNING: This will erase all data on /dev/sdb. Double-check the device
# name (lsblk) before running on a real node.

set -e

DATA_DISK="/dev/sdb"
DATA_PART="${DATA_DISK}1"
MOUNT_POINT="/var/lib/rancher/k3s/storage"

echo "[setup-storage] Installing partitioning/filesystem tools ..."
apk update
apk add parted e2fsprogs

echo "[setup-storage] Creating GPT label on ${DATA_DISK} ..."
parted "${DATA_DISK}" mklabel gpt

echo "[setup-storage] Creating primary ext4 partition (100% of disk) ..."
parted -a optimal "${DATA_DISK}" mkpart primary ext4 0% 100%

echo "[setup-storage] Formatting ${DATA_PART} as ext4 ..."
mkfs.ext4 "${DATA_PART}"

echo "[setup-storage] Creating mount point at ${MOUNT_POINT} ..."
mkdir -p "${MOUNT_POINT}"

echo "[setup-storage] Adding fstab entry ..."
if ! grep -q "${DATA_PART}" /etc/fstab; then
  echo "${DATA_PART} ${MOUNT_POINT} ext4 defaults 0 2" >> /etc/fstab
else
  echo "[setup-storage] fstab entry already present, skipping."
fi

echo "[setup-storage] Mounting all fstab entries ..."
mount -a

echo "[setup-storage] Done. ${DATA_PART} is mounted at ${MOUNT_POINT}."
df -h "${MOUNT_POINT}"
