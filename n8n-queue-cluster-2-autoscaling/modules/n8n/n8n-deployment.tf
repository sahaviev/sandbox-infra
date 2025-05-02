resource "kubernetes_deployment" "n8n_deployment" {
  metadata {
    name      = "${var.name_prefix}-deployment"
    namespace = var.namespace
    labels = {
      service = var.name_prefix
    }
  }

  spec {
    replicas = var.enable_autoscaling ? var.autoscaling.min_replicas : var.replicas

    selector {
      match_labels = {
        service = var.name_prefix
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          service = var.name_prefix
        }
      }

      spec {
        init_container {
          name    = "volume-permissions"
          image   = "busybox:1.36"
          command = ["sh", "-c", "chown 1000:1000 /data"]

          volume_mount {
            name       = "${var.name_prefix}-data"
            mount_path = "/data"
          }
        }

        container {
          name    = var.name_prefix
          image   = "n8nio/n8n"
          command = ["/bin/sh"]
          args    = ["-c", "sleep 5; n8n ${var.mode}"]

          port {
            container_port = try(tonumber(var.env_vars.N8N_PORT), 5678)
          }

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

          dynamic "env" {
            for_each = var.env_vars
            content {
              name  = env.key
              value = env.value
            }
          }

          volume_mount {
            name       = "${var.name_prefix}-data"
            mount_path = "/home/node/.n8n"
          }
        }

        volume {
          name = "${var.name_prefix}-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.n8n_persistent_volume_claim.metadata[0].name
          }
        }

        restart_policy = "Always"
      }
    }
  }
}
