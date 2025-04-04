output "postgres_host" {
  value = "${kubernetes_service.postgres_service.metadata[0].name}.${kubernetes_service.postgres_service.metadata[0].namespace}.svc.cluster.local"
  description = "PostgreSQL DNS-address inside cluster"
}

output "postgres_port" {
  value = kubernetes_service.postgres_service.spec[0].port[0].port
  description = "PostgreSQL port"
}
