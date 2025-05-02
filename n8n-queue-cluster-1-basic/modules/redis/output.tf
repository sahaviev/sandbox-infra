output "redis_host" {
  value = "${kubernetes_service.redis_service.metadata.0.name}.${kubernetes_service.redis_service.metadata.0.namespace}.svc.cluster.local"
  description = "Redis-service DNS-address inside cluster"
}

output "redis_port" {
  value = kubernetes_service.redis_service.spec[0].port[0].port
  description = "Redis-service port"
}

