# Weird hack to bypass some dhcp interface issues.
class VagrantPlugins::ProviderVirtualBox::Action::Network
  def dhcp_server_matches_config?(dhcp_server, config)
    true
  end
end

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