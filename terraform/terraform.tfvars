vms = {
  "k3s-master" = {
    name      = "k3s-master"
    vmid      = 100
    memory    = 2048
    cores     = 2
    sockets   = 1
    ipconfig0 = "ip=192.168.1.200/24,gw=192.168.1.1"
    disk_size = "32G"
  }
}
