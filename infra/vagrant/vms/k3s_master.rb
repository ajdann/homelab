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

      # Port forwarding for accessing K3s API via localhost
      if i == 0  # Only for first master
        master.vm.network "forwarded_port", guest: 6443, host: 6443
      end
      
      # Use private network (internal VirtualBox network)
      master.vm.network "private_network",
        ip: ip,
        virtualbox__intnet: NETWORK_CONFIG[:virtualbox_intnet]

      # Public network configuration (commented out)
      # master.vm.network "public_network", 
      #   ip: ip,  # Uses the IP from vm_resources.rb but you need to change it to your network range
      #   bridge: "auto"  # Automatically select the network adapter
      

      master.vm.provider "virtualbox" do |vb|
        vb.name   = "k3s-master-#{i+1}"
        vb.cpus   = VM_RESOURCES["k3s-master"][:cpus]
        vb.memory = VM_RESOURCES["k3s-master"][:memory]
      end

      # configure_netplan(master, ip)
      master.vm.provision "shell", inline: <<-SHELL
      SHELL

      master.vm.provision "ansible_local" do |ansible|
        ansible.playbook = "/vagrant/infra/ansible/playbooks/k3s-ha-vagrant.yaml"
        ansible.install_mode = "pip"
        ansible.pip_args = "-r /vagrant/infra/ansible/requirements.txt"
        # ansible.verbose = true  # Enable verbose output for debugging
        ansible.groups = {
          "k3s_masters" => ["k3s-master-#{i+1}"]
        }
        ansible.extra_vars = {
          kubernetes_vip: VM_RESOURCES["k3s-master"][:ips][0],  # Use master IP as API endpoint
          kubernetes_tls_sans: [
            VM_RESOURCES["k3s-master"][:ips][0],  # VM IP address
            "localhost",                          # For port forwarding access
            "127.0.0.1"                          # For port forwarding access
          ].join(","),  # K3s expects comma-separated TLS SANs
          kubeconfig_server: "localhost"        # Use localhost for port forwarding
        }
      end

      master.vm.provision "ansible_local" do |ansible|
        ansible.playbook = "/vagrant/infra/ansible/playbooks/k8s-bootstrap.yaml"
        ansible.verbose = false  
        ansible.install_mode = "pip"
        ansible.galaxy_role_file = "/vagrant/infra/ansible/requirements.yaml"
        ansible.pip_args = "-r /vagrant/infra/ansible/requirements.txt"
        ansible.groups = {
          "k3s_masters" => ["k3s-master-#{i+1}"]
        }
        ansible.extra_vars = {
          kubernetes_vip: VM_RESOURCES["k3s-master"][:ips][0],  # Use master IP as API endpoint
          kubernetes_tls_sans: [
            VM_RESOURCES["k3s-master"][:ips][0],  # VM IP address
            "localhost",                          # For port forwarding access
            "127.0.0.1"                          # For port forwarding access
          ].join(","),  # K3s expects comma-separated TLS SANs
          kubeconfig_server: "localhost"        # Use localhost for port forwarding
        }
      end
    end
  end
end