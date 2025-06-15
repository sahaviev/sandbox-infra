resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd-namespace"

    labels = {
      environment = "development"
      team        = "platform"
    }

    annotations = {
      "created-by" = "terraform"
    }
  }
}
