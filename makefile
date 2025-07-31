.PHONY: up ssh ansible kubeconfig destroy

up:
	vagrant up

ssh:
	vagrant ssh

ansible:
	vagrant ssh -c "cd /vagrant && ansible-playbook -i ansible/inventory/hosts.yaml ansible/playbooks/bootstrap.yaml"
	vagrant ssh -c "cd /vagrant && ansible-playbook -i ansible/inventory/hosts.yaml ansible/playbooks/k3s-single-node.yaml"
	vagrant ssh -c "cd /vagrant && ansible-playbook -i ansible/inventory/hosts.yaml ansible/playbooks/k8s-secrets.yaml"

kubeconfig:
	vagrant ssh -c "sudo cat /etc/rancher/k3s/k3s.yaml" > kubeconfig
	sed -i '' -e 's/127.0.0.1/192.168.56.10/' kubeconfig
	@echo "Run: export KUBECONFIG=$$PWD/kubeconfig"

destroy:
	vagrant destroy -f
