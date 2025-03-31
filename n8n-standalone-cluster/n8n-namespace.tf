resource "kubernetes_namespace" "n8n-namespace" {
  metadata {
    name = "n8n-namespace"
    
    labels = {
      environment = "development"
      team        = "platform"
    }
    
    annotations = {
      "created-by" = "terraform"
    }
  }
}
