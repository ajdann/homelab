# ------------------------------------------------------
# Global VM resource settings
# ------------------------------------------------------
VM_RESOURCES = {
  "pfsense"     => { 
    cpus: 1, 
    memory: 1024, 
    enabled: false,
    ip: "192.168.222.1"
  },
  "nessus"      => { 
    cpus: 1, 
    memory: 1024, 
    enabled: false,
    ip: "192.168.222.20"
  },
  "haproxy"     => { 
    cpus: 1, 
    memory: 1024, 
    enabled: true,
    ips: ["192.168.222.5", "192.168.222.6"]  # Array for multiple HAProxy instances
  },
  "k3s-master"  => { 
    cpus: 4, 
    memory: 9216, 
    enabled: true,
    ip: "192.168.222.10"
  },
  "k3s-worker"  => { 
    cpus: 1, 
    memory: 1024, 
    enabled: false,
    ips: ["192.168.222.11", "192.168.222.12", "192.168.222.13"]  # Array for multiple worker instances
  },
}

# Network configuration
NETWORK_CONFIG = {
  subnet: "192.168.222.0/24",
  gateway: "192.168.222.1",
  dns: ["8.8.8.8", "1.1.1.1"],
  virtualbox_intnet: "k3s-lan"
}
