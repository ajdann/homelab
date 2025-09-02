# ------------------------------------------------------
# Global VM resource settings
# ------------------------------------------------------
VM_RESOURCES = {
  "pfsense"     => { cpus: 1, memory: 1024 },
  "nessus"      => { cpus: 2, memory: 2048 },
  "k3s-master"  => { cpus: 1, memory: 1024 },
  "k3s-worker"  => { cpus: 1, memory: 1024 },  # applies to all workers
}

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
sudo tee /etc/netplan/01-netcfg.yaml > /dev/null <<EOF
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: yes
      dhcp4-overrides:
        use-routes: false
        use-dns: false
      dhcp6: yes
      dhcp6-overrides:
        use-routes: false
        use-dns: false
    enp0s8:
      dhcp4: no
      addresses:
        - #{ip}/24
      routes:
        - to: 0.0.0.0/0
          via: 192.168.222.1
          metric: 100
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
EOF
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

    pfsense.vm.network "public_network" , auto_config: false
    pfsense.vm.network "private_network",
      ip: "192.168.222.1",
      # auto_config: false,
      virtualbox__intnet: "k3s-lan"
    pfsense.vm.network "forwarded_port", guest: 80, host: 8080
    pfsense.vm.network "forwarded_port", guest: 443, host: 8443

    pfsense.vm.provider "virtualbox" do |vb|
      vb.name   = "pfsense"
      vb.cpus   = VM_RESOURCES["pfsense"][:cpus]
      vb.memory = VM_RESOURCES["pfsense"][:memory]
    end

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
    nessus.vm.network "private_network",
      ip: "192.168.222.20",
      auto_config: false,
      virtualbox__intnet: "k3s-lan"


    nessus.vm.provider "virtualbox" do |vb|
      vb.name   = "nessus"
      vb.cpus   = VM_RESOURCES["nessus"][:cpus]
      vb.memory = VM_RESOURCES["nessus"][:memory]
    end
    # configure_netplan(nessus, "192.168.222.20")

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
    master.vm.network "private_network",
      ip: "192.168.222.10",
      virtualbox__intnet: "k3s-lan"

    master.vm.provider "virtualbox" do |vb|
      vb.name   = "k3s-master"
      vb.cpus   = VM_RESOURCES["k3s-master"][:cpus]
      vb.memory = VM_RESOURCES["k3s-master"][:memory]
    end

    # configure_netplan(master, "192.168.222.10")
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
      worker.vm.network "private_network",
        ip: "192.168.222.1#{i}",
        virtualbox__intnet: "k3s-lan"

      worker.vm.provider "virtualbox" do |vb|
        vb.name   = "k3s-worker#{i}"
        vb.cpus   = VM_RESOURCES["k3s-worker"][:cpus]
        vb.memory = VM_RESOURCES["k3s-worker"][:memory]
      end

      # configure_netplan(worker, "192.168.222.1#{i}")
      worker.vm.provision "shell", inline: <<-SHELL
        sudo apt update
        sudo apt install -y ansible
      SHELL
    end
  end
end
