cat .\butane.yaml | docker run --rm -i quay.io/coreos/butane:latest > ignition.json  
docker run --rm -v ${PWD}:/work -w /work quay.io/coreos/ignition-validate ignition.json

## Manual Setup Steps

### Tailscale OAuth Secret

The Tailscale operator requires OAuth credentials to function. These credentials need to be created manually as a Kubernetes secret. Follow these steps:

1. Create a Tailscale OAuth client:
   - Go to https://login.tailscale.com/admin/authkeys
   - Click "Create OAuth Client"
   - Note down the Client ID and Client Secret

2. Create the Kubernetes secret:
   ```bash
   kubectl create secret generic operator-oauth \
     --namespace tailscale \
     --from-literal=clientId=your-client-id \
     --from-literal=clientSecret=your-client-secret
   ```

3. Verify the secret was created:
   ```bash
   kubectl get secret tailscale-oauth -n tailscale
   ```

Note: This secret needs to be created before deploying the Tailscale operator. The operator will use these credentials to authenticate with Tailscale.