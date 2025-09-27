def configure_k3s_workers(config)
  return unless VM_RESOURCES["k3s-worker"][:enabled]
  
  (1..1).each do |i|
    # Generate IP by appending the worker number to the base IP
    worker_ip = VM_RESOURCES["k3s-worker"][:ip_base] + i.to_s
    
    config.vm.define "k3s-worker#{i}" do |worker|
      worker.vm.box = "ubuntu/jammy64"
      worker.vm.hostname = "k3s-worker#{i}"
      worker.vm.network "private_network",
        ip: worker_ip,
        virtualbox__intnet: NETWORK_CONFIG[:virtualbox_intnet]

      worker.vm.provider "virtualbox" do |vb|
        vb.name   = "k3s-worker#{i}"
        vb.cpus   = VM_RESOURCES["k3s-worker"][:cpus]
        vb.memory = VM_RESOURCES["k3s-worker"][:memory]
      end

      # configure_netplan(worker, worker_ip)
      worker.vm.provision "shell", inline: <<-SHELL
        sudo apt update
        sudo apt install -y ansible
      SHELL
    end
  end
end