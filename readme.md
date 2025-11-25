# Local Kubernetes Cluster with Ansible & Kubeadm

![Ansible](https://img.shields.io/badge/ansible-%231A1918.svg?style=flat&logo=ansible&logoColor=white) ![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=flat&logo=kubernetes&logoColor=white)

This repository contains Ansible playbooks and roles to automate the provisioning and management of a local Kubernetes cluster using `kubeadm`. It is designed to bootstrap a cluster from scratch on bare metal servers or local virtual machines.

## Project Structure

```text
.
├── inventory.yml       # Defines your control plane and worker nodes (IPs/Hostnames)
├── requirements.yml    # Ansible Galaxy collection dependencies
├── roles
│   ├── common          # Dependencies (Containerd, swap settings, kernel modules)
│   ├── control-plane   # Initializes the cluster (kubeadm init) and networking (Flannel)
│   └── worker          # Joins nodes to the cluster (kubeadm join)
└── site.yml            # Main playbook entry point

```

## Prerequisites

Before running the playbooks, ensure the following:

1.  **Ansible Installed:** You need Ansible installed on your control machine.
2.  **Target Machines:** You should have at least 2 Linux VMs (Ubuntu/Debian) ready.
3.  **SSH Access:** Passwordless SSH access (keys) configured from your control machine to the target nodes.
4.  **Sudo Privileges:** The user connecting via SSH must have passwordless sudo privileges.

## Usage

### 1. Configure Inventory

Edit the `inventory.yml file to match your local network setup.

Crucial: You must update the ansible_user and ansible_ssh_private_key_file variables to match your environment:

```yaml
vars:
  ansible_ssh_private_key_file: ~/.ssh/your_key.pub
  ansible_user: your_username
```

### 2. Install Ansible Dependencies

Install the required Ansible collections (Posix and Community General) defined in `requirements.yml`:

```bash
ansible-galaxy install -r requirements.yml
```

### 2. Connectivity Check

Verify that Ansible can talk to your nodes:

```bash
ansible all -i inventory.yml -m ping
```

### 3. Run the Playbook

Execute the main playbook to set up the cluster:

```bash
ansible-playbook -i inventory.yml site.yml
```

> **Note:** This process may take several minutes depending on your internet connection speed, as it downloads required binaries and container images.

## Role Breakdown

### `roles/common`

- Disables Swap (required by Kubelet).
- Installs Container Runtime (e.g., Containerd or Docker).
- Installs `kubelet`, `kubeadm`, and `kubectl`.
- Configures necessary kernel modules and sysctl params.

### `roles/control-plane`

- Runs `kubeadm init` on the primary node.
- Sets up the `.kube` config directory for the user.
- Installs the Pod Network Addon (e.g., Calico or Flannel).
- Generates the join command for workers.

### `roles/worker`

- Retrieves the join token from the control plane.
- Runs `kubeadm join` to connect the worker to the cluster.

## Verification

Once the playbook finishes, SSH into your control plane node and run:

```bash
kubectl get nodes
```

You should see your control plane and worker nodes with a status of `Ready`.
