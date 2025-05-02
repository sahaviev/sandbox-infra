variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "redis"
}

variable "namespace" {
  description = "Kubernetes namespace to deploy resources in"
  type        = string
  default     = "redis-namespace"
}

variable "redis_image" {
  description = "Redis Docker image to use"
  type        = string
  default     = "redis:latest"
}

variable "replicas" {
  description = "Number of Redis replicas"
  type        = number
  default     = 1
}

variable "storage_size" {
  description = "Size of the persistent volume"
  type        = string
  default     = "1Gi"
}

variable "storage_class_name" {
  description = "Storage class name for the persistent volume"
  type        = string
}

variable "host_path" {
  description = "Host path for the persistent volume"
  type        = string
  default     = "/home/redis-data"
}

variable "resource_limits" {
  description = "Resource limits for Redis container"
  type        = object({
    cpu    = string
    memory = string
  })
  default     = {
    cpu    = "500m"
    memory = "512Mi"
  }
}

variable "resource_requests" {
  description = "Resource requests for Redis container"
  type        = object({
    cpu    = string
    memory = string
  })
  default     = {
    cpu    = "100m"
    memory = "128Mi"
  }
}

variable "labels" {
  description = "Additional labels for resources"
  type        = map(string)
  default     = {}
}
