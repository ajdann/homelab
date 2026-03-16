# KUBERNETES — Flux GitOps Manifests

## OVERVIEW

267 YAML files organized as Kustomize base/overlays for Flux GitOps. Flux reconciles the `dev` branch every 10s from `kubernetes/clusters/homelab/`.

## STRUCTURE

```
kubernetes/
├── clusters/
│   ├── homelab/
│   │   ├── flux-system/          # GitRepository + Kustomization + FluxInstance
│   │   └── kustomization.yaml    # → ../../infrastructure/overlays/dev + ../../apps/overlays/dev
│   └── production/               # INACTIVE — future production cluster scaffold
├── infrastructure/   # Core infra + Security + Monitoring (17 components)
│   ├── tailscale/, reloader/, dashboard/, ... (9 former core)
│   ├── wazuh/, kyverno/, falco/, ... (7 former security)
│   ├── loki-stack/ (1 former monitoring)
│   └── overlays/
│       ├── dev/kustomization.yaml  # Unified gate — controls what's active
│       └── prod/                   # Placeholder for production
└── apps/             # User-facing applications (6 components)
    ├── homepage/, adguard/, gitea/, ...
    └── overlays/
        ├── dev/kustomization.yaml
        └── prod/                   # Placeholder for production
```

## RECONCILIATION FLOW

```
GitRepository (dev branch, 10s poll)
  → Kustomization (homelab, 1m interval)
    → clusters/homelab/kustomization.yaml
      → infrastructure/overlays/dev + apps/overlays/dev
        → Each component's base/ (namespace + HelmRepository + HelmRelease or raw manifests)
```

PostBuild: `DOMAIN` variable substituted from `flux-substitutions` ConfigMap (created by Ansible).

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add new component | `infrastructure/<name>/base/` + `infrastructure/<name>/overlays/dev/` or `apps/<name>/base/` + `apps/<name>/overlays/dev/` | Follow Helm or raw manifest pattern below |
| Enable/disable component | `infrastructure/overlays/dev/kustomization.yaml` or `apps/overlays/dev/kustomization.yaml` | Comment/uncomment resource line |
| Add Kyverno policy | `infrastructure/kyverno/base/policies/` | Add YAML, then reference in policies/kustomization.yaml |
| Flux bootstrap config | `clusters/homelab/flux-system/` | FluxInstance, GitRepository, Kustomization |
| Wazuh certificates | `infrastructure/wazuh/overlays/dev/secret-files/` | indexer-certs/ and dashboard-certs/ |
| Wazuh secrets | `infrastructure/wazuh/overlays/dev/*.secret.yaml` | 5 base64-encoded Secrets |
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

### Infrastructure (11 active of 17)

#### Former Core (2 of 9 active)

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

#### Former Security (7 of 7 — all active)

| Component | Type | Version | Purpose |
|-----------|------|---------|---------|
| **wazuh** | HelmRelease | — | SIEM, log analysis, FIM |
| **kyverno** | HelmRelease | 3.1.0 | Policy engine (16 policies, 1 enabled) |
| **falco** | HelmRelease | 5.x | Runtime syscall monitoring |
| **falcosidekick** | HelmRelease | — | Falco event forwarding |
| **kubescape** | HelmRelease | 1.29.6 | Vulnerability scanning |
| **kubebench** | CronJob | — | CIS benchmark |
| **policy-reporter** | HelmRelease | 2.21.0 | Policy violation UI |

#### Former Monitoring (1 of 1 — active)

| Component | Type | Status |
|-----------|------|--------|
| **loki-stack** | HelmRelease | Active |

### Apps (1 of 6)

| Component | Type | Status |
|-----------|------|--------|
| **homepage** | Raw manifests | Active |
| adguard | Raw manifests | Commented |
| gitea | Raw + HelmRelease | Commented |
| authentik | HelmRelease | Commented |
| nextcloud | HelmRelease | Commented |
| seafile | Raw manifests | Commented |

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

Enable policies by uncommenting in `infrastructure/kyverno/base/policies/kustomization.yaml`.

## SECRETS MANAGEMENT

- **No encryption** — K8s Secrets are plain base64 YAML in `overlays/dev/`
- **Tailscale OAuth** — created by Ansible (not in this directory)
- **Wazuh certs** — stored in `infrastructure/wazuh/overlays/dev/secret-files/` (18 cert files)
- **Wazuh credentials** — 5 Secret files in `infrastructure/wazuh/overlays/dev/`
- **App secrets** — per-app `*.secret.yaml` in `apps/<name>/overlays/dev/`
- **Gitleaks ignores** `kubernetes/infrastructure/` and `kubernetes/apps/` overlays/dev paths for secret scanning

## ANTI-PATTERNS

- **Never put real secrets in base/** — secrets only in `overlays/dev/` (gitignored from gitleaks)
- **Don't create HelmRepository in a different namespace** than its HelmRelease — always co-locate
- **Don't skip namespace.yaml** — every component creates its own namespace
- **Don't use cluster-wide HelmRepository** — each component scopes its own

## NOTES

- **Flux uses FluxInstance CR** (Flux Operator pattern), not `flux bootstrap`
- **`clusters/homelab/kustomization.yaml`** references `../../infrastructure/overlays/dev` and `../../apps/overlays/dev` — the real content lives in those directories
- **`clusters/production/`** is scaffolded but INACTIVE — future production cluster placeholder
- **Kustomize `force: true`** is set on root Kustomization — forces apply even on immutable field changes
- **`prune: true`** — Flux garbage-collects resources removed from Git
- **Wazuh is the most complex component** — has sub-directories for indexer_stack, wazuh_managers, certs, plus secretGenerator for TLS
