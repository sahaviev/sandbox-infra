# Add ArgoCD Helm Repository
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = var.namespace

  # Wait for deployment to be ready
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  # Values file with templating
  values = [
    yamlencode(local.values)
  ]

  # Additional configuration via set blocks
  dynamic "set" {
    for_each = var.admin_password != "" ? [1] : []
    content {
      name  = "configs.secret.argocdServerAdminPassword"
      value = bcrypt(var.admin_password)
    }
  }

  depends_on = [
    kubectl_manifest.argocd_certificate
  ]
}

# Get ArgoCD admin password (if auto-generated)
data "kubernetes_secret" "argocd_initial_admin_secret" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = var.namespace
  }

  depends_on = [helm_release.argocd]
}
