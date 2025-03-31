resource "kubernetes_persistent_volume" "n8n_persistent_volume" {
  metadata {
    name = "n8n-persistent-volume"
  }
  spec {
    capacity = {
      storage = "5Gi"
    }
    volume_mode = "Filesystem"
    access_modes = ["ReadWriteOnce"]
    storage_class_name = kubernetes_storage_class.cluster_storage_class.metadata[0].name
    persistent_volume_source {
      host_path {
        path = "/home/n8n-data"
      }
    }
  }
}
