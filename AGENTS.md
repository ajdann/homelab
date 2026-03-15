# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-15
**Commit:** fdc5194
**Branch:** feature/tailscale-auth-fix

## OVERVIEW

Kubernetes homelab: K3s cluster with Flux GitOps, Tailscale VPN, and defense-in-depth security stack (Wazuh SIEM, Falco, Kyverno, Kubescape, Nessus). Supports two workflows: cloud VM (Ansible) and local Vagrant.

## STRUCTURE

```
homelab/
├── infra/                # IaC: Ansible, Terraform (Proxmox), Vagrant VMs
│   ├── ansible/          # Playbooks, 10 roles, 3 inventories
│   ├── terraform/        # Proxmox VM provisioning (alternative path)
│   ├── vagrant/           # VM definitions, resources, helpers
│   └── Vagrantfile
├── kubernetes/           # Flux GitOps manifests (267 YAML files)
│   ├── clusters/homelab/ # Flux entrypoint — reconciles everything below
│   ├── core/             # Tailscale, Reloader, Traefik, etc.
│   ├── security/         # Wazuh, Kyverno, Falco, Kubescape, etc.
│   ├── apps/             # Homepage, Gitea, Nextcloud, etc.
│   └── monitoring/       # Loki stack
├── secrets/              # GITIGNORED — vm_user, SSH keys, .env, kubeconfig
├── makefile              # Thin wrapper: bootstrap, vagrant-up, healthcheck
├── butane.yaml           # Alternative: Flatcar Linux + kubeadm (not K3s)
└── pfsense-config.xml    # pfSense firewall export
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Bootstrap cloud VM | `make bootstrap` | Runs k8s-server.yaml then k8s-bootstrap.yaml |
| Bootstrap local | `make vagrant-full` | Brings up k3s-master-1 with full provisioning |
| Add K8s component | `kubernetes/{core,apps,security,monitoring}/<name>/` | Follow base/overlays/dev pattern |
| Add Ansible role | `infra/ansible/roles/<name>/` | tasks/, defaults/, vars/, handlers/ |
| Add Kyverno policy | `kubernetes/security/kyverno/base/policies/` | Then add to kustomization.yaml |
| Tailscale OAuth | `secrets/.env` → Ansible creates K8s Secret | See `.env.example` for format |
| Health check | `make healthcheck` | Runs cluster_health role |
| CI workflows | `.github/workflows/` | yamllint, kubesec, kustomize-validate, trivy, gitleaks, checkov |

## CONVENTIONS

- **YAML**: 2-space indent, `---` document start, line-length disabled. See `.yamllint`
- **Ansible vars**: snake_case. Secrets via `lookup('file', ...)` from `secrets/` dir
- **K8s manifests**: `app.kubernetes.io/name` labels, resource name = app name, namespace = app name
- **K8s security context**: `runAsNonRoot: true`, UID 1000, `capabilities.drop: [ALL]`, `seccompProfile: RuntimeDefault`
- **Kustomize**: Every component follows `base/` + `overlays/dev/` pattern
- **Helm**: Namespace-scoped HelmRepository + HelmRelease per component
- **Inventory selection**: `single-node.yaml` (cloud), `vagrant.yaml` (local). `hosts.yaml` = Proxmox multi-node
- **Vagrant detection**: `vagrant_run: true` in inventory skips secrets lookups, uses `vagrant` user

## ANTI-PATTERNS (THIS PROJECT)

- **Never commit secrets** — `secrets/`, `.env`, `kubeconfig`, `age.key` are gitignored
- **K8s secrets are NOT encrypted** — dev overlay uses plain base64 Secrets (not SealedSecrets/SOPS). Acceptable for dev only
- **Gitleaks allowlist**: `kubernetes/overlays/dev/` is excluded from secret scanning (`.gitleaks.toml`)
- **No `site.yaml`** — Makefile chains playbooks instead of a master playbook
- **Terraform Flux is commented out** — `infra/terraform/flux.tf` was abandoned in favor of Ansible bootstrap
- **Proxmox password hardcoded** in `group_vars/proxmox.yaml` and `terraform/provider.tf`

## UNIQUE STYLES

- **Dual workflow**: Same Ansible playbooks serve both cloud VM and Vagrant. Detected via `vagrant_run` flag
- **Ansible bootstraps Flux**: Rsyncs manifests to node then applies (not `flux bootstrap`). Unusual but intentional
- **Vagrant uses `ansible_local`**: Ansible runs inside VM, not from host. Playbooks accessed via `/vagrant` synced folder
- **FluxInstance CR** (not `flux bootstrap`): Uses Flux Operator pattern with `fluxInstance.yaml`
- **Flux postBuild substitutions**: `DOMAIN` variable injected from ConfigMap `flux-substitutions`
- **Security-first CI**: 6 GitHub Actions workflows, all security-focused (no build/deploy CI)

## COMMANDS

```bash
# Cloud VM bootstrap (K3s + Flux)
make bootstrap

# Local Vagrant (full provisioning)
make vagrant-full

# Health check
make healthcheck

# Tailscale agent only (Vagrant)
make tailscale-vagrant

# Vagrant VMs up (no provision)
make up

# Wazuh cert generation
bash kubernetes/security/wazuh/base/certs/indexer_cluster/generate_certs.sh

# Terraform (Proxmox only)
cd infra/terraform && terraform apply
```

## NOTES

- **Flux reconciles `dev` branch** — not `main`. See `gitrepository.yaml`
- **GitOps interval**: GitRepository polls every 10s, Kustomization reconciles every 1m
- **Only 2 core components active**: Tailscale + Reloader. Others (dashboard, traefik, prometheus, etc.) are commented out in `kubernetes/core/overlays/dev/kustomization.yaml`
- **Only 1 app active**: Homepage. Others (adguard, gitea, authentik, nextcloud, seafile) commented out
- **All 7 security tools active** in dev overlay
- **Only 1 of 16 Kyverno policies enabled** (`require-labels`). Rest available but commented out
- **`kubeconfig` make target** referenced in README but missing from Makefile
- **Ansible collections required**: `community.general`, `community.proxmox`, `kubernetes.core` (see `requirements.yaml`)
- **Wazuh NodePorts hardcoded**: 31514 (events), 31515 (registration) in Vagrant provisioner
