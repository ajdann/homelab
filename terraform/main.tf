terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc04"
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://192.168.1.157:8006/api2/json"
  pm_user         = "root@pam"
  pm_password     = file("../secrets/proxmox_api_password")
  pm_tls_insecure = "true"
}


resource "proxmox_vm_qemu" "k3s_master" {
  # VM General settings
  name        = "k3s-master"
  target_node = var.proxmox_node
  vmid        = 100
  onboot      = true

  # Cloning settings
  clone       = var.template_name
  full_clone  = true

  # System settings
  agent  = 1 # Enable QEMU Guest Agent
  memory = 4096
  scsihw = "virtio-scsi-pci"
  boot   = "order=scsi0"

  ipconfig0 = "ip=192.168.1.200/24,gw=192.168.1.1" # Set your desired IP and gateway

  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
  }

# disk {
#   slot = "scsi0"
#   size = "32G"
#   type = "disk"
#   storage = "local-lvm"
# }

disks {
  scsi {
    scsi0 {
      disk {
        size    = "32G"
        storage = "local-lvm"
      }
    }
  }
  ide {
    ide0 {
      cloudinit {
        storage = "local-lvm"
      }
    }
  }
}
  # Network settings
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Cloud-Init settings
  ciuser   = file("../secrets/vm_user")
  cipassword = file("../secrets/vm_password")
  ciupgrade = true
  sshkeys  = file("../secrets/vm_ssh_pub_key")

  serial {
    id = 0
    type = "socket"
  }

  vga {
    type = "serial0"
  }

}
