resource "kubernetes_storage_class" "cluster_storage_class" {
  metadata {
    name = "cluster-storage-class"
  }

  storage_provisioner = "kubernetes.io/no-provisioner"
  volume_binding_mode = "WaitForFirstConsumer"
}
