terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc04"
    }
  }
}

provider "proxmox" {}

# Define variables for VM properties
variable "proxmox_node" {
  description = "The Proxmox node to deploy to"
  default     = "pve"
}

variable "template_name" {
  description = "The name of the template to clone from"
  default     = "debian12-cloudinit"
}

# Resource to create the k3s-master VM
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
  boot   = "scsi0" # CRITICAL: Boot from the correct disk
  cpu {
    cores  = 2
    sockets = 1
    type   = "host"
  }

  # Network settings
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Cloud-Init settings
  ipconfig0   = "ip=10.0.0.10/24,gw=10.0.0.1"
  ciuser      = "admin"
  cipassword  = "SuperSecret123"
  # sshkeys     = <<-EOT
  #   # Paste your public SSH key here
  #   ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAA... user@domain
  # EOT
}
