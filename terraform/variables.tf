variable "proxmox_api_password" {
  description = "The password for the Proxmox API."
  sensitive   = true
}

variable "proxmox_node" {
  description = "The Proxmox node to deploy to"
  default     = "pve"
}

variable "template_name" {
  description = "The name of the template to clone from"
  default     = "debian12-cloudinit"
}

variable "cloud_init_user" {
  description = "The username for the cloud-init user."
  default     = "admin"
}

variable "cloud_init_password" {
  description = "The password for the cloud-init user."
  sensitive   = true
}

variable "cloud_init_ssh_public_key" {
  description = "The public SSH key for the cloud-init user."
}

variable "cloud_init_ssh_private_key" {
  description = "The private SSH key for the cloud-init user."
  sensitive = true
}

variable "vm_disk_size" {
  description = "The size of the VM disk in GB."
  default     = 32
}
