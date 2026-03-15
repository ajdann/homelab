# Homelab – AI Context

This file gives AI assistants (Cursor, Gemini, OpenCode, etc.) enough context to work effectively in this repo.

## What This Repo Is

A **homelab** project: a secure, Kubernetes-based environment with Tailscale VPN for private access. It uses defense-in-depth (pfSense, Tailscale, Wazuh SIEM, Falco, Kyverno, Nessus). The goal is to automate setup and management of a personal cloud / lab environment.

## Primary Workflows

This project supports **two equally valid workflows** — choose based on what's available to you:

---

### Option 1: Cloud VM (Remote)

Use when you have a cloud VM available (e.g., Azure, GCP, Hetzner).

- **Target**: VM IP and SSH details come from `infra/ansible/inventory/single-node.yaml` (e.g., `k3s-master-1` with `ansible_host`).
- **Secrets** (not in repo): live in **`secrets/`** at project root. Expected files:
  - `vm_user` — SSH username
  - `vm_password` — SSH password (if using password auth)
  - `vm_ssh_pub_key` — SSH public key
  - `vm_ssh_private_key` — SSH private key
  - `.env` — Tailscale OAuth credentials
  - `kubeconfig` — (created after bootstrap)
- **Bootstrap**:
  ```bash
  make bootstrap
  ```
  This runs `k8s-server.yaml` then `k8s-bootstrap.yaml` against the cloud VM.

---

### Option 2: Vagrant (Local)

Use when you want to run everything locally on your machine.

- **Target**: VMs managed by Vagrant in `infra/Vagrantfile`. Supports: pfSense, Nessus, HAProxy, K3s master, K3s workers.
- **Requirements**: Vagrant + VirtualBox (or another provider) + Ansible.
- **Bootstrap**:
  ```bash
  # Full setup: bring up k3s-master-1 and run all provisioners
  make vagrant-full

  # Or just bring up VMs without provisioning
  make up  # or: make vagrant-up
  ```
- **Inventory**: Uses `infra/ansible/inventory/vagrant.yaml` (auto-detects SSH port via `vagrant ssh-config`).

---

## Directory Layout

| Path | Purpose |
|------|--------|
| **`infra/ansible/`** | Ansible playbooks, roles, inventory, `group_vars`. Playbooks: `k8s-server.yaml`, `k8s-bootstrap.yaml`, `k8s-healthcheck.yaml`, plus proxmox, haproxy, wazuh-agent, nessus, etc. |
| **`infra/ansible/inventory/`** | Two inventories: `single-node.yaml` (cloud VM), `vagrant.yaml` (local Vagrant). |
| **`infra/Vagrantfile`** | Vagrant configuration for local VMs. Config in `infra/vagrant/` (vms/, config/, lib/). |
| **`kubernetes/`** | Flux GitOps and Kustomize. **`kubernetes/clusters/homelab/flux-system/`** – Flux GitRepository (points at this repo, `dev` branch). Rest is Kustomize bases/overlays for core (e.g. Tailscale), security (Wazuh, Kyverno, Falco, Kubescape, policy-reporter), monitoring (e.g. Loki). |
| **`secrets/`** | Credentials and keys (gitignored). VM user/password, SSH keys, `.env` for Tailscale, kubeconfig. |
| **`butane.yaml`** | Butane config for **Flatcar Linux** + kubeadm – alternative/experimental path (not the main Ansible/K3s flow). |
| **Root** | `makefile`, `README.md`, `CONTEXT.md`, `.env.example`, `pfsense-config.xml`, etc. |

## Key Tools & Conventions

- **Ansible**: Drives node bootstrap, K3s install, K8s bootstrap (Flux, Tailscale operator), healthchecks. Use `group_vars/all.yaml` and inventory under `infra/ansible/`.
- **K3s**: Kubernetes distribution used on the VM(s). Kubeconfig path on server: `/etc/rancher/k3s/k3s.yaml`; copied to `secrets/kubeconfig` via playbooks.
- **Flux**: GitOps; cluster reconciles from this repo (`dev` branch). Bootstrap installs Flux and points it at the repo.
- **Tailscale**: OAuth client + ACL tag **`tag:k8s-operator`** (owned by `autogroup:admin`) required for the Tailscale Kubernetes operator. Credentials in `.env` (e.g. `TAILSCALE_CLIENT_ID`, `TAILSCALE_CLIENT_SECRET`, `TAILSCALE_DOMAIN`).
- **Config format**: YAML for Ansible and Kubernetes; consistent naming for resources and files.
- **Secrets**: Never commit secrets. Use `secrets/` and, in K8s, sealed secrets or similar as in the Wazuh overlays.

## User Preferences

- Prefer **clear, concise** explanations.
- **Inform the user** about any changes made to the system or repo.

For full architecture, security stack, and step-by-step setup (including Tailscale OAuth), see **README.md**.
