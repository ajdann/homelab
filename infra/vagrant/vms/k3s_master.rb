def configure_k3s_master(config)
  return unless VM_RESOURCES["k3s-master"][:enabled]
  
  config.vm.define "k3s-master" do |master|
    master.vm.box = "ubuntu/jammy64"
    master.vm.hostname = "k3s-master"
    master.disksize.size = "60GB"

    master.vm.network "forwarded_port", guest: 6443, host: 6443
    master.vm.network "private_network",
      ip: VM_RESOURCES["k3s-master"][:ip],
      virtualbox__intnet: NETWORK_CONFIG[:virtualbox_intnet]

    master.vm.provider "virtualbox" do |vb|
      vb.name   = "k3s-master"
      vb.cpus   = VM_RESOURCES["k3s-master"][:cpus]
      vb.memory = VM_RESOURCES["k3s-master"][:memory]
    end

    # configure_netplan(master, VM_RESOURCES["k3s-master"][:ip])
    master.vm.provision "shell", inline: <<-SHELL
      sudo apt update
      sudo apt install software-properties-common -y 
      sudo add-apt-repository --yes --update ppa:ansible/ansible
      sudo apt install -y ansible
      sudo ansible-galaxy collection install kubernetes.core --force
      ansible-galaxy collection install kubernetes.core --force
    SHELL

    master.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "/vagrant/ansible/playbooks/k3s-ha.yaml"
      ansible.inventory_path = "/vagrant/ansible/inventory/hosts.yaml"
      ansible.limit = "localhost"
    end

    master.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "/vagrant/ansible/playbooks/k8s_bootstrap.yaml"
      ansible.inventory_path = "/vagrant/ansible/inventory/hosts.yaml"
      ansible.limit = "localhost"
    end
  end
end