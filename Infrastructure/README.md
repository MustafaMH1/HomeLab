# k3s-alpine-homelab

A 3-node, ultra-lightweight K3s Kubernetes cluster running on Alpine Linux VMs
inside Proxmox VE.

## Cluster Topology

| Role          | Hostname      | IP             | Notes                          |
|---------------|---------------|----------------|---------------------------------|
| Control plane | k3s-master    | 192.168.1.70   | K3s server                     |
| Worker        | k3s-worker1   | 192.168.1.71   | + 150GB data disk              |
| Worker        | k3s-worker2   | 192.168.1.72   | + 150GB data disk              |

- **Subnet / Gateway:** `192.168.1.0/24` / `192.168.1.1`
- **Cluster join token:** `myhomelabtoken123` (change this for anything beyond a home lab)

## Storage Architecture

Each node has a **15GB SSD** (`local-lvm` pool) for the OS. Each worker also
has a **150GB HDD** virtual disk from a separate high-capacity pool
(`Vauld-HDD`), dedicated to persistent volume container data.

Worker data disks are formatted ext4 and mounted directly at
`/var/lib/rancher/k3s/storage` — the path K3s' built-in
local-path-provisioner uses for persistent volumes — rather than a generic
mount point.

## Prerequisites / Gotchas

- **Proxmox disk bus:** Use **SATA** (`sata0`, `sata1`), not the default
  VirtIO SCSI. VirtIO SCSI caused boot loops / bootloader detection failures
  on this Alpine setup.
- **cgroups:** Alpine doesn't mount cgroups by default. Without patching the
  boot config, containerd fails with a `memory.max` missing-folder loop.
  `scripts/cgroup-fix.sh` handles this — run it (and reboot) **before**
  installing K3s on every node.
- **Cloned worker identity collisions:** Since the workers were made as full
  clones of the master's VM, each clone still carries the master's identity.
  Before joining a cloned node to anything, on each worker:
  ```sh
  # Update /etc/hostname to k3s-worker1 / k3s-worker2
  # Update /etc/network/interfaces with the worker's static IP
  cat /dev/null > /etc/machine-id
  cat /dev/null > /var/lib/dbus/machine-id
  rc-service networking restart
  reboot
  ```

## Build Order

1. **Install base OS on k3s-master**
   Boot the Alpine Linux Extended ISO, run `setup-alpine`, assign static IP
   `192.168.1.70`, set the root password.

2. **Clone workers**
   Shut down k3s-master cleanly, full-clone it twice in Proxmox to create
   k3s-worker1 and k3s-worker2. Follow the identity-decoupling steps above
   on each clone.

3. **Fix cgroups on all 3 nodes**
   ```sh
   ./scripts/cgroup-fix.sh
   reboot
   ```

4. **Set up worker storage (worker nodes only)**
   ```sh
   ./scripts/setup-storage.sh
   ```

5. **Install K3s server (master only)**
   ```sh
   ./scripts/install-master.sh
   ```

6. **Install K3s agent (each worker)**
   ```sh
   NODE_IP=192.168.1.71 ./scripts/install-worker.sh   # k3s-worker1
   NODE_IP=192.168.1.72 ./scripts/install-worker.sh   # k3s-worker2
   ```

7. **Verify**
   From the master:
   ```sh
   kubectl get nodes -o wide
   ```
   All three nodes should show `Ready`.

## Repo Layout

```
k3s-alpine-homelab/
├── README.md
└── scripts/
    ├── cgroup-fix.sh       # run on all nodes before installing K3s
    ├── setup-storage.sh    # run on worker nodes to format/mount data disk
    ├── install-master.sh   # run on the master to install the K3s server
    └── install-worker.sh   # run on each worker to join the cluster
```

## Security Notes

This is documented as a home lab setup, so defaults favor convenience
(shared static token, `--write-kubeconfig-mode=644` for easy admin access).
If you expose this cluster beyond your LAN, at minimum:
- Rotate `K3S_TOKEN` to something random and keep it out of version control
  (e.g. via an untracked `.env` or Proxmox-injected secret).
- Restrict kubeconfig permissions instead of the open `644` mode.
