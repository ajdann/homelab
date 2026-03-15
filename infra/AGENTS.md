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
│   └── vms/              # 5 VM definitions (Ruby): pfsense, nessus, haproxy, k3s_master, k3s_workers
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
| `wazuh-agent` | Install + register Wazuh agent on host | `wazuh_manager_ip`, `wazuh_manager_port` | `wazuh-agent.conf.j2`, `wazuh-agent.service.j2` |
| `wazuh_certs` | Generate Wazuh TLS certs, create K8s secrets | `certs_dir` | — |
| `haproxy_keepalived` | HAProxy + Keepalived for K8s API HA | `kubernetes_vip` | `haproxy.cfg.j2`, `keepalived.conf.j2` |
| `proxmox` | Create Debian/Alpine cloud-init VM templates on Proxmox | `debian_vmid`, `alpine_vmid` | — |
| `nessus` | Install Nessus, activate license, create+launch scan | `nessus_activation_code`, `scan_targets` | — |

## ROLE DEPENDENCY CHAIN

```
node_bootstrap → k3s_server → k8s_bootstrap → cluster_health
                                    ├── tailscale (creates K8s Secret)
                                    └── flux (rsyncs manifests, applies)
wazuh_certs (standalone, needs kubernetes.core)
wazuh-agent (standalone)
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
| `wazuh-agent.yaml` | all | wazuh-agent |
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
- **HAProxy playbook path differs** — uses `/vagrant/ansible/playbooks/` (not `/vagrant/infra/ansible/playbooks/`)
- **No tags on most roles** — only `k3s_server` has tags (`k3s`, `k3s-validate`)

## NOTES

- **Inventory path quirk**: `ansible.cfg` defaults to `inventory/hosts.yaml` (Proxmox multi-node), but Makefile always specifies inventory explicitly
- **Secret paths use `playbook_dir`** with relative `../../../secrets/` — fragile if playbook location changes
- **Terraform state is local** — no remote backend. `.tfstate` is gitignored
- **`flux.tf` and `ansible_control_node.tf` are commented out** — abandoned in favor of Ansible-only path
- **`run-tailscale-agent.sh`** exists as a convenience wrapper for running from WSL
