resource "kubernetes_stateful_set" "redis_stateful_set" {
  metadata {
    name      = "${var.name_prefix}-stateful-set"
    namespace = var.namespace
    labels    = local.service_labels
  }
  spec {
    service_name = kubernetes_service.redis_service.metadata[0].name
    replicas     = var.replicas

    selector {
      match_labels = {
        app = "redis"
      }
    }
    template {
      metadata {
        labels = {
          app = "redis"
        }
      }
      spec {
        container {
          name  = "redis"
          image = var.redis_image

          port {
            container_port = 6379
          }

          volume_mount {
            name       = "redis-data"
            mount_path = "/data"
          }

          command = ["redis-server", "--appendonly", "yes"]
          
          resources {
            limits = {
              cpu    = var.resource_limits.cpu
              memory = var.resource_limits.memory
            }
            requests = {
              cpu    = var.resource_requests.cpu
              memory = var.resource_requests.memory
            }
          }
        }

        volume {
          name = "redis-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.redis_persistent_volume_claim.metadata[0].name
          }
        }
      }
    }
  }
}
