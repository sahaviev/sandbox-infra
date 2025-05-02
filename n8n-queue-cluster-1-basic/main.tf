module "postgres_n8n" {
  source             = "./modules/postgres"

  name_prefix        = "postgres"
  namespace          = kubernetes_namespace.n8n_namespace.metadata[0].name
  storage_class_name = kubernetes_storage_class.cluster_storage_class.metadata[0].name
  storage_size       = "5Gi"
  init_script_path   = "./init-data.sh"
  postgres_port      = "5432"
  env_vars           = {
    "POSTGRES_USER"               = kubernetes_secret.postgres_secret.data["POSTGRES_USER"]
    "POSTGRES_PASSWORD"           = kubernetes_secret.postgres_secret.data["POSTGRES_PASSWORD"]
    "POSTGRES_NON_ROOT_USER"      = kubernetes_secret.postgres_secret.data["POSTGRES_NON_ROOT_USER"]
    "POSTGRES_NON_ROOT_PASSWORD"  = kubernetes_secret.postgres_secret.data["POSTGRES_NON_ROOT_PASSWORD"]
    "POSTGRES_DB"                 = kubernetes_secret.postgres_secret.data["POSTGRES_DB"]
  }
}

module "n8n_main" {
  source = "./modules/n8n"
  
  name_prefix        = "n8n-main"
  namespace          = kubernetes_namespace.n8n_namespace.metadata[0].name
  storage_class_name = kubernetes_storage_class.cluster_storage_class.metadata[0].name
  storage_size       = "5Gi"
  resource_requests = {
    memory = "1Gi"
  }
  resource_limits = {
    memory = "2Gi"
  }

  env_vars = {
    "N8N_PORT"                              = "5678"
    "N8N_PROTOCOL"                          = "http"
    "EXECUTIONS_MODE"                       = "queue"
    "QUEUE_BULL_REDIS_HOST"                 = module.redis_n8n.redis_host
    "QUEUE_BULL_REDIS_PORT"                 = module.redis_n8n.redis_port
    "N8N_ENCRYPTION_KEY"                    = kubernetes_secret.n8n_secret.data["N8N_ENCRYPTION_KEY"]
    "OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS"  = "true"
    "N8N_RUNNERS_MODE"                      = "external"
    "DB_TYPE"                               = "postgresdb"
    "DB_POSTGRESDB_HOST"                    = module.postgres_n8n.postgres_host
    "DB_POSTGRESDB_PORT"                    = module.postgres_n8n.postgres_port
    "DB_POSTGRESDB_USER"                    = kubernetes_secret.postgres_secret.data["POSTGRES_NON_ROOT_USER"]
    "DB_POSTGRESDB_PASSWORD"                = kubernetes_secret.postgres_secret.data["POSTGRES_NON_ROOT_PASSWORD"]
    "DB_POSTGRESDB_DATABASE"                = kubernetes_secret.postgres_secret.data["POSTGRES_DB"]
  }
}

module "n8n_worker" {
  source = "./modules/n8n"
  
  replicas           = 2
  name_prefix        = "n8n-worker"
  mode               = "worker"
  namespace          = kubernetes_namespace.n8n_namespace.metadata[0].name
  storage_class_name = kubernetes_storage_class.cluster_storage_class.metadata[0].name
  storage_size       = "5Gi"
  resource_requests = {
    memory = "1Gi"
  }
  resource_limits = {
    memory = "1.5Gi"
  }
  env_vars           = {
    "N8N_PORT"                              = "5678"
    "N8N_PROTOCOL"                          = "http"
    "EXECUTIONS_MODE"                       = "queue"
    "QUEUE_BULL_REDIS_HOST"                 = module.redis_n8n.redis_host
    "QUEUE_BULL_REDIS_PORT"                 = module.redis_n8n.redis_port
    "N8N_ENCRYPTION_KEY"                    = kubernetes_secret.n8n_secret.data["N8N_ENCRYPTION_KEY"]
    "OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS"  = "true"
    "NODE_OPTIONS"                          = "--max-old-space-size=768"
    "DB_TYPE"                               = "postgresdb"
    "DB_POSTGRESDB_HOST"                    = module.postgres_n8n.postgres_host
    "DB_POSTGRESDB_PORT"                    = module.postgres_n8n.postgres_port
    "DB_POSTGRESDB_USER"                    = kubernetes_secret.postgres_secret.data["POSTGRES_NON_ROOT_USER"]
    "DB_POSTGRESDB_PASSWORD"                = kubernetes_secret.postgres_secret.data["POSTGRES_NON_ROOT_PASSWORD"]
    "DB_POSTGRESDB_DATABASE"                = kubernetes_secret.postgres_secret.data["POSTGRES_DB"]
  }
}

module "redis_n8n" {
  source = "./modules/redis"

  name_prefix        = "redis"
  namespace          = kubernetes_namespace.n8n_namespace.metadata[0].name
  storage_class_name = kubernetes_storage_class.cluster_storage_class.metadata[0].name
  redis_image        = "redis:7.0"
  storage_size       = "2Gi"
  resource_requests = {
    cpu    = "200m"
    memory = "256Mi"
  }
  resource_limits = {
    cpu    = "1000m"
    memory = "1Gi"
  }
}

output "postgres_n8n" {
  value = module.postgres_n8n
}

output "redis_n8n" {
  value = module.redis_n8n
}

output "n8n_main" {
  value = module.n8n_main
}
