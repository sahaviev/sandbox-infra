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
  description = "N8N mode: 'start' for regular mode, 'worker' for worker mode"
  type        = string
  default     = "start"
  validation {
    condition     = contains(["start", "worker"], var.mode)
    error_message = "Mode must be either 'start' or 'worker'."
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

variable "storage_class_name" {
  description = "Storage class name"
  type        = string
}

variable "env_vars" {
  description = "Map of environment variables with plain text values"
  type        = map(string)
  default     = {}
}
