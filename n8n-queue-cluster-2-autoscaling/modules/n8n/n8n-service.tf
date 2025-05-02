resource "kubernetes_service" "n8n_service" {
  metadata {
    name      = "${var.name_prefix}-service"
    namespace = var.namespace
  }
  spec {
    selector = {
      service = var.name_prefix
    }
    port {
      port        = 5678
      target_port = 5678
    }
    type = "ClusterIP"
  }
}
