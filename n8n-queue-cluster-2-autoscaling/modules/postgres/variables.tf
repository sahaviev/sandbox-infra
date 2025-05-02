variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "postgres"
}

variable "namespace" {
  description = "Kubernetes namespace to deploy resources in"
  type        = string
  default     = "postgres-namespace"
}

variable "storage_size" {
  description = "Size of persistent volume"
  type        = string
  default     = "5Gi"
}

variable "host_path" {
  description = "Host path for persistent volume"
  type        = string
  default     = "/home/postgres-data"
}

variable "postgres_port" {
  description = "Port for PostgreSQL"
  type        = number
  default     = 5432
}


variable "database_name" {
  description = "Name of the default database to create"
  type        = string
  default     = "custom-database"
}

variable "postgres_image" {
  description = "PostgreSQL Docker image to use"
  type        = string
  default     = "postgres:11"
}

variable "resource_requests" {
  description = "Resource requests for PostgreSQL container"
  type        = object({
    cpu    = optional(string)
    memory = string
  })
  default     = {
    memory = "1Gi"
  }
}

variable "resource_limits" {
  description = "Resource limits for PostgreSQL container"
  type        = object({
    cpu    = optional(string)
    memory = string
  })
  default     = {
    memory = "2Gi"
  }
}

variable "storage_class_name" {
  description = "Storage class name"
  type        = string
}

variable "init_script_path" {
  description = "Path to the initialization script"
  type        = string
  default     = null
}

variable "labels" {
  description = "Additional labels for resources"
  type        = map(string)
  default     = {}
}

variable "env_vars" {
  description = "Map of environment variables with plain text values"
  type        = map(string)
  default     = {}
}
