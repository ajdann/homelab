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
  pm_password     = var.proxmox_api_password
  pm_tls_insecure = "true"
}



data "template_file" "cloud_init_user_data" {
  template = file("${path.module}/cloud-init.yml")

  vars = {
    user           = var.cloud_init_user
    password       = var.cloud_init_password
    ssh_public_key = var.cloud_init_ssh_public_key
  }
}

resource "proxmox_cloud_init_disk" "cloud_init" {
  name         = "k3s-master-cloud-init.iso"
  pve_node     = var.proxmox_node
  storage      = "local"
  user_data    = data.template_file.cloud_init_user_data.rendered
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

  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
  }

  disks {
    scsi {
      scsi0 {
        disk {
          size    = var.vm_disk_size
          storage = "local-lvm"
        }
      }
    }
  }

  ide2 = "${proxmox_cloud_init_disk.cloud_init.storage}:cloudinit"

  # Network settings
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }
}
