# ─────────────────────────────────────────────────────────
# Homelab Infrastructure
# ─────────────────────────────────────────────────────────
#
#   make              Show all available commands
#   make master       Start k3s-master-1 with full provisioning
#   make up           Start all enabled VMs
#   make bootstrap    Bootstrap cloud VM (K3s + Flux)
#
#   VM targeting:     make halt VM=k3s-master-1
#   VM config:        infra/vagrant/config/vm_resources.rb
#
# ─────────────────────────────────────────────────────────

.DEFAULT_GOAL := help

# ── Configuration ──────────────────────────────────────

VAGRANT_DIR       := infra
PLAYBOOK_DIR      := infra/ansible/playbooks
INVENTORY_CLOUD   := infra/ansible/inventory/single-node.yaml
INVENTORY_VAGRANT := infra/ansible/inventory/vagrant.yaml
ANSIBLE_FLAGS     := -v

# Auto-detect WSL: sync project to Windows filesystem, use vagrant.exe
# VirtualBox shared folders require a DrvFs path (not WSL's ext4).
ifdef WSL_DISTRO_NAME
  VAGRANT     := vagrant.exe
  VAGRANT_CWD := /mnt/d/work/homelab/infra
  RSYNC_FLAGS := -rlpt --no-group --omit-dir-times --delete \
                 --exclude='.git' --exclude='.vagrant' --exclude='.trunk'
  export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS := 1
else
  VAGRANT     := vagrant
  VAGRANT_CWD := infra
endif

# ── WSL: Sync to Windows filesystem ──────────────────

.PHONY: sync

sync:                                                      ## (WSL) Sync project to /mnt/d/work/homelab
ifdef WSL_DISTRO_NAME
	@rsync $(RSYNC_FLAGS) . /mnt/d/work/homelab/
else
	@echo "Not running in WSL — nothing to sync."
endif

# ── Vagrant: Quick Start ──────────────────────────────

.PHONY: master master-vm up

master: sync                                               ## Start k3s-master-1 (full provisioning: K3s + Flux + Wazuh)
	cd $(VAGRANT_CWD) && $(VAGRANT) up k3s-master-1

master-vm: sync                                            ## Start k3s-master-1 (VM only, no provisioning)
	cd $(VAGRANT_CWD) && $(VAGRANT) up k3s-master-1 --no-provision

up: sync                                                   ## Start all enabled VMs (see vm_resources.rb)
	cd $(VAGRANT_CWD) && $(VAGRANT) up

# ── Vagrant: VM Management ────────────────────────────

.PHONY: status ssh halt destroy provision

status:                                                    ## Show Vagrant VM status
	cd $(VAGRANT_CWD) && $(VAGRANT) status

ssh:                                                       ## SSH into a VM — make ssh [VM=k3s-master-1]
	cd $(VAGRANT_CWD) && $(VAGRANT) ssh $(or $(VM),k3s-master-1)

halt:                                                      ## Stop VM(s) — make halt [VM=name] or halt all
ifdef VM
	cd $(VAGRANT_CWD) && $(VAGRANT) halt $(VM)
else
	cd $(VAGRANT_CWD) && $(VAGRANT) halt
endif

destroy:                                                   ## Destroy VM(s) — make destroy [VM=name] or destroy all
ifdef VM
	cd $(VAGRANT_CWD) && $(VAGRANT) destroy -f $(VM)
else
	cd $(VAGRANT_CWD) && $(VAGRANT) destroy -f
endif

provision: sync                                            ## Re-run provisioners — make provision [VM=k3s-master-1]
	cd $(VAGRANT_CWD) && $(VAGRANT) provision $(or $(VM),k3s-master-1)

# ── Vagrant: Host-Side Ansible ────────────────────────
# These run Ansible from YOUR machine against the Vagrant VM.
# The VM must already be running (make master-vm first).

.PHONY: tailscale-vagrant healthcheck-vagrant

tailscale-vagrant:                                         ## Run Tailscale agent playbook against Vagrant VM
	ansible-playbook $(ANSIBLE_FLAGS) -i $(INVENTORY_VAGRANT) $(PLAYBOOK_DIR)/tailscale-agent.yaml

healthcheck-vagrant:                                       ## Run healthcheck against Vagrant VM
	ansible-playbook $(ANSIBLE_FLAGS) -i $(INVENTORY_VAGRANT) $(PLAYBOOK_DIR)/k8s-healthcheck.yaml

# ── Cloud VM ──────────────────────────────────────────
# Target: remote VM defined in inventory/single-node.yaml.
# Requires secrets/ dir (vm_user, vm_ssh_private_key, .env).

.PHONY: bootstrap healthcheck

bootstrap:                                                 ## Bootstrap cloud VM — K3s install, then Flux + Tailscale
	ansible-playbook $(ANSIBLE_FLAGS) -i $(INVENTORY_CLOUD) $(PLAYBOOK_DIR)/k8s-server.yaml
	ansible-playbook $(ANSIBLE_FLAGS) -i $(INVENTORY_CLOUD) $(PLAYBOOK_DIR)/k8s-bootstrap.yaml

healthcheck:                                               ## Run healthcheck on cloud VM
	ansible-playbook $(ANSIBLE_FLAGS) -i $(INVENTORY_CLOUD) $(PLAYBOOK_DIR)/k8s-healthcheck.yaml

# ── Help ──────────────────────────────────────────────

.PHONY: help

help:
	@echo ""
	@echo "  \033[1mHomelab Infrastructure\033[0m"
	@echo ""
	@echo "  \033[36mVAGRANT \342\200\224 Quick Start\033[0m"
	@echo "    make master                Start k3s-master-1 (full provisioning)"
	@echo "    make master-vm             Start k3s-master-1 (VM only, skip provisioning)"
	@echo "    make up                    Start all enabled VMs"
	@echo ""
	@echo "  \033[36mVAGRANT \342\200\224 VM Management\033[0m"
	@echo "    make status                Show VM status"
	@echo "    make ssh [VM=name]         SSH into VM (default: k3s-master-1)"
	@echo "    make provision [VM=name]   Re-run provisioners (default: k3s-master-1)"
	@echo "    make halt [VM=name]        Stop VM(s) \342\200\224 omit VM to stop all"
	@echo "    make destroy [VM=name]     Destroy VM(s) \342\200\224 omit VM to destroy all"
	@echo ""
	@echo "  \033[36mVAGRANT \342\200\224 Ansible from Host\033[0m  (VM must be running)"
	@echo "    make tailscale-vagrant     Run Tailscale agent playbook"
	@echo "    make healthcheck-vagrant   Run healthcheck against Vagrant VM"
	@echo ""
	@echo "  \033[36mCLOUD VM\033[0m  (requires secrets/ dir)"
	@echo "    make bootstrap             Bootstrap cloud VM (K3s + Flux)"
	@echo "    make healthcheck           Run healthcheck on cloud VM"
	@echo ""
	@echo "  \033[36mWSL\033[0m"
	@echo "    make sync                  Sync project to /mnt/d/work/homelab (auto on up/master)"
	@echo ""
	@echo "  \033[2mVM names: k3s-master-1 | k3s-worker{1-3} | haproxy{1,2} | pfsense | nessus\033[0m"
	@echo "  \033[2mEnable/disable VMs:  infra/vagrant/config/vm_resources.rb\033[0m"
	@echo ""
