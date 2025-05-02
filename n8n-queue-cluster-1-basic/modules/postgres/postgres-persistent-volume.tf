resource "kubernetes_persistent_volume" "postgres_persistent_volume" {
  metadata {
    name = "${var.name_prefix}-persistent-volume"
  }
  spec {
    capacity = {
      storage = var.storage_size
    }
    volume_mode = "Filesystem"
    access_modes = ["ReadWriteOnce"]
    storage_class_name = var.storage_class_name
    persistent_volume_source {
      host_path {
        path = var.host_path
      }
    }
  }
}
