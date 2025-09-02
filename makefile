.PHONY: up ssh bootstrap kubeconfig destroy

up:
	vagrant up

ssh:
	vagrant ssh

bootstrap:
	vagrant ssh -c "echo 'test'"
	vagrant ssh -c "cd /vagrant && ansible-playbook -i ansible/inventory/hosts.yaml ansible/playbooks/bootstrap.yaml"
	vagrant ssh -c "cd /vagrant && ansible-playbook -i ansible/inventory/hosts.yaml ansible/playbooks/k3s-single-node.yaml"
	vagrant ssh -c "cd /vagrant && ansible-playbook -i ansible/inventory/hosts.yaml ansible/playbooks/k8s-tailscale.yaml"
	vagrant ssh -c "cd /vagrant && ansible-playbook -i ansible/inventory/hosts.yaml ansible/playbooks/bootstrap-k8s.yaml"
	vagrant ssh -c "cd /vagrant/ansible && ansible-playbook -i inventory/hosts.yaml playbooks/wazuh-agent.yaml"
# 	vagrant ssh -c "cd /vagrant && ansible-playbook -i ansible/inventory/hosts.yaml ansible/playbooks/generate-wazuh-certs.yaml"

kubeconfig:
	vagrant ssh -c "sudo cat /etc/rancher/k3s/k3s.yaml | sed 's/127.0.0.1/192.168.56.10/' > /vagrant/kubeconfig"

destroy:
	vagrant destroy -f
