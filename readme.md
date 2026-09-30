# Local Kubernetes Cluster with Ansible & Kubeadm

![Ansible](https://img.shields.io/badge/ansible-%231A1918.svg?style=flat&logo=ansible&logoColor=white) ![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=flat&logo=kubernetes&logoColor=white)

This repository contains Ansible playbooks and roles to automate the provisioning and management of a local Kubernetes cluster using `kubeadm`. It is designed to bootstrap a cluster from scratch on bare metal servers or local virtual machines.

## Project Structure

```text
.
├── Makefile            # Convenient commands for setup, deployment, pinging, and linting
├── inventory.yml       # Defines control plane and worker nodes, SSH vars, and k8s configuration
├── requirements.yml    # Ansible Galaxy collection dependencies
├── site.yml            # Main playbook entry point
├── addons/             # Additional Kubernetes cluster manifests and storage configurations
└── roles/
    ├── common          # System setup (containerd, swap disable, kernel modules, kubeadm binaries)
    ├── control-plane   # Cluster initialization (kubeadm init), CNI (Calico), join token generation
    └── worker          # Joins worker nodes to the cluster (kubeadm join)
```

## Prerequisites

Before running the playbooks, ensure the following:

1. **Ansible Installed:** You need Ansible installed on your control machine (`ansible` and `ansible-playbook`).
2. **Target Machines:** At least 1 control plane node and worker nodes (Ubuntu/Debian) ready.
3. **SSH Access:** Passwordless SSH access (keys) configured from your control machine to the target nodes.
4. **Sudo Privileges:** The user connecting via SSH must have passwordless sudo privileges.

---

## Quickstart & Helper Commands (`Makefile`)

To streamline your workflow and provide a smoother starter experience, common tasks are wrapped in the project `Makefile`.

Run `make help` or `make` at any time to see available commands:

```bash
make help
```

### Key Make Commands:

| Command | Description | Example Usage |
| :--- | :--- | :--- |
| `make install` | Installs Galaxy collections defined in `requirements.yml` | `make install` |
| `make ping` | Checks SSH connectivity to all inventory nodes | `make ping` |
| `make lint` | Performs syntax checks and runs `ansible-lint` | `make lint` |
| `make dry-run` | Runs playbook in check mode with `--diff` | `make dry-run` |
| `make deploy` | Runs the full Ansible playbook (`site.yml`) | `make deploy` |
| `make deploy TAGS=...` | Runs playbook filtered by tags | `make deploy TAGS=configure_control_plane` |

---

## Usage Guide

### 1. Install Ansible Dependencies

Install the required Ansible dependencies (Posix and Community General collections):

```bash
make install
# Or manually: ansible-galaxy install -r requirements.yml
```

### 2. Configure Inventory

Edit `inventory.yml` to reflect your target infrastructure and preferences:

```yaml
all:
  vars:
    k8s_version: 1.31
    cilium_version: 1.20.0
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/your_key.pem
    ansible_python_interpreter: /usr/bin/python3
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
  children:
    control_plane:
      hosts:
        control-plane-01:
          ansible_host: 172.16.167.11
    workers:
      hosts:
        worker-01:
          ansible_host: 172.16.167.101
        worker-02:
          ansible_host: 172.16.167.102
```

### 3. Verify Connectivity

Test connection to all control plane and worker nodes:

```bash
make ping
# Or manually: ansible -i inventory.yml all -m ping
```

### 4. Run Dry Run (Optional)

Preview changes without modifying host configurations:

```bash
make dry-run
```

### 5. Deploy the Cluster

Run the playbook to provision containerd, `kubeadm`, `kubelet`, initialize the control plane with Cilium CNI, and join worker nodes:


```bash
make deploy
# Or manually: ansible-playbook -i inventory.yml site.yml
```

> **Note:** Deployment may take several minutes while nodes download container images and Kubernetes binaries.

#### Selective Runs with Tags

You can selectively run parts of the playbook using tags:

- **Prerequisites only:** `make deploy TAGS=prereqs`
- **Control plane only:** `make deploy TAGS=configure_control_plane`
- **Worker join only:** `make deploy TAGS=join_workers`
- **Adding a new worker node (Prereqs + Join):** 
  ```bash
  ansible-playbook -i inventory.yml site.yml --limit new-worker-node --tags "prereqs,join_workers"
  # Or via Makefile:
  make deploy TAGS="prereqs,join_workers" OPTS="--limit new-worker-node"
  ```


---

## Role Breakdown

### `roles/common`
- Disables Swap (required by Kubelet).
- Loads kernel modules (`overlay`, `br_netfilter`) and configures sysctl parameters.
- Installs and configures `containerd` runtime with systemd cgroup driver.
- Configures Kubernetes APT repository and installs `kubelet`, `kubeadm`, and `kubectl` (configured for version `1.31` by default).

### `roles/control-plane`
- Runs `kubeadm init` on the control plane node.
- Sets up `.kube/config` for standard user access.
- Deploys Cilium Pod Network Addon.
- Generates join token and certificate hash for worker nodes.


### `roles/worker`
- Fetches join credentials from the control plane node.
- Executes `kubeadm join` to connect worker nodes to the cluster.

---

## Verification

After deployment completes, SSH into your control plane node and verify host status:

```bash
kubectl get nodes
```

Expected output: All control plane and worker nodes should report status `Ready`.
