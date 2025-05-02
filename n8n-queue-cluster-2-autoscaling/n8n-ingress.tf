resource "kubernetes_ingress_v1" "n8n_ingress" {
  metadata {
    name      = "n8n-ingress"
    namespace = kubernetes_namespace.n8n_namespace.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                = "nginx"
      "cert-manager.io/cluster-issuer"             = "letsencrypt-prod"
    }
  }

  spec {
    rule {
      host = local.host
      http {
        path {
          path      = "/webhook"
          path_type = "Prefix"
          backend {
            service {
              name = module.n8n_webhook.n8n_service.metadata[0].name
              port {
                number = local.n8n_port
              }
            }
          }
        }
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = module.n8n_main.n8n_service.metadata[0].name
              port {
                number = local.n8n_port
              }
            }
          }
        }
      }
    }
  }
}
