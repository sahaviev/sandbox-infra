resource "kubernetes_namespace" "vault" {
  metadata {
    name = var.namespace
  }
}
