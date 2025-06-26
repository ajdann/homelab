cat .\butane.yaml | docker run --rm -i quay.io/coreos/butane:latest > ignition.json  
docker run --rm -v ${PWD}:/work -w /work quay.io/coreos/ignition-validate ignition.json

## Manual Setup Steps

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


### Flux Set up

1. helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator --namespace flux-system --create-namespace
2. kubectl apply -f flux-system\fluxInstance.yaml