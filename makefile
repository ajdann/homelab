.PHONY: up bootstrap vagrant-up healthcheck vagrant-up-tailscale vagrant-full tailscale-vagrant

up: vagrant-up

# Bring up all enabled Vagrant VMs (Vagrantfile lives in infra/)
vagrant-up:
	cd infra && vagrant up

# Bring up only k3s-master-1 with no provision (for testing Tailscale only)
vagrant-up-tailscale:
	cd infra && vagrant up k3s-master-1 --no-provision

# Run only the Tailscale agent playbook against the Vagrant VM (VM must be up)
tailscale-vagrant:
	ansible-playbook -v -i infra/ansible/inventory/vagrant.yaml infra/ansible/playbooks/tailscale-agent.yaml

# Full setup: bring up k3s-master-1 and run all provisioners (k8s-server, k8s-bootstrap, wazuh-agent)
vagrant-full:
	cd infra && vagrant up k3s-master-1

# Cloud VM: bootstrap (K3s + Flux, etc.)
bootstrap:
	ansible-playbook -v -i infra/ansible/inventory/single-node.yaml infra/ansible/playbooks/k8s-server.yaml
	ansible-playbook -v -i infra/ansible/inventory/single-node.yaml infra/ansible/playbooks/k8s-bootstrap.yaml

healthcheck:
	ansible-playbook -v -i infra/ansible/inventory/single-node.yaml infra/ansible/playbooks/k8s-healthcheck.yaml
