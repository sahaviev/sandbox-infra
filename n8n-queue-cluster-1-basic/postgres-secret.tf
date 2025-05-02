resource "kubernetes_secret" "postgres_secret" {
  metadata {
    name      = "postgres-secret"
    namespace = kubernetes_namespace.n8n_namespace.metadata[0].name
  }

  type = "Opaque"

  data = {
    POSTGRES_USER              = "postgres"
    POSTGRES_PASSWORD          = "123456"
    POSTGRES_DB                = "n8n"
    POSTGRES_NON_ROOT_USER     = "admin"
    POSTGRES_NON_ROOT_PASSWORD = "123456"
  }
}
