resource "kubernetes_stateful_set" "postgres_stateful_set" {
  metadata {
    name      = "postgres-stateful-set"
    namespace = "n8n-namespace"
    labels = {
      service = "postgres-n8n"
    }
  }

  spec {
    replicas = 1
    service_name = "postgres-service"

    selector {
      match_labels = {
        service = "postgres-n8n"
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
          service = "postgres-n8n"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:11"
          
          resources {
            limits = {
              cpu    = "4"
              memory = "4Gi"
            }
            requests = {
              cpu    = "1"
              memory = "2Gi"
            }
          }

          port {
            container_port = 5432
            name           = "postgresql"
          }

          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }

          volume_mount {
            name       = "init-data"
            mount_path = "/docker-entrypoint-initdb.d/init-n8n-user.sh"
            sub_path   = "init-data.sh"
          }

          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = "postgres-secret"
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = "postgres-secret"
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name  = "POSTGRES_DB"
            value = "n8n"
          }

          env {
            name = "POSTGRES_NON_ROOT_USER"
            value_from {
              secret_key_ref {
                name = "postgres-secret"
                key  = "POSTGRES_NON_ROOT_USER"
              }
            }
          }

          env {
            name = "POSTGRES_NON_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = "postgres-secret"
                key  = "POSTGRES_NON_ROOT_PASSWORD"
              }
            }
          }

          env {
            name  = "POSTGRES_HOST"
            value = "postgres-service"
          }

          env {
            name  = "POSTGRES_PORT"
            value = "5432"
          }
        }

        volume {
          name = "postgres-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgresql_persistent_volume_claim.metadata[0].name
          }
        }

        volume {
          name = "init-data"
          config_map {
            name          = "init-data"
            default_mode  = "0744"
          }
        }

        restart_policy = "Always"
      }
    }
  }
}
