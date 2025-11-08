# Falco Sidekick

[Falco Sidekick](https://github.com/falcosecurity/falcosidekick) is a notification tool for Falco events. It takes Falco's events and forwards them to different outputs in a fan-out way.

## Overview

Falcosidekick acts as a single endpoint for Falco instances and manages a large variety of outputs including chat platforms, metrics systems, alerting tools, log aggregators, and more.

## Architecture

```
Falco (Runtime Security) → Falcosidekick → Multiple Outputs (Slack, Loki, Elasticsearch, etc.)
```

## Deployment

This Helm chart deploys Falcosidekick using FluxCD GitOps approach.

### Prerequisites

- Kubernetes cluster (K3s recommended)
- FluxCD installed and configured
- Falco installed and running (optional but recommended)

### Files

- `namespace.yaml` - Creates the falcosidekick namespace
- `helm-repository.yaml` - References the Falco Security Helm repository
- `helm-release.yaml` - Configures the Falcosidekick deployment
- `kustomization.yaml` - Kustomize configuration to tie everything together

## Configuration

The default configuration in `helm-release.yaml` includes:

- **Replica Count**: 1 (can be increased for high availability)
- **Security Context**: Non-root user with restricted capabilities
- **Resource Limits**: CPU 500m / Memory 512Mi
- **Service**: ClusterIP on port 2801

### Connecting to Falco

To connect Falco to Falcosidekick, update your Falco configuration to send events to:

```yaml
http://falcosidekick.falcosidekick.svc.cluster.local:2801
```

In the Falco Helm release, add:

```yaml
falcosidekick:
  enabled: true
  fullfqdn: true
  host: falcosidekick.falcosidekick.svc.cluster.local
  port: 2801
```

Or if Falco is in the same namespace:

```yaml
falcosidekick:
  enabled: true
  host: falcosidekick
  port: 2801
```

### Output Configuration

Falcosidekick supports numerous output integrations. Configure them in the `config` section of `helm-release.yaml`.

#### Example: Slack Integration

```yaml
config:
  slack:
    webhookurl: "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
    minimumpriority: "warning"
    outputformat: "text"
```

#### Example: Loki Integration

```yaml
config:
  loki:
    hostport: "http://loki.monitoring.svc.cluster.local:3100"
    minimumpriority: "debug"
```

#### Example: Elasticsearch Integration

```yaml
config:
  elasticsearch:
    hostport: "http://elasticsearch.logging.svc.cluster.local:9200"
    index: "falco"
    type: "_doc"
    minimumpriority: "warning"
```

#### Example: AlertManager Integration

```yaml
config:
  alertmanager:
    hostport: "http://alertmanager.monitoring.svc.cluster.local:9093"
    minimumpriority: "error"
```

#### Example: Prometheus Metrics

```yaml
config:
  prometheus:
    enabled: true
```

Then create a ServiceMonitor:

```yaml
serviceMonitor:
  enabled: true
  additionalLabels:
    release: prometheus
```

### Multiple Outputs

You can enable multiple outputs simultaneously:

```yaml
config:
  slack:
    webhookurl: "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
    minimumpriority: "warning"
  
  loki:
    hostport: "http://loki.monitoring.svc.cluster.local:3100"
    minimumpriority: "debug"
  
  elasticsearch:
    hostport: "http://elasticsearch.logging.svc.cluster.local:9200"
    index: "falco"
    minimumpriority: "warning"
```

## Supported Outputs

Falcosidekick supports a wide range of outputs:

### Chat & Collaboration
- Slack
- Microsoft Teams
- Discord
- Mattermost
- Rocket.Chat
- Google Chat
- Telegram

### Metrics & Observability
- Prometheus
- Datadog
- Grafana
- InfluxDB
- Wavefront
- Dynatrace

### Logging
- Elasticsearch
- Loki
- AWS CloudWatch Logs
- Syslog

### Alerting
- AlertManager
- Opsgenie
- PagerDuty
- Grafana OnCall

### Message Queues
- Kafka
- RabbitMQ
- NATS
- AWS SQS/SNS/Kinesis
- Azure Event Hubs
- GCP Pub/Sub

### Databases
- PostgreSQL
- MySQL
- Redis
- TimescaleDB

### Cloud Storage
- AWS S3
- GCP Storage
- Azure Blob Storage

For a complete list and configuration details, see the [official documentation](https://github.com/falcosecurity/falcosidekick/blob/master/docs/outputs/).

## Security Features

The deployment includes security best practices:

- **Non-root user**: Runs as UID/GID 1234
- **Read-only root filesystem**: Prevents modifications to the container filesystem
- **No privilege escalation**: Blocks privilege escalation attempts
- **Dropped capabilities**: All Linux capabilities are dropped
- **Seccomp profile**: Uses RuntimeDefault seccomp profile
- **Resource limits**: CPU and memory limits prevent resource exhaustion

## Web UI

Falcosidekick includes an optional Web UI for viewing and managing events. To enable it:

```yaml
webui:
  enabled: true
  ingress:
    enabled: true
    className: tailscale
    annotations:
      tailscale.com/tags: tag:k8s-operator
    hosts:
      - host: falcosidekick-ui
        paths:
          - path: /
            pathType: Prefix
```

## Monitoring

### Prometheus Metrics

Enable Prometheus metrics collection:

```yaml
config:
  prometheus:
    enabled: true

serviceMonitor:
  enabled: true
  additionalLabels:
    release: prometheus
  interval: "30s"
```

### Grafana Dashboards

Deploy pre-built Grafana dashboards:

```yaml
grafana:
  dashboards:
    enabled: true
    configMaps:
      falcosidekick:
        name: falcosidekick-grafana-dashboard
        namespace: monitoring
```

## Troubleshooting

### Check Falcosidekick logs

```bash
kubectl logs -n falcosidekick -l app.kubernetes.io/name=falcosidekick
```

### Check service status

```bash
kubectl get pods -n falcosidekick
kubectl get svc -n falcosidekick
```

### Test connectivity from Falco

```bash
# From a Falco pod
curl -v http://falcosidekick.falcosidekick.svc.cluster.local:2801/ping
```

### Common Issues

1. **Events not forwarding**: Check that Falco is configured with the correct Falcosidekick endpoint
2. **Output not working**: Verify output configuration and network connectivity
3. **High memory usage**: Increase resource limits or reduce replica count

## Integration with Homelab Security Stack

This deployment integrates with the homelab security stack:

- **Falco**: Runtime security monitoring (sends events to Falcosidekick)
- **Wazuh**: SIEM (can receive events from Falcosidekick via Loki or direct integration)
- **Kyverno**: Policy enforcement (complements runtime monitoring)

Example integration flow:
```
Falco detects suspicious activity → 
Falcosidekick receives event → 
Forwards to Slack (immediate alert) + Loki (logging) + Wazuh (SIEM)
```

## References

- [Falcosidekick GitHub](https://github.com/falcosecurity/falcosidekick)
- [Falcosidekick Helm Chart](https://github.com/falcosecurity/charts/tree/master/charts/falcosidekick)
- [Output Configuration Docs](https://github.com/falcosecurity/falcosidekick/blob/master/docs/outputs/)
- [Falco Documentation](https://falco.org/docs/)

## Version

This chart uses Falcosidekick Helm chart version `0.x` which will automatically use the latest 0.x.x version. You can pin to a specific version by updating the `version` field in `helm-release.yaml`.

## License

Falcosidekick is licensed under the Apache License 2.0.
