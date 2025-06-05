variable "namespace" {
  description = "Kubernetes namespace for Vault"
  type        = string
  default     = "vault-namespace"
}

variable "vault_chart_version" {
  description = "Version of HashiCorp Vault Helm chart"
  type        = string
  default     = "0.27.0"
}

variable "vault_image_tag" {
  description = "Vault Docker image tag"
  type        = string
  default     = "1.15.2"
}

variable "vault_replicas" {
  description = "Number of Vault replicas"
  type        = number
  default     = 3
}

variable "storage_class" {
  description = "Storage class for Vault data"
  type        = string
  default     = "standard"
}

variable "storage_size" {
  description = "Storage size for each Vault instance"
  type        = string
  default     = "10Gi"
}

variable "ingress_enabled" {
  description = "Enable ingress for Vault"
  type        = bool
  default     = true
}

variable "ingress_hostname" {
  description = "Hostname for Vault ingress"
  type        = string
  default     = "vault.local"
}
