# 📖 Project Overview
This project aims to build a secure and accessible Kubernetes-based homelab environment combined with Tailscale VPN for private, encrypted access over the internet.


## Demo Setup: Local K3s Cluster with Flux via Vagrant & Ansible

This project sets up a local **Kubernetes (K3s)** cluster using **Vagrant**, **Ansible**, and a **Makefile**

---

### ✅ Requirements

Make sure the following tools are installed on your host machine:

- [Vagrant](https://www.vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/) (or another Vagrant-compatible provider)
- [Ansible](https://www.ansible.com/)
- [GNU Make](https://www.gnu.org/software/make/)


---


#### 1. Set up Tailscale OAuth
[Go to Tailscale setup](#tailscale-setup)

#### 2. Set up env vars
- Copy `.env.example` to `.env`:
  ```bash
  cp .env.example .env  
  ```
- Edit `.env` and fill in the required values:
   - Tailscale Client ID
   - Tailscale Client Secret
   - Tailscale Domain

#### 2. Start the VM
```bash
make up
```
#### 3. Bootstrap the VM
```bash
make bootstrap
```


### Tailscale Setup

The Tailscale operator requires OAuth credentials to function. These credentials need to be created manually as a Kubernetes secret. Follow these steps:

1. Create a Tailscale OAuth client:
   - Go to https://login.tailscale.com/admin/settings/oauth
   - Click "Create OAuth Client"
   - Copy the Client ID and Client Secret


2. Set Up the Tailscale Tag
- ⚠️ This is required for the Tailscale K8s Operator to function.
  - Go to https://login.tailscale.com/admin/acls/file
  - Add the following to your ACL file:
  ```json
	"tagOwners": {
		"tag:k8s-operator": ["autogroup:admin"],
	},
   ```
   - Save and apply the ACL changes.

## Storage
TODO
## Security
TODO
## High Availability
TODO