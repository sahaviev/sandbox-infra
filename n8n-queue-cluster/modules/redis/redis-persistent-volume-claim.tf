resource "kubernetes_persistent_volume_claim" "redis_persistent_volume_claim" {
  metadata {
    name      = "${var.name_prefix}-persistent-volume-claim"
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.storage_size
      }
    }
    storage_class_name = var.storage_class_name
    volume_name        = kubernetes_persistent_volume.redis_persistent_volume.metadata[0].name
  }
}
