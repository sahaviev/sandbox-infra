resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = var.vault_chart_version
  namespace  = var.namespace

  values = [
    templatefile("${path.module}/vault-values.yaml", {
      vault_image_tag    = var.vault_image_tag
      storage_size       = var.storage_size
      storage_class      = var.storage_class
      ingress_enabled    = var.ingress_enabled
      ingress_hostname   = var.ingress_hostname
    })
  ]

  depends_on = [kubernetes_namespace.vault]
}
