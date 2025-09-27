def configure_haproxy(config)
  return unless VM_RESOURCES["haproxy"][:enabled]
  
  VM_RESOURCES["haproxy"][:ips].each_with_index do |ip, i|
    config.vm.define "haproxy#{i+1}" do |haproxy|
      haproxy.vm.box = "ubuntu/jammy64"
      haproxy.vm.hostname = "haproxy#{i+1}"
      haproxy.vm.network "private_network",
        ip: ip,
        virtualbox__intnet: NETWORK_CONFIG[:virtualbox_intnet]

      haproxy.vm.provider "virtualbox" do |vb|
        vb.name   = "haproxy#{i+1}"
        vb.cpus   = VM_RESOURCES["haproxy"][:cpus]
        vb.memory = VM_RESOURCES["haproxy"][:memory]
      end

      # configure_netplan(haproxy, ip)
      haproxy.vm.provision "shell", inline: <<-SHELL
        sudo apt update
        sudo apt install -y ansible haproxy keepalived
      SHELL

      haproxy.vm.provision "ansible_local" do |ansible|
        ansible.playbook = "/vagrant/ansible/playbooks/haproxy.yaml"
        ansible.inventory_path = "/vagrant/ansible/inventory/hosts.yaml"
        ansible.limit = "haproxy#{i+1}"
      end
    end
  end
end