resource "kubernetes_secret" "postgres_secret" {
  metadata {
    name      = "postgres-secret"
    namespace = "n8n-namespace"
  }

  type = "Opaque"

  data = {
    POSTGRES_USER             = "postgres"
    POSTGRES_PASSWORD         = "123456"
    POSTGRES_DB               = "n8n"
    POSTGRES_NON_ROOT_USER    = "admin"
    POSTGRES_NON_ROOT_PASSWORD = "123456"
  }
}
