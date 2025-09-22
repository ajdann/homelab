variable "proxmox_node" {
  description = "The Proxmox node to deploy to"
  default     = "pve"
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
    template  = string
    nameserver = string
    balloon   = optional(number, 0)
    tags      = optional(string, "")
  }))
  default = {}
}