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
  pm_password     = "12345678"
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "k3s_master" {
  name        = "k3s-master"
  target_node = "pve"
  vmid        = 101
  clone       = "debian12-cloudinit"   # 👈 clone 
   your template
  full_clone  = true                   # 👈 makes VM independent from template
  memory      = 2048
  onboot      = true
  scsihw      = "virtio-scsi-pci"
  boot        = "cdn"

  cpu {
    cores = 2
    type  = "host"
  }

  # Network configuration
  network {
    id     = 0  # Required argument, must be unique integer :cite[7]
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Disk configuration
  disk {
    slot     = "scsi0" 
    type     = "disk"
    storage  = "local-lvm"
    size     = "32G"
    discard  = false
  }

  serial {
    id   = 0
    type = "socket"
  }

  cicustom = "user=local:snippets/bootstrap.yaml"
  # # Cloud-init config
  # ciuser      = "k3suser"
  # cipassword  = "securepassword"
  # # ipconfig0   = "ip=192.168.1.50/24,gw=192.168.1.1"
  # nameserver  = "1.1.1.1"
  # searchdomain = "homelab.local"

  # It's recommended to enable the QEMU agent for better management
  agent = 1
}