variable "proxmox_node" {
  description = "The Proxmox node to deploy to"
  default     = "pve"
}

variable "template_name" {
  description = "The name of the template to clone from"
  default     = "debian12-cloudinit"
}

variable "vm_disk_size" {
  description = "The size of the VM disk in GB."
  default     = 32
}
