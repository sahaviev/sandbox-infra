resource "kubernetes_secret" "n8n_secret" {
  metadata {
    name      = "n8n-secret"
    namespace = kubernetes_namespace.n8n_namespace.metadata[0].name
  }

  type = "Opaque"

  data = {
    N8N_ENCRYPTION_KEY              = "d4PuNg3v6MwMxKkjfMiSj8GDo58ipjAW"
  }
}
