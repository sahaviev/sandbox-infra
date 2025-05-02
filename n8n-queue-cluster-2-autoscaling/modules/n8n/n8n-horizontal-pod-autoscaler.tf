resource "kubernetes_horizontal_pod_autoscaler_v2" "n8n_horizontal_pod_autoscaler" {
  count = var.enable_autoscaling ? 1 : 0

  metadata {
    name      = "${var.name_prefix}-horizonal-pod-autoscaler"
    namespace = var.namespace
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.n8n_deployment.metadata[0].name
    }

    min_replicas = var.autoscaling.min_replicas
    max_replicas = var.autoscaling.max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.autoscaling.target_cpu_utilization_percentage
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type               = "Utilization"
          average_utilization = var.autoscaling.target_memory_utilization_percentage
        }
      }
    }
  }
}
