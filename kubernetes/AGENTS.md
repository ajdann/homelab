# KUBERNETES — Flux GitOps Manifests

## OVERVIEW

267 YAML files organized as Kustomize base/overlays for Flux GitOps. Flux reconciles the `dev` branch every 10s from `kubernetes/clusters/homelab/`.

## STRUCTURE

```
kubernetes/
├── clusters/
│   └── homelab/
│       ├── flux-system/          # GitRepository + Kustomization + FluxInstance
│       ├── apps/kustomization.yaml       # → ../../../apps/overlays/dev
│       ├── core/kustomization.yaml       # → ../../../core/overlays/dev
│       ├── security/kustomization.yaml   # → ../../../security/overlays/dev
│       ├── monitoring/kustomization.yaml # → ../../../monitoring/overlays/dev
│       └── secrets/kustomization.yaml    # → ../../../secrets/dev
├── core/           # Infrastructure services (10 components, 2 active)
├── security/       # Security stack (7 components, all active)
├── apps/           # Applications (6 components, 1 active)
└── monitoring/     # Observability (1 component: loki-stack)
```

## RECONCILIATION FLOW

```
GitRepository (dev branch, 10s poll)
  → Kustomization (homelab, 1m interval)
    → clusters/homelab/kustomization.yaml
      → apps/overlays/dev, core/overlays/dev, security/overlays/dev, monitoring/overlays/dev
        → Each component's base/ (namespace + HelmRepository + HelmRelease or raw manifests)
```

PostBuild: `DOMAIN` variable substituted from `flux-substitutions` ConfigMap (created by Ansible).

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add new component | `{category}/<name>/base/` + `{category}/<name>/overlays/dev/` | Follow Helm or raw manifest pattern below |
| Enable/disable component | `{category}/overlays/dev/kustomization.yaml` | Comment/uncomment resource line |
| Add Kyverno policy | `security/kyverno/base/policies/` | Add YAML, then reference in policies/kustomization.yaml |
| Flux bootstrap config | `clusters/homelab/flux-system/` | FluxInstance, GitRepository, Kustomization |
| Wazuh certificates | `security/wazuh/overlays/dev/secret-files/` | indexer-certs/ and dashboard-certs/ |
| Wazuh secrets | `security/wazuh/overlays/dev/*.secret.yaml` | 5 base64-encoded Secrets |
| App secrets | `apps/<name>/overlays/dev/*.secret.yaml` | Per-app secret files |

## COMPONENT PATTERN (Helm-based)

Every Helm component follows this exact structure:

```
<component>/
├── base/
│   ├── kustomization.yaml    # namespace: <name>, resources: [namespace, helm-repo, helm-release]
│   ├── namespace.yaml        # Namespace with app.kubernetes.io/name label
│   ├── helm-repository.yaml  # HelmRepository CR (namespace-scoped)
│   └── helm-release.yaml     # HelmRelease CR referencing local HelmRepository
└── overlays/
    └── dev/
        └── kustomization.yaml  # resources: [../../base] + optional patches/secrets
```

## COMPONENT PATTERN (Raw manifests — e.g., Homepage)

```
<component>/
├── base/
│   ├── kustomization.yaml    # namespace: <name>, resources: [all manifests]
│   ├── namespace.yaml
│   ├── deployment.yaml       # Security context: runAsNonRoot, UID 1000, drop ALL
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   └── rbac.yaml
└── overlays/dev/
    └── kustomization.yaml
```

## ACTIVE COMPONENTS

### Core (2 of 10)

| Component | Type | Version | Status |
|-----------|------|---------|--------|
| **tailscale** | HelmRelease | 1.90.9 | Active |
| **reloader** | HelmRelease | — | Active |
| dashboard | HelmRelease | — | Commented |
| kured | HelmRelease | — | Commented |
| netdata | HelmRelease | — | Commented |
| nginx-ingress | HelmRelease | — | Commented |
| prometheus | HelmRelease | — | Commented |
| traefik | HelmRelease | — | Commented |
| keda | HelmRelease | — | Commented |

### Security (7 of 7 — all active)

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| **wazuh** | HelmRelease | — | SIEM, log analysis, FIM |
| **kyverno** | HelmRelease | 3.1.0 | Policy engine (16 policies, 1 enabled) |
| **falco** | HelmRelease | 5.x | Runtime syscall monitoring |
| **falcosidekick** | HelmRelease | — | Falco event forwarding |
| **kubescape** | HelmRelease | 1.29.6 | Vulnerability scanning |
| **kubebench** | CronJob | — | CIS benchmark |
| **policy-reporter** | HelmRelease | 2.21.0 | Policy violation UI |

### Apps (1 of 6)

| Component | Type | Status |
|-----------|------|--------|
| **homepage** | Raw manifests | Active |
| adguard | Raw manifests | Commented |
| gitea | Raw + HelmRelease | Commented |
| authentik | HelmRelease | Commented |
| nextcloud | HelmRelease | Commented |
| seafile | Raw manifests | Commented |

### Monitoring (1)

| Component | Type | Status |
|-----------|------|--------|
| **loki-stack** | HelmRelease | Active |

## KYVERNO POLICIES (16 available, 1 enabled)

| Policy | Mode | Enforces |
|--------|------|----------|
| **require-labels** | Audit | `app`, `environment`, `team` labels on Pods |
| require-security-context | Audit | runAsNonRoot, capabilities, readOnlyRootFilesystem |
| auto-add-security-context | **Enforce** (mutate) | Auto-injects security context on Pods/Deployments |
| prevent-privileged-containers | Audit | Blocks `privileged: true` (exempts kured namespace) |
| prevent-latest-tag | Audit | Blocks `:latest` image tags |
| require-resource-limits | Audit | CPU + memory limits/requests required |
| require-network-policy | Audit | Namespace must have `network-policy` label |
| pod-security-baseline-standards | Audit | K8s PSS baseline profile |
| pod-security-restricted | Audit | K8s PSS restricted profile |
| podsecurity-subrule-restricted-seccomp | Audit | Restricted PSS minus seccomp |
| podsecurity-subrule-restricted-capabilities | Audit | Restricted PSS with image exemptions |
| verify-flux-git-repositories | Audit | GitRepository URLs must match `github.com/fluxcd/*` |
| verify-flux-images | Audit | Cosign signature verification for Flux images |
| verify-flux-sources-in-cel | Audit | CEL-based source validation (requires Kyverno 1.11+) |
| detect-non-flux-objects | Audit | Flags resources missing Flux management labels |

Enable policies by uncommenting in `security/kyverno/base/policies/kustomization.yaml`.

## SECRETS MANAGEMENT

- **No encryption** — K8s Secrets are plain base64 YAML in `overlays/dev/`
- **Tailscale OAuth** — created by Ansible (not in this directory)
- **Wazuh certs** — stored in `security/wazuh/overlays/dev/secret-files/` (18 cert files)
- **Wazuh credentials** — 5 Secret files in `security/wazuh/overlays/dev/`
- **App secrets** — per-app `*.secret.yaml` in `apps/<name>/overlays/dev/`
- **Gitleaks ignores** `kubernetes/overlays/dev/` for secret scanning

## ANTI-PATTERNS

- **Never put real secrets in base/** — secrets only in `overlays/dev/` (gitignored from gitleaks)
- **Don't create HelmRepository in a different namespace** than its HelmRelease — always co-locate
- **Don't skip namespace.yaml** — every component creates its own namespace
- **Don't use cluster-wide HelmRepository** — each component scopes its own

## NOTES

- **Flux uses FluxInstance CR** (Flux Operator pattern), not `flux bootstrap`
- **`clusters/homelab/{apps,core,security,monitoring}/kustomization.yaml`** are thin redirects to `../../../{category}/overlays/dev` — the real content lives in the category directories
- **Kustomize `force: true`** is set on root Kustomization — forces apply even on immutable field changes
- **`prune: true`** — Flux garbage-collects resources removed from Git
- **Wazuh is the most complex component** — has sub-directories for indexer_stack, wazuh_managers, certs, plus secretGenerator for TLS
