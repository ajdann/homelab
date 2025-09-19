resource "proxmox_vm_qemu" "server" {
  for_each = var.vms

  # VM General settings
  name        = each.value.name
  target_node = var.proxmox_node
  vmid        = each.value.vmid
  onboot      = true

  # Cloning settings
  clone      = each.value.template
  full_clone = true

  # System settings
  agent  = 1 # Enable QEMU Guest Agent
  memory = each.value.memory
  scsihw = "virtio-scsi-pci"
  boot   = "order=scsi0"

  ipconfig0 = each.value.ipconfig0
  balloon   = each.value.balloon

  cpu {
    cores   = each.value.cores
    sockets = each.value.sockets
    type    = "host"
  }

  disks {
    scsi {
      scsi0 {
        disk {
          size    = each.value.disk_size
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
  ciuser     = file("../secrets/vm_user")
  cipassword = file("../secrets/vm_password")
  ciupgrade  = true
  sshkeys    = file("../secrets/vm_ssh_pub_key")

  serial {
    id   = 0
    type = "socket"
  }

  vga {
    type = "serial0"
  }
  tags = each.value.tags
}