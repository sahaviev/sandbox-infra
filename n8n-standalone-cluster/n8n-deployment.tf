resource "kubernetes_deployment" "n8n_deployment" {
  metadata {
    name      = "n8n-deployment"
    namespace = "n8n-namespace"
    labels = {
      service = "n8n"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        service = "n8n"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          service = "n8n"
        }
      }

      spec {
        init_container {
          name    = "volume-permissions"
          image   = "busybox:1.36"
          command = ["sh", "-c", "chown 1000:1000 /data"]

          volume_mount {
            name       = "n8n-data"
            mount_path = "/data"
          }
        }

        container {
          name    = "n8n"
          image   = "n8nio/n8n"
          command = ["/bin/sh"]
          args    = ["-c", "sleep 5; n8n start"]

          port {
            container_port = 5678
          }

          resources {
            requests = {
              memory = "500Mi"
            }
            limits = {
              memory = "1Gi"
            }
          }

          env {
            name  = "DB_TYPE"
            value = "postgresdb"
          }

          env {
            name  = "DB_POSTGRESDB_HOST"
            value = "postgres-service.n8n-namespace.svc.cluster.local"
          }

          env {
            name  = "DB_POSTGRESDB_PORT"
            value = "5432"
          }

          env {
            name  = "DB_POSTGRESDB_DATABASE"
            value = "n8n"
          }

          env {
            name = "DB_POSTGRESDB_USER"
            value_from {
              secret_key_ref {
                name = "postgres-secret"
                key  = "POSTGRES_NON_ROOT_USER"
              }
            }
          }

          env {
            name = "DB_POSTGRESDB_PASSWORD"
            value_from {
              secret_key_ref {
                name = "postgres-secret"
                key  = "POSTGRES_NON_ROOT_PASSWORD"
              }
            }
          }

          env {
            name  = "N8N_PROTOCOL"
            value = "http"
          }

          env {
            name  = "N8N_PORT"
            value = "5678"
          }

          volume_mount {
            name       = "n8n-data"
            mount_path = "/home/node/.n8n"
          }
        }

        volume {
          name = "n8n-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.n8n_persistent_volume_claim.metadata[0].name
          }
        }

        volume {
          name = "n8n-secret"
          secret {
            secret_name = "n8n-secret"
          }
        }

        volume {
          name = "postgres-secret"
          secret {
            secret_name = "postgres-secret"
          }
        }

        restart_policy = "Always"
      }
    }
  }
}
