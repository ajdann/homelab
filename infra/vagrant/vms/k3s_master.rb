def configure_k3s_master(config)
  return unless VM_RESOURCES["k3s-master"][:enabled]
  
  # Check conditions for port forwarding:
  # 1. Only one k3s-master defined
  # 2. No haproxy nodes enabled
  single_master = VM_RESOURCES["k3s-master"][:ips].length == 1
  no_haproxy = !VM_RESOURCES["haproxy"][:enabled]
  should_expose_port = single_master && no_haproxy
  
  VM_RESOURCES["k3s-master"][:ips].each_with_index do |ip, i|
    config.vm.define "k3s-master-#{i+1}" do |master|
      master.vm.box = "ubuntu/jammy64"
      master.vm.hostname = "k3s-master-#{i+1}"
      master.disksize.size = "60GB"

      # Only forward port 6443 if single master and no haproxy
      if should_expose_port && i == 0
        master.vm.network "forwarded_port", guest: 6443, host: 6443
      end

      master.vm.network "private_network",
        ip: ip,
        virtualbox__intnet: NETWORK_CONFIG[:virtualbox_intnet]

      master.vm.provider "virtualbox" do |vb|
        vb.name   = "k3s-master-#{i+1}"
        vb.cpus   = VM_RESOURCES["k3s-master"][:cpus]
        vb.memory = VM_RESOURCES["k3s-master"][:memory]
      end

      # configure_netplan(master, ip)
      master.vm.provision "shell", inline: <<-SHELL
        # sudo apt update
        # sudo apt install -y software-properties-common python3 python3-pip python3-venv
        # sudo add-apt-repository --yes --update ppa:ansible/ansible
        # sudo apt install -y ansible
        # sudo pip3 install -r /vagrant/ansible/requirements.txt
        # sudo ansible-galaxy install -r /vagrant/ansible/requirements.yaml
      SHELL

      master.vm.provision "ansible_local" do |ansible|
        ansible.playbook = "/vagrant/ansible/playbooks/k3s-ha-vagrant.yaml"
        ansible.install = true
        ansible.verbose = true  # Enable verbose output for debugging
        ansible.pip_args = "-r /vagrant/ansible/requirements.txt"
        # ansible.groups = {
        #   "k3s_masters" => ["k3s-master-#{i+1}"]
        # }
        # ansible.host_vars = {
        #   "k3s-master-#{i+1}" => {"ansible_connection" => "local"}
        # }
        # ansible.extra_vars = {
        #   kubernetes_vip: VM_RESOURCES["k3s-master"][:ips][0]  # Use master IP as API endpoint
        # }
      end

      # master.vm.provision "ansible_local" do |ansible|
      #   ansible.playbook = "/vagrant/ansible/playbooks/k8s_bootstrap.yaml"
      #   ansible.groups = {
      #     "k3s_masters" => ["k3s-master-#{i+1}"]
      #   }
      #   ansible.host_vars = {
      #     "k3s-master-#{i+1}" => {"ansible_connection" => "local"}
      #   }
      #   ansible.verbose = true  # Enable verbose output for debugging
      #   ansible.extra_vars = {
      #     kubernetes_vip: VM_RESOURCES["k3s-master"][:ips][0]  # Use master IP as API endpoint
      #   }
      # end
    end
  end
end