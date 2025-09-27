def configure_pfsense(config)
  return unless VM_RESOURCES["pfsense"][:enabled]
  
  config.vm.define "pfsense" do |pfsense|
    pfsense.vm.guest = :freebsd
    pfsense.vm.box = "ksklareski/pfsense-ce"
    pfsense.vm.hostname = "pfsense"
    pfsense.vm.synced_folder ".", "/vagrant", disabled: true
    pfsense.ssh.shell = 'sh'
    pfsense.ssh.insert_key = false

    pfsense.vm.network "public_network" , auto_config: false
    pfsense.vm.network "private_network",
      ip: VM_RESOURCES["pfsense"][:ip],
      virtualbox__intnet: NETWORK_CONFIG[:virtualbox_intnet]
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
end