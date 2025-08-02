cat .\butane.yaml | docker run --rm -i quay.io/coreos/butane:latest > ignition.json  
docker run --rm -v ${PWD}:/work -w /work quay.io/coreos/ignition-validate ignition.json

# Demo Setup: Local K3s Cluster with Flux via Vagrant & Ansible

This project sets up a local **Kubernetes (K3s)** cluster using **Vagrant**, **Ansible**, and a **Makefile**

---

## ✅ Requirements

Make sure the following tools are installed on your host machine:

- [Vagrant](https://www.vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/) (or another Vagrant-compatible provider)
- [Ansible](https://www.ansible.com/)
- [GNU Make](https://www.gnu.org/software/make/)


---

## 🚀 Getting Started

### 1. Set up Tailscale OAuth

### 2. Start the VM
```bash
make up
```
### 3. Bootstrap the VM
```bash
make bootstrap
```


### Tailscale OAuth Secret

The Tailscale operator requires OAuth credentials to function. These credentials need to be created manually as a Kubernetes secret. Follow these steps:

1. Create a Tailscale OAuth client:
   - Go to https://login.tailscale.com/admin/settings/oauth
   - Click "Create OAuth Client"
   - Note down the Client ID and Client Secret

2. Create the Tailscale namespace:
   ```bash
   kubectl create namespace tailscale
   ```

3. Create the Kubernetes secret:
   ```bash 
   kubectl create secret generic operator-oauth --namespace tailscale \
     --from-literal=client_id=your-client-id \
     --from-literal=client_secret=your-client-secret
   ```

4. Verify the secret was created:
   ```bash
   kubectl get secret tailscale-oauth -n tailscale
   ```

Note: This secret needs to be created before deploying the Tailscale operator. The operator will use these credentials to authenticate with Tailscale.

### Tailscale Tag

- Tailscale operator for Kubernetes integration
- OAuth-based authentication
- Automatic node management
- **Important**: Requires `tag:k8s-operator` to be configured in Tailscale admin console
  - Go to https://login.tailscale.com/admin/acls/file
  - Add tag `k8s-operator`
  ```json
	"tagOwners": {
		"tag:k8s-operator": ["autogroup:admin"],
	},
   ```

## Storage

## Security

## High Availability
