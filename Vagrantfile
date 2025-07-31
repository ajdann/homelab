Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "k3s-master"
  config.vm.network "private_network", ip: "192.168.56.10"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  config.vm.boot_timeout = 600
  end

  config.vm.provision "shell", inline: <<-SHELL
    sudo apt update
    sudo apt install -y ansible
  SHELL
end