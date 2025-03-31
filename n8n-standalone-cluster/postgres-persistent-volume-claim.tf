resource "kubernetes_persistent_volume_claim" "postgresql_persistent_volume_claim" {
  metadata {
    name      = "postgres-persistent-volume-claim"
    namespace = "n8n-namespace"
  }
  
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    storage_class_name = kubernetes_storage_class.cluster_storage_class.metadata[0].name
    volume_name = kubernetes_persistent_volume.postgres_persistent_volume.metadata[0].name
  }
}
