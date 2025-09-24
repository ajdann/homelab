resource "proxmox_lxc" "ansible_control_node" {
  hostname     = "ansible-control-node"
  target_node  = var.proxmox_node
  ostemplate   = var.lxc_template
  memory       = 2048
  cores        = 1
  unprivileged = true
  vmid         = 200

  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }

  ssh_public_keys = file("../secrets/vm_ssh_pub_key")

  # Wait for cloud-init to complete
  # provisioner "remote-exec" {
  #   inline = [
  #     "cloud-init status --wait",
  #   ]

  #   connection {
  #     type        = "ssh"
  #     user        = "root"
  #     private_key = file("../secrets/vm_ssh_private_key")
  #     host        = self.network[0].ip
  #   }
  # }

  # Provision the control node
  # provisioner "remote-exec" {
  #   inline = [
  #     "apt-get update",
  #     "apt-get install -y ansible git",
  #     "git clone https://github.com/ajdann/homelab.git /root/homelab",
  #   ]

  #   connection {
  #     type        = "ssh"
  #     user        = "root"
  #     private_key = file("../secrets/vm_ssh_private_key")
  #     host        = self.network[0].ip
  #   }
  # }
}
