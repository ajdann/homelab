locals {
  flux_instance_values = yamldecode(file("${path.module}/../kubernetes/flux/fluxInstance.yaml"))
}

resource "helm_release" "flux_operator" {
  name             = "flux-operator"
  namespace        = "flux-system"
  repository       = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart            = "flux-operator"
  create_namespace = true
}

resource "helm_release" "flux_instance" {
  depends_on = [helm_release.flux_operator]

  name       = "flux"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-instance"

  values = [
    yamlencode({
      instance = merge(local.flux_instance_values.spec, {
        sync = {
          kind     = "GitRepository"
          interval = "1m0s"
          url      = "https://github.com/ajdann/homelab.git"
          ref      = "refs/heads/main"
          path     = "./kubernetes/overlays/dev"
        }
      })
    })
  ]

}
