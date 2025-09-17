terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc04"
    }
  }
}

provider "proxmox" {
  pm_api_url  = "https://192.168.1.157:8006/api2/json"
  pm_user     = "root@pam"
  pm_password = "12345678"
  #   pm_password = trimspace(file("../secrets/proxmox_api_password"))
  pm_tls_insecure = true
}