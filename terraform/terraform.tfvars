vms = {
  "k3s-master-1" = {
    name      = "k3s-master-1"
    vmid      = 100
    memory    = 2048
    cores     = 2
    sockets   = 1
    ipconfig0 = "ip=192.168.1.200/24,gw=192.168.1.1"
    disk_size = "32G"
    template  = "debian12-cloudinit"
    tags      = "k3s-master"
  },
  "k3s-master-2" = {
    name      = "k3s-master-2"
    vmid      = 101
    memory    = 2048
    cores     = 2
    sockets   = 1
    ipconfig0 = "ip=192.168.1.201/24,gw=192.168.1.1"
    disk_size = "32G"
    template  = "debian12-cloudinit"
    tags      = "k3s-master"

  },
  "k3s-master-3" = {
    name      = "k3s-master-3"
    vmid      = 102
    memory    = 2048
    cores     = 2
    sockets   = 1
    ipconfig0 = "ip=192.168.1.202/24,gw=192.168.1.1"
    disk_size = "32G"
    template  = "debian12-cloudinit"
    tags      = "k3s-master"

  },
  "haproxy-1" = {
    name      = "haproxy-1"
    vmid      = 103
    memory    = 2048
    cores     = 1
    sockets   = 1
    ipconfig0 = "ip=192.168.1.203/24,gw=192.168.1.1"
    disk_size = "32G"
    template  = "debian12-cloudinit"
    tags      = "haproxy"

  },
  "haproxy-2" = {
    name      = "haproxy-2"
    vmid      = 104
    memory    = 2048
    balloon   = 1024
    cores     = 1
    sockets   = 1
    ipconfig0 = "ip=192.168.1.204/24,gw=192.168.1.1"
    disk_size = "32G"
    template  = "debian12-cloudinit"
    tags      = "haproxy"
  }
}
