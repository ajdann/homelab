# Kyverno Policies

This directory contains Kyverno policies for enforcing security and best practices across your homelab cluster.

## Policy Overview

### Security Policies

1. **require-security-context.yaml**
   - **Purpose**: Enforces security contexts on all pods
   - **Enforcement**: `enforce` (blocks non-compliant resources)
   - **Requirements**:
     - Pod-level security context with `runAsNonRoot: true`
     - Container-level security context with restricted capabilities
     - Read-only root filesystem
     - No privilege escalation

2. **prevent-privileged-containers.yaml**
   - **Purpose**: Prevents creation of privileged containers
   - **Enforcement**: `enforce` (blocks privileged containers)
   - **Security Impact**: High - prevents containers from accessing host resources

3. **auto-add-security-context.yaml**
   - **Purpose**: Automatically adds security contexts to pods
   - **Enforcement**: `enforce` (mutates resources)
   - **Behavior**: Adds default security settings if not present

### Resource Management Policies

4. **require-resource-limits.yaml**
   - **Purpose**: Ensures all containers have resource limits and requests
   - **Enforcement**: `enforce` (blocks resources without limits)
   - **Benefits**: Prevents resource exhaustion, ensures fair allocation

5. **prevent-latest-tag.yaml**
   - **Purpose**: Prevents use of `latest` image tags
   - **Enforcement**: `enforce` (blocks latest tags)
   - **Benefits**: Ensures reproducible deployments, better security

### Best Practices Policies

6. **require-labels.yaml**
   - **Purpose**: Enforces required labels on all pods
   - **Enforcement**: `enforce` (blocks resources without labels)
   - **Required Labels**:
     - `app`: Application name
     - `environment`: Environment (dev, staging, prod)
     - `team`: Team responsible

7. **require-network-policy.yaml**
   - **Purpose**: Encourages network policies for namespaces
   - **Enforcement**: `audit` (reports but doesn't block)
   - **Behavior**: Monitors for network policy labels

## Policy Categories

### High Severity (Security Critical)
- `prevent-privileged-containers.yaml`
- `require-security-context.yaml`

### Medium Severity (Best Practices)
- `require-resource-limits.yaml`
- `prevent-latest-tag.yaml`
- `auto-add-security-context.yaml`
- `require-network-policy.yaml`

### Low Severity (Organization)
- `require-labels.yaml`

## Enforcement Levels

- **`enforce`**: Blocks non-compliant resources from being created
- **`audit`**: Reports violations but allows resources to be created
- **`warn`**: Shows warnings but allows resources to be created

## Customization

### Adjusting Resource Limits
Modify `require-resource-limits.yaml` to set minimum/maximum values:

```yaml
pattern:
  spec:
    containers:
    - resources:
        limits:
          memory: ">= 128Mi"
          cpu: ">= 100m"
        requests:
          memory: ">= 64Mi"
          cpu: ">= 50m"
```

### Adding Exceptions
Use `exclude` rules to exclude specific resources:

```yaml
exclude:
  any:
  - resources:
      namespaces:
      - kube-system
      - kyverno
```

### Custom Labels
Modify `require-labels.yaml` to add your own required labels:

```yaml
pattern:
  metadata:
    labels:
      app: "?*"
      environment: "?*"
      team: "?*"
      version: "?*"
```

## Monitoring Policies

### Check Policy Status
```bash
# List all policies
kubectl get clusterpolicies

# Check policy reports
kubectl get policyreports -A

# View specific policy violations
kubectl get policyreports -o yaml | grep -A 10 "policyName: require-resource-limits"
```

### Policy Metrics
Kyverno exposes metrics for policy enforcement:
- `kyverno_policy_rule_info_total`
- `kyverno_policy_rule_results_total`

## Troubleshooting

### Common Issues

1. **Policy Too Restrictive**
   - Start with `audit` mode instead of `enforce`
   - Add exclusions for system namespaces
   - Gradually increase restrictions

2. **Resource Limits Too High**
   - Adjust the minimum requirements in policies
   - Consider workload-specific policies

3. **Security Context Conflicts**
   - Some applications require specific user IDs
   - Add exclusions or create workload-specific policies

### Testing Policies

```bash
# Test a policy against existing resources
kubectl apply -f test-pod.yaml --dry-run=server

# Check policy validation
kubectl get clusterpolicies require-resource-limits -o yaml
```

## Additional Policy Ideas

Consider adding these policies based on your needs:

1. **Pod Disruption Budgets**: Ensure high availability
2. **Service Account Restrictions**: Limit service account usage
3. **Ingress TLS**: Require HTTPS for all ingress
4. **Pod Anti-Affinity**: Prevent single points of failure
5. **Image Vulnerability Scanning**: Block vulnerable images
6. **Namespace Quotas**: Limit resource usage per namespace
7. **RBAC Restrictions**: Enforce least privilege access
8. **Audit Logging**: Ensure audit trails are enabled

## Policy Maintenance

- Regularly review and update policies
- Monitor policy reports for violations
- Adjust policies based on workload requirements
- Keep policies aligned with security standards 