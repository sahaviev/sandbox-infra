
resource "kubernetes_service" "redis_service" {
  metadata {
    name      = "${var.name_prefix}-service"
    namespace = var.namespace
    labels    = local.service_labels
  }
  spec {
    port {
      port        = 6379
      target_port = 6379
    }
    selector = {
      app = "redis"
    }
    cluster_ip = "None"
  }
}
