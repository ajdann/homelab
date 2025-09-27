def configure_nessus(config)
  return unless VM_RESOURCES["nessus"][:enabled]
  
  config.vm.define "nessus" do |nessus|
    nessus.vm.box = "ubuntu/jammy64"
    nessus.vm.hostname = "nessus"
    nessus.vm.synced_folder ".", "/vagrant", disabled: false
    nessus.vm.network "private_network",
      ip: VM_RESOURCES["nessus"][:ip],
      auto_config: false,
      virtualbox__intnet: NETWORK_CONFIG[:virtualbox_intnet]

    nessus.vm.provider "virtualbox" do |vb|
      vb.name   = "nessus"
      vb.cpus   = VM_RESOURCES["nessus"][:cpus]
      vb.memory = VM_RESOURCES["nessus"][:memory]
    end
    
    # configure_netplan(nessus, VM_RESOURCES["nessus"][:ip])

    nessus.vm.provision "shell", inline: <<-SHELL
      sudo apt update
      sudo apt install -y ansible python3-requests wget gnupg2 lsb-release
    SHELL

    nessus.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "/vagrant/ansible/playbooks/nessus.yaml"
    end
  end
end