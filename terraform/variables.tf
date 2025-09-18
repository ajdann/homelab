variable "proxmox_node" {
  description = "The Proxmox node to deploy to"
  default     = "pve"
}

variable "template_name" {
  description = "The name of the template to clone from"
  default     = "debian12-cloudinit"
}

variable "vms" {
  description = "A map of VMs to create"
  type = map(object({
    name      = string
    vmid      = number
    memory    = number
    cores     = number
    sockets   = number
    ipconfig0 = string
    disk_size = string
  }))
  default = {}
}