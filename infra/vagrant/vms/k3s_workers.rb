def configure_k3s_workers(config)
  return unless VM_RESOURCES["k3s-worker"][:enabled]
  
  VM_RESOURCES["k3s-worker"][:ips].each_with_index do |ip, i|
    config.vm.define "k3s-worker#{i+1}" do |worker|
      worker.vm.box = "ubuntu/jammy64"
      worker.vm.hostname = "k3s-worker#{i+1}"
      worker.vm.network "private_network",
        ip: ip,
        virtualbox__intnet: NETWORK_CONFIG[:virtualbox_intnet]

      worker.vm.provider "virtualbox" do |vb|
        vb.name   = "k3s-worker#{i+1}"
        vb.cpus   = VM_RESOURCES["k3s-worker"][:cpus]
        vb.memory = VM_RESOURCES["k3s-worker"][:memory]
      end

      # configure_netplan(worker, ip)
      worker.vm.provision "shell", inline: <<-SHELL
        sudo apt update
        sudo apt install -y ansible
      SHELL
    end
  end
end