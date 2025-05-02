variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "n8n"
}

variable "namespace" {
  description = "Kubernetes namespace to deploy resources in"
  type        = string
  default     = "n8n-namespace"
}

variable "storage_size" {
  description = "Size of persistent volume"
  type        = string
  default     = "5Gi"
}

variable "host_path" {
  description = "Host path for persistent volume"
  type        = string
  default     = "/home/n8n-data"
}

variable "mode" {
  description = "N8N mode: 'start' for regular mode, 'worker' for worker mode, 'webhook' for webhook mode"
  type        = string
  default     = "start"
  validation {
    condition     = contains(["start", "worker", "webhook"], var.mode)
    error_message = "Mode must be either 'start', 'worker' and 'webhook'."
  }
}

variable "n8n_secret" {
  description = "Kubernetes secret name containing n8n credentials"
  type        = string
  default     = "n8n-secret"
}

variable "resource_requests" {
  description = "Resource requests for n8n container"
  type        = object({
    cpu    = optional(string)
    memory = string
  })
  default     = {
    memory = "500Mi"
  }
}

variable "resource_limits" {
  description = "Resource limits for n8n container"
  type        = object({
    cpu    = optional(string)
    memory = string
  })
  default     = {
    memory = "1Gi"
  }
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 1
}

variable "enable_autoscaling" {
  description = "Whether to enable autoscaling for deployment"
  type        = bool
  default     = false
}

variable "autoscaling" {
  description = "Autoscaling configuration for deployment"
  type = object({
    min_replicas                      = number
    max_replicas                      = number
    target_cpu_utilization_percentage = number
    target_memory_utilization_percentage = number
  })
  default = {
    min_replicas                      = 1
    max_replicas                      = 2
    target_cpu_utilization_percentage = 80
    target_memory_utilization_percentage = 80
  }
}

variable "storage_class_name" {
  description = "Storage class name"
  type        = string
}

variable "env_vars" {
  description = "Map of environment variables with plain text values"
  type        = map(string)
  default     = {}
}
