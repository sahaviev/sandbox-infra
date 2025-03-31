output "n8n_host" {
  value = "${kubernetes_service.n8n_service.metadata.0.name}.${kubernetes_service.n8n_service.metadata.0.namespace}.svc.cluster.local"
  description = "n8n DNS-address inside cluster"
}

output "n8n_port" {
  value = kubernetes_service.n8n_service.spec[0].port[0].port
  description = "n8n port"
}
