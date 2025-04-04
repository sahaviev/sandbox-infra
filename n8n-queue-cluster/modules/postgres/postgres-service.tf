resource "kubernetes_service" "postgres_service" {
  metadata {
    name      = "${var.name_prefix}-service"
    namespace = var.namespace
    labels    = local.service_labels
  }

  spec {
    cluster_ip = "None"
    
    port {
      name        = "5432"
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }
    
    selector = {
      service = "${var.name_prefix}-service-selector"
    }
  }
}
