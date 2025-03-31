resource "kubernetes_config_map" "init_data" {
  metadata {
    name      = "init-data"
    namespace = "n8n-namespace"
  }

  data = {
    "init-data.sh" = file("${path.module}/init-data.sh")
  }
}
