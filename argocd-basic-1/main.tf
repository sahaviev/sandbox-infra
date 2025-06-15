module "argocd" {
  source = "./modules/argocd"

  namespace = kubernetes_namespace.argocd.metadata[0].name
  ingress_enabled = true
  ingress_hostname   = "argocd.local"

  argocd_users = {
    "rail" = {
      capabilities = ["login", "apiKey"]
      role = "admin"
    }
    "developer" = {
      capabilities = ["login"]
      role = "readonly"
    }
  }

  argocd_roles = {
    "readonly" = {
      policies = [
        "p, role:readonly, applications, get, */*, allow",
        "p, role:readonly, repositories, get, */*, allow"
      ]
    }
    "admin" = {
      policies = [
        "p, role:admin, applications, *, */*, allow",
        "p, role:admin, repositories, *, */*, allow"
      ]
    }
  }

  providers = {
    helm = helm
    kubectl = kubectl
  }

  depends_on = [kubernetes_namespace.argocd]
}
