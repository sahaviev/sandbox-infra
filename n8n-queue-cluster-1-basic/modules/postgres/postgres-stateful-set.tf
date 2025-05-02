resource "kubernetes_stateful_set" "postgres_stateful_set" {
  metadata {
    name      = "${var.name_prefix}-stateful-set"
    namespace = var.namespace
    labels    = local.service_labels
  }

  spec {
    replicas = 1
    service_name = kubernetes_service.postgres_service.metadata[0].name

    selector {
      match_labels = {
        service = "${var.name_prefix}-service-selector"
      }
    }

    update_strategy {
      type = "RollingUpdate"
      rolling_update {
        partition = 0
      }
    }

    template {
      metadata {
        labels = {
          service = "${var.name_prefix}-service-selector"
        }
      }

      spec {
        container {
          name  = var.name_prefix
          image = var.postgres_image

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

          port {
            container_port = var.postgres_port
            name           = "postgresql"
          }

          volume_mount {
            name       = "${var.name_prefix}-data"
            mount_path = "/var/lib/postgresql/data"
          }

          volume_mount {
            name       = "${var.name_prefix}-init-data-config-map"
            mount_path = "/docker-entrypoint-initdb.d/init-data.sh"
            sub_path   = "init-data.sh"
          }

          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          env {
            name  = "POSTGRES_HOST"
            value = "${var.name_prefix}-service"
          }

          env {
            name  = "POSTGRES_PORT"
            value = var.postgres_port
          }

          dynamic "env" {
            for_each = var.env_vars
            content {
              name  = env.key
              value = env.value
            }
          }
        }

        volume {
          name = "${var.name_prefix}-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgresql_persistent_volume_claim.metadata[0].name
          }
        }

        volume {
          name = "${var.name_prefix}-init-data-config-map"
          config_map {
            name          = kubernetes_config_map.postgres_init_data_config_map.metadata[0].name
            default_mode  = "0744"
          }
        }

        restart_policy = "Always"
      }
    }
  }
}
