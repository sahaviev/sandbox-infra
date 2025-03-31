resource "kubernetes_service" "postgres_service" {
  metadata {
    name      = "postgres-service"
    namespace = "n8n-namespace"
    labels = {
      service = "postgres-n8n"
    }
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
      service = "postgres-n8n"
    }
  }
}
