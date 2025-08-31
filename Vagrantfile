# Weird hack to bypass some dhcp interface issues.
class VagrantPlugins::ProviderVirtualBox::Action::Network
  def dhcp_server_matches_config?(dhcp_server, config)
    true
  end
end

Vagrant.configure("2") do |config|

  ######################################################
  # Netplan Template Function
  ######################################################
def configure_netplan(vm, ip)
  vm.vm.provision "shell", inline: <<-SHELL
    sudo bash -c 'cat > /etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  ethernets:
    enp0s3:  # Vagrant NAT interface - keep for management
      dhcp4: yes
      dhcp4-overrides:
        use-routes: false  # Prevent default route through Vagrant
        use-dns: false     # Prevent DNS override
    enp0s8:  # pfSense LAN interface
      dhcp4: no
      addresses:
        - #{ip}/24
      routes:
        - to: 0.0.0.0/0
          via: 192.168.222.1
          metric: 100      # Lower metric = higher priority
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
EOF'
    sudo chmod 600 /etc/netplan/01-netcfg.yaml
    sudo chmod 600 /etc/netplan/50-vagrant.yaml 
    sudo netplan apply
    sudo systemctl restart systemd-resolved
  SHELL
end

  ######################################################
  # pfSense Firewall
  ######################################################
  config.vm.define "pfsense" do |pfsense|
    pfsense.vm.guest = :freebsd
    pfsense.vm.box = "ksklareski/pfsense-ce"
    pfsense.vm.hostname = "pfsense"
    pfsense.vm.synced_folder ".", "/vagrant", disabled: true
    pfsense.ssh.shell = 'sh'
    pfsense.ssh.insert_key = false

    # WAN interface (bridged for internet access)
    pfsense.vm.network "public_network", bridge: "en0: Wi-Fi (Wireless)", auto_config: false

    # LAN interface (Private Network for K3s cluster)
    pfsense.vm.network "private_network", ip: "192.168.222.1", auto_config: false

    # Forward pfSense WebUI (port 80 -> host 8080, 443 -> host 8443)
    pfsense.vm.network "forwarded_port", guest: 80, host: 8080
    pfsense.vm.network "forwarded_port", guest: 443, host: 8443

    pfsense.vm.provider "virtualbox" do |vb|
      vb.name = "pfsense"
      vb.memory = 1024
      vb.cpus = 1
    end

    # Push prebuilt config.xml
    pfsense.vm.provision "file", source: "./pfsense-config.xml", destination: "/tmp/config.xml"
    pfsense.vm.provision "shell",
      inline: <<-SHELL
        mv /tmp/config.xml /cf/conf/config.xml
        rm -f /tmp/config.cache
      SHELL
  end

  ######################################################
  # Nessus VM
  ######################################################
  config.vm.define "nessus" do |nessus|
    nessus.vm.box = "ubuntu/jammy64"
    nessus.vm.hostname = "nessus"
    nessus.vm.synced_folder ".", "/vagrant", disabled: false
    # Attach to pfSense LAN
    # nessus.vm.network "private_network", ip: "192.168.222.20"
    nessus.vm.network "forwarded_port", guest: 8834, host: 8834

    nessus.vm.provider "virtualbox" do |vb|
      vb.name = "nessus"
      vb.cpus = 2
      vb.memory = 2048
    end
    # Apply netplan with correct static IP
    # Disabled for now as it doesnt work..
    # configure_netplan(nessus, "192.168.222.20")


    # Provision: install Ansible and dependencies
    nessus.vm.provision "shell", inline: <<-SHELL
      sudo apt update
      sudo apt install -y ansible python3-requests wget gnupg2 lsb-release
    SHELL
    
    # Run the playbook
    nessus.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "/vagrant/ansible/playbooks/nessus.yaml"
    end

  end
  
  ######################################################
  # K3s Master Node
  ######################################################
  config.vm.define "k3s-master" do |master|
    master.vm.box = "ubuntu/jammy64"
    master.vm.hostname = "k3s-master"

    # Attach to pfSense LAN
    master.vm.network "private_network", ip: "192.168.222.10"

    master.vm.provider "virtualbox" do |vb|
      vb.name = "k3s-master"
      vb.cpus = 1
      vb.memory = 1024
    end

    # Apply netplan with correct static IP
    configure_netplan(master, "192.168.222.10")

    master.vm.provision "shell", inline: <<-SHELL
      sudo apt update
      sudo apt install -y ansible
      ping -c 3 8.8.8.8
      ping -c 3 archive.ubuntu.com
    SHELL
  end

  ######################################################
  # K3s Workers
  ######################################################
  (1..1).each do |i|
    config.vm.define "k3s-worker#{i}" do |worker|
      worker.vm.box = "ubuntu/jammy64"
      worker.vm.hostname = "k3s-worker#{i}"

      # Attach to pfSense LAN
      worker.vm.network "private_network", ip: "192.168.222.1#{i}"

      worker.vm.provider "virtualbox" do |vb|
        vb.name = "k3s-worker#{i}"
        vb.cpus = 1
        vb.memory = 1024
      end

      # Apply netplan with correct static IP
      configure_netplan(worker, "192.168.222.1#{i}")

      worker.vm.provision "shell", inline: <<-SHELL
        sudo apt update
        sudo apt install -y ansible
      SHELL
    end
  end
end


