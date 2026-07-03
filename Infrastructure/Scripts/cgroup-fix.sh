#!/bin/sh
# cgroup-fix.sh
#
# Patches Alpine Linux boot config to enable cgroups before K3s/containerd
# start. Without this, container runtimes fail with a "memory.max missing
# folder" loop because Alpine does not mount cgroups by default.
#
# Run on ALL nodes (master + workers) BEFORE installing K3s.
# Requires a reboot after running.

set -e

echo "[cgroup-fix] Patching /etc/update-extlinux.conf ..."
sed -i 's/default_kernel_opts="/default_kernel_opts="cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory /' /etc/update-extlinux.conf

echo "[cgroup-fix] Regenerating extlinux config ..."
update-extlinux

echo "[cgroup-fix] Enabling cgroups service at boot ..."
rc-update add cgroups boot

echo "[cgroup-fix] Done. Reboot this node for changes to take effect:"
echo "    reboot"
