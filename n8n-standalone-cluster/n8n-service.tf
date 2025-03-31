resource "kubernetes_service" "n8n_service" {
  metadata {
    name = "n8n-service"
    namespace = "n8n-namespace"
  }
  spec {
    selector = {
      service = "n8n"
    }
    port {
      port        = 5678
      target_port = 5678
    }
    type = "NodePort"
  }
}
