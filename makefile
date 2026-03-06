.PHONY: up bootstrap vagrant-up healthcheck

up: vagrant-up

vagrant-up:
	vagrant up


bootstrap:
# 	ansible-playbook -v -i infra/ansible/inventory/single-node.yaml infra/ansible/playbooks/k8s-server.yaml
	ansible-playbook -v -i infra/ansible/inventory/single-node.yaml infra/ansible/playbooks/k8s-bootstrap.yaml

healthcheck:
	ansible-playbook -v -i infra/ansible/inventory/single-node.yaml infra/ansible/playbooks/k8s-healthcheck.yaml

