# INFRA — IaC & VM Provisioning

## OVERVIEW

Three provisioning paths: Ansible (primary), Terraform (Proxmox VMs), Vagrant (local dev). Ansible is the only actively used bootstrap path.

## STRUCTURE

```
infra/
├── ansible/
│   ├── playbooks/        # 9 playbooks — entry points for all operations
│   ├── roles/            # 10 roles (see role map below)
│   ├── inventory/        # 3 inventories: single-node, vagrant, hosts (Proxmox)
│   ├── group_vars/       # all.yaml (global), proxmox.yaml
│   ├── ansible.cfg       # Default inventory: hosts.yaml, roles_path: ./roles
│   ├── requirements.yaml # Galaxy collections: community.general, community.proxmox, kubernetes.core
│   └── requirements.txt  # Python deps for pip install inside VMs
├── terraform/            # Proxmox VM provisioning (alternative to Vagrant)
├── vagrant/
│   ├── config/vm_resources.rb  # VM specs: CPU, memory, IPs, enabled/disabled
│   ├── lib/helpers.rb          # Netplan template + VirtualBox DHCP hack
│   ├── powershell.ps1          # WSL→Windows sync helper script
│   └── vms/              # 5 VM definitions (Ruby): pfsense, nessus, haproxy, k3s_master, k3s_workers
├── flatcar/              # Alternative: Flatcar Linux + kubeadm (not K3s)
│   └── butane.yaml
├── pfsense/              # pfSense firewall export
│   └── pfsense-config.xml
└── Vagrantfile           # Loads vagrant/config + vagrant/vms/*.rb, mounts parent as /vagrant
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add playbook | `ansible/playbooks/` | Target a host group, include roles, reference `group_vars/all.yaml` |
| Add role | `ansible/roles/<name>/` | tasks/main.yaml required. Optional: defaults/, vars/, handlers/, templates/ |
| Change VM resources | `vagrant/config/vm_resources.rb` | Toggle `enabled: true/false`, set CPU/memory/IPs |
| Add Vagrant VM | `vagrant/vms/<name>.rb` | Define `configure_<name>(config)`, add call in `Vagrantfile` |
| Change inventory | `ansible/inventory/` | `single-node.yaml` for cloud, `vagrant.yaml` for local |
| Proxmox VMs | `terraform/main.tf` + `terraform.tfvars` | `terraform apply` from `infra/terraform/` |

## ANSIBLE ROLE MAP

| Role | Purpose | Key Vars | Templates |
|------|---------|----------|-----------|
| `node_bootstrap` | Base packages, Python venv, kubectl, helm, Flux CLI | — | — |
| `k3s_server` | Install K3s, fetch kubeconfig | `kubernetes_vip`, `kubernetes_tls_sans` | — |
| `k8s_bootstrap` | Flux operator + Tailscale OAuth secret + flux-substitutions ConfigMap | `flux_components_path`, `.env` vars | — |
| `tailscale_agent` | Install + OAuth-authenticate Tailscale client | `tailscale_tags`, `tailscale_hostname` | — |
| `cluster_health` | Verify K8s nodes, pods, Flux, disk usage | `fail_on_issues: false` | — |
| `wazuh_agent` | Install + register Wazuh agent on host | `wazuh_manager_ip`, `wazuh_manager_port` | `wazuh-agent.conf.j2`, `wazuh-agent.service.j2` |
| `wazuh_certs` | Generate Wazuh TLS certs, create K8s secrets | `certs_dir` | — |
| `haproxy_keepalived` | HAProxy + Keepalived for K8s API HA | `kubernetes_vip` | `haproxy.cfg.j2`, `keepalived.conf.j2` (uses `.yaml` extensions) |
| `proxmox` | Create Debian/Alpine cloud-init VM templates on Proxmox | `debian_vmid`, `alpine_vmid` | — |
| `nessus` | Install Nessus, activate license, create+launch scan | `nessus_activation_code`, `scan_targets` | — |

## ROLE DEPENDENCY CHAIN

```
node_bootstrap → k3s_server → k8s_bootstrap → cluster_health
                                    ├── tailscale (creates K8s Secret)
                                    └── flux (rsyncs manifests, applies)
wazuh_certs (standalone, needs kubernetes.core)
wazuh_agent (standalone)
haproxy_keepalived (standalone, needs k3s_masters group)
proxmox (standalone)
nessus (standalone, runs on localhost)
```

## PLAYBOOK → ROLE MAPPING

| Playbook | Hosts | Roles |
|----------|-------|-------|
| `k8s-server.yaml` | k3s_masters | node_bootstrap → k3s_server |
| `k8s-bootstrap.yaml` | k3s_masters | k8s_bootstrap |
| `k8s-healthcheck.yaml` | k3s-master-1 | cluster_health |
| `tailscale-agent.yaml` | k3s_masters | tailscale_agent |
| `wazuh-agent.yaml` | all | wazuh_agent |
| `haproxy.yaml` | haproxy_nodes | haproxy_keepalived |
| `nessus.yaml` | localhost | nessus |
| `proxmox.yaml` | proxmox | proxmox |
| `generate-wazuh-certs.yaml` | localhost | wazuh_certs |

## VAGRANT VM TOPOLOGY

| VM | Box | IP | Enabled | Provisioners |
|----|-----|----|---------|-------------|
| k3s-master-1 | ubuntu/jammy64 | 192.168.222.10 | **Yes** | k8s-server → k8s-bootstrap → wazuh-agent |
| k3s-worker-{1-3} | ubuntu/jammy64 | .11-.13 | No | — |
| haproxy-{1,2} | ubuntu/jammy64 | .5, .6 | No | haproxy.yaml |
| pfsense | ksklareski/pfsense-ce | .1 | No | copies pfsense-config.xml |
| nessus | ubuntu/jammy64 | .20 | No | nessus.yaml |

Network: `192.168.222.0/24` on VirtualBox intnet `k3s-lan`. Port forward: `6443→6443` on first master.

## ANTI-PATTERNS

- **Vagrant uses `ansible_local`** — runs inside VM via `/vagrant` mount, not from host
- **No Ansible Vault** — secrets are plain files in `secrets/`, looked up at runtime
- **Proxmox password hardcoded** in `group_vars/proxmox.yaml` — should use vault
- **Wazuh NodePorts hardcoded** in `vagrant/vms/k3s_master.rb` (31514, 31515)
- **No tags on most roles** — only `k3s_server` has tags (`k3s`, `k3s-validate`)

## NOTES

- **Inventory path quirk**: `ansible.cfg` defaults to `inventory/hosts.yaml` (Proxmox multi-node), but Makefile always specifies inventory explicitly
- **Secret paths use `playbook_dir`** with relative `../../../secrets/` — fragile if playbook location changes
- **Terraform state is local** — no remote backend. `.tfstate` is gitignored
- **`flux.tf` and `ansible_control_node.tf` are commented out** — abandoned in favor of Ansible-only path
- **`run-tailscale-agent.sh`** exists as a convenience wrapper for running from WSL

## WSL + VAGRANT WORKFLOW

Running Vagrant from WSL requires special handling because VirtualBox runs on Windows.

### How it works

The Makefile auto-detects WSL via `WSL_DISTRO_NAME` env var and:
1. Uses `vagrant.exe` instead of `vagrant`
2. Sets `VAGRANT_WSL_ENABLE_WINDOWS_ACCESS=1`
3. Syncs the project from WSL ext4 to `/mnt/d/work/homelab` (DrvFs) before each Vagrant command
4. Runs `vagrant.exe` from the DrvFs copy so VirtualBox shared folders work

### Why the sync is needed

VirtualBox shared folders require host paths on a DrvFs-mounted filesystem (e.g., `/mnt/c/`, `/mnt/d/`). WSL's native ext4 filesystem (`/home/...`) is NOT DrvFs and will fail with: `The host path of the shared folder is not supported from WSL`.

### Commands (from repo root in WSL)

```bash
make master          # Sync + create k3s-master-1 with full provisioning
make master-vm       # Sync + create VM only (no provisioning)
make provision       # Sync + re-run all provisioners
make status          # Show VM status (no sync needed)
make ssh             # SSH into k3s-master-1
make halt            # Stop all VMs
make destroy         # Destroy all VMs
```

### Accessing the cluster

Port forward `6443→6443` is set up by VirtualBox. The kubeconfig server is `https://localhost:6443`.

- **From Windows** (kubectl.exe, FreeLens, etc.): works directly — `localhost` resolves to the VirtualBox host
- **From WSL**: `localhost` is WSL's own loopback, NOT Windows. Use `kubectl.exe` with a Windows path, or route through the WSL gateway IP (`ip route show default | awk '{print $3}'`)
- **Kubeconfig location**: provisioning saves to `secrets/kubeconfig` (via shared folder at `D:\work\homelab\secrets\kubeconfig`). Copy to `C:\Users\<user>\.kube\config` for default kubectl/FreeLens access. Copy from `D:\` not from WSL ext4 to avoid byte corruption.

### Key variables for ansible_local provisioners

The Vagrant provisioners pass `vagrant_run: true` via `extra_vars`. Ansible roles use this to:
- Use local `copy` instead of `synchronize` for Flux manifests (no SSH key needed)
- Skip host-side secret file lookups

### Known issues

- **Wazuh agent provisioner**: may fail on first run because Flux hasn't finished deploying the Wazuh manager. Re-run `make provision` after waiting for Flux reconciliation.
- **kubernetes.core.k8s module**: reads kubeconfig at Ansible parse time, before `become` escalation. The `k8s_bootstrap` role copies kubeconfig to `{{ bootstrap_kubeconfig_path }}` (default: `/tmp/k3s-kubeconfig.yaml`) with `0644` permissions to work around this.
