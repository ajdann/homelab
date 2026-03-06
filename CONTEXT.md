# Homelab – AI Context

This file gives AI assistants (Cursor, Gemini, etc.) enough context to work effectively in this repo.

## What This Repo Is

A **homelab** project: a secure, Kubernetes-based environment with Tailscale VPN for private access. It uses defense-in-depth (pfSense, Tailscale, Wazuh SIEM, Falco, Kyverno, Nessus). The goal is to automate setup and management of a personal cloud / lab environment.

## Primary Workflow: Cloud VM

The **main development and test target is a cloud VM**, not local Vagrant.

- **Target**: VM IP and SSH details come from `infra/ansible/inventory/single-node.yaml` and `infra/ansible/group_vars/all.yaml` (e.g. `k3s-master-1` with `ansible_host`).
- **Secrets** (not in repo): live in **`secrets/`** at project root. Expected files include: `vm_user`, `vm_password`, `vm_ssh_pub_key`, `vm_ssh_private_key`, `.env` (Tailscale OAuth, etc.), and optionally `kubeconfig` after bootstrap.
- **Bootstrap**: From project root run **`make bootstrap`**. This runs the Ansible playbook `infra/ansible/playbooks/k8s-bootstrap.yaml` against the inventory (cloud VM). No Vagrant step required for the cloud VM workflow.
- **Optional local demo**: For a local VM, use `make vagrant-up` (or `make up` if that target exists) then `make bootstrap`; a Vagrantfile may live in a subdirectory or be added later.

## Directory Layout

| Path | Purpose |
|------|--------|
| **`infra/ansible/`** | Ansible playbooks, roles, inventory, `group_vars`. Playbooks: `k8s-server.yaml`, `k8s-bootstrap.yaml`, `k8s-healthcheck.yaml`, plus proxmox, haproxy, wazuh-agent, nessus, etc. |
| **`kubernetes/`** | Flux GitOps and Kustomize. **`kubernetes/clusters/homelab/flux-system/`** – Flux GitRepository (points at this repo, `dev` branch). Rest is Kustomize bases/overlays for core (e.g. Tailscale), security (Wazuh, Kyverno, Falco, Kubescape, policy-reporter), monitoring (e.g. Loki). |
| **`secrets/`** | Credentials and keys (gitignored). VM user/password, SSH keys, `.env` for Tailscale, kubeconfig. |
| **`butane.yaml`** | Butane config for **Flatcar Linux** + kubeadm – alternative/experimental path (not the main Ansible/K3s flow). |
| **Root** | `Makefile`, `README.md`, `CONTEXT.md`, `gemini.md`, `.env.example`, `pfsense-config.xml`, etc. |

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
