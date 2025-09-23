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
  nameserver = each.value.nameserver
  
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
  # cipassword = file("../secrets/vm_password")
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

  # Wait for cloud-init to complete
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
    ]

    connection {
      type        = "ssh"
      user        = file("../secrets/vm_user")
      private_key = file("../secrets/vm_ssh_private_key")
      host        = self.default_ipv4_address
    }
  }

  # Run Ansible playbook
  provisioner "local-exec" {
    command = <<-EOT
      if [[ "${each.value.name}" == *"k3s"* ]]; then
        ansible-playbook -i '${self.default_ipv4_address},' playbooks/k3s-ha.yaml
        ansible-playbook -i '${self.default_ipv4_address},' playbooks/bootstrap-k8s.yaml
      elif [[ "${each.value.name}" == *"haproxy"* ]]; then
        ansible-playbook -i '${self.default_ipv4_address},' playbooks/haproxy.yaml
      fi
    EOT
    working_dir = "../ansible"
    environment = {
      ANSIBLE_REMOTE_USER           = file("../secrets/vm_user")
      ANSIBLE_PRIVATE_KEY_FILE      = abspath("../secrets/vm_ssh_private_key")
      ANSIBLE_HOST_KEY_CHECKING     = "False"
    }
  }
}