resource "kubernetes_config_map" "postgres_init_data_config_map" {
  metadata {
    name      = "${var.name_prefix}-init-data"
    namespace = var.namespace
  }

  data = {
    "init-data.sh" = var.init_script_path != null ? file(var.init_script_path) : ""
  }
}
