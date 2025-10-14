# Example: Falco Integration Configuration
#
# To connect Falco to Falcosidekick, add the following configuration
# to the Falco helm-release.yaml in kubernetes/security/falco/
#
# This is an EXAMPLE ONLY - not required for the falcosidekick deployment

# Add this to spec.values in the Falco helm-release.yaml:
falcosidekick:
  enabled: true
  # Use the fully qualified domain name for cross-namespace communication
  fullfqdn: true
  host: falcosidekick.falcosidekick.svc.cluster.local
  port: 2801

# Alternative: If both Falco and Falcosidekick are in the same namespace,
# you can use the simple service name:
# falcosidekick:
#   enabled: true
#   host: falcosidekick
#   port: 2801

# The complete Falco helm-release would look like:
# ---
# apiVersion: helm.toolkit.fluxcd.io/v2
# kind: HelmRelease
# metadata:
#   name: falco
#   namespace: falco
# spec:
#   interval: 5m
#   chart:
#     spec:
#       chart: falco
#       version: "5.x"
#       sourceRef:
#         kind: HelmRepository
#         name: falco
#         namespace: falco
#   values:
#     falcosidekick:
#       enabled: true
#       fullfqdn: true
#       host: falcosidekick.falcosidekick.svc.cluster.local
#       port: 2801
#     # ... other Falco configuration ...
