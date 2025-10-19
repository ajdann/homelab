# Loki Stack - Logs and Metrics with Grafana

## Overview

This deployment provides a complete logging and visualization stack using:
- **Loki**: Log aggregation system inspired by Prometheus
- **Grafana**: Visualization and analytics platform (pinned to latest version)
- **Promtail**: Agent for collecting and forwarding logs to Loki

## Architecture

```
Container Logs → Promtail → Loki → Grafana (Visualization)
                                  ↓
                             Persistent Storage
```

## Deployment

This Helm chart deploys the Loki Stack using FluxCD GitOps approach.

### Prerequisites

- Kubernetes cluster (K3s recommended)
- FluxCD installed and configured
- Tailscale operator configured for ingress
- Persistent storage available (for Loki and Grafana data)

### Files

- `namespace.yaml` - Creates the monitoring namespace
- `helm-repository.yaml` - References the Grafana Helm repository
- `helm-release.yaml` - Configures the Loki Stack deployment
- `kustomization.yaml` - Kustomize configuration to tie everything together

### Installation

The stack is automatically deployed via FluxCD when included in the overlay kustomization.

To enable it for the homelab cluster:
```yaml
# In kubernetes/monitoring/overlays/dev/kustomization.yaml
resources:
  - ../../loki-stack/overlays/dev
```

## Configuration

### Grafana

**Version**: 11.3.0 (pinned to latest stable)

**Default Credentials**:
- Username: `admin`
- Password: `admin`

⚠️ **Important**: Change the default password after first login!

**Ingress**: 
- Hostname: `grafana`
- Access via: `https://grafana.${DOMAIN}` (Tailscale)
- Ingress Class: `tailscale`
- TLS: Automatically handled by Tailscale

**Data Persistence**: 
- Volume size: 5Gi
- Used for dashboards, plugins, and settings

**Pre-configured Datasources**:
- Loki datasource automatically configured and set as default

### Loki

**Service Endpoint**: `http://loki-stack:3100`

**Data Persistence**: 
- Volume size: 10Gi
- Stores log data with 7-day retention by default

**Log Ingestion**: 
- Accepts logs from Promtail agents
- HTTP API available at port 3100

### Promtail

**Function**: Collects logs from Kubernetes pods and forwards to Loki

**Configuration**:
- Runs as DaemonSet on all nodes
- Automatically discovers and tails container logs
- Applies labels for pod, namespace, container metadata

## Security Features

### Grafana Security
- Non-root user (UID 472)
- Read-only root filesystem disabled (needs write for plugins)
- Dropped all capabilities
- No privilege escalation
- Seccomp profile: RuntimeDefault
- Resource limits enforced

### Loki Security
- Non-root user (UID 10001)
- Read-only root filesystem
- Dropped all capabilities
- No privilege escalation
- Seccomp profile: RuntimeDefault
- Resource limits enforced

### Promtail Security
- Runs as root (required to read container logs)
- Read-only root filesystem
- Dropped all capabilities
- No privilege escalation
- Seccomp profile: RuntimeDefault
- Resource limits enforced

## Accessing Grafana

### Via Tailscale

Once deployed, access Grafana at:
```
https://grafana.${DOMAIN}
```

Replace `${DOMAIN}` with your Tailscale domain configured in `.env`.

### First Login

1. Navigate to `https://grafana.${DOMAIN}`
2. Login with default credentials:
   - Username: `admin`
   - Password: `admin`
3. **Change the password immediately** when prompted

### Viewing Logs

1. In Grafana, go to **Explore**
2. Select **Loki** as the datasource (already configured)
3. Use LogQL queries to search logs:
   ```
   {namespace="monitoring"}
   {app="nginx"} |= "error"
   {pod=~"loki.*"}
   ```

## Integration with Other Services

### Falcosidekick Integration

To send Falco security events to Loki, update Falcosidekick configuration:

```yaml
config:
  loki:
    hostport: "http://loki-stack.monitoring.svc.cluster.local:3100"
    minimumpriority: "debug"
```

### Application Log Collection

Promtail automatically collects logs from all pods. To add custom labels or filters:

1. Add annotations to your pods:
   ```yaml
   annotations:
     promtail.io/collect: "true"
   ```

2. Promtail will automatically discover and collect these logs

## Resource Requirements

### Grafana
- **CPU**: 100m request, 500m limit
- **Memory**: 256Mi request, 512Mi limit
- **Storage**: 5Gi PVC

### Loki
- **CPU**: 100m request, 500m limit
- **Memory**: 512Mi request, 1Gi limit
- **Storage**: 10Gi PVC

### Promtail (per node)
- **CPU**: 100m request, 200m limit
- **Memory**: 128Mi request, 256Mi limit

## Troubleshooting

### Grafana Not Accessible

1. Check ingress status:
   ```bash
   kubectl get ingress -n monitoring
   ```

2. Verify Tailscale operator is running:
   ```bash
   kubectl get pods -n tailscale
   ```

3. Check Grafana pod logs:
   ```bash
   kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
   ```

### No Logs Appearing in Loki

1. Check Promtail status:
   ```bash
   kubectl get pods -n monitoring -l app.kubernetes.io/name=promtail
   ```

2. View Promtail logs:
   ```bash
   kubectl logs -n monitoring -l app.kubernetes.io/name=promtail
   ```

3. Verify Loki is receiving logs:
   ```bash
   kubectl logs -n monitoring -l app.kubernetes.io/name=loki
   ```

### Storage Issues

1. Check PVC status:
   ```bash
   kubectl get pvc -n monitoring
   ```

2. Ensure storage class is available:
   ```bash
   kubectl get storageclass
   ```

## Customization

### Change Grafana Version

To update Grafana to a different version, edit `helm-release.yaml`:

```yaml
grafana:
  image:
    tag: "11.4.0"  # Update to desired version
```

### Adjust Log Retention

To change Loki's log retention period, add to `helm-release.yaml`:

```yaml
loki:
  config:
    table_manager:
      retention_deletes_enabled: true
      retention_period: 168h  # 7 days (default)
```

### Add Additional Datasources

Add more datasources in Grafana configuration:

```yaml
grafana:
  datasources:
    datasources.yaml:
      apiVersion: 1
      datasources:
        - name: Loki
          type: loki
          url: http://loki-stack:3100
        - name: Prometheus
          type: prometheus
          url: http://prometheus:9090
```

## Monitoring and Alerts

### Grafana Dashboards

Import pre-built dashboards:
1. Go to **Dashboards** → **Import**
2. Enter dashboard ID or upload JSON
3. Recommended dashboards:
   - Loki Dashboard: `13639`
   - Kubernetes Cluster Monitoring: `7249`

### Alerting

Configure alerts in Grafana:
1. Go to **Alerting** → **Alert rules**
2. Create new alert rules based on LogQL queries
3. Configure notification channels (Slack, Email, etc.)

## Maintenance

### Backup

Important data to backup:
- Grafana dashboards and settings: `/var/lib/grafana`
- Loki logs: `/data/loki`

Use Velero or similar tools for automated backups.

### Updates

FluxCD automatically manages updates based on the version specified in `helm-release.yaml`.

To update manually:
1. Edit version in `helm-release.yaml`
2. Commit and push changes
3. FluxCD will reconcile and update the deployment

## References

- [Loki Stack Helm Chart](https://artifacthub.io/packages/helm/grafana/loki-stack)
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [LogQL Query Language](https://grafana.com/docs/loki/latest/logql/)
- [Promtail Configuration](https://grafana.com/docs/loki/latest/clients/promtail/)

## Support

For issues or questions:
1. Check pod status: `kubectl get pods -n monitoring`
2. Review logs: `kubectl logs -n monitoring <pod-name>`
3. Verify configuration: `kubectl get helmrelease -n monitoring loki-stack -o yaml`
