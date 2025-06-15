
variable "namespace" {
  description = "Namespace for ArgoCD deployment"
  type        = string
  default     = "argocd-namespace"
}

variable "chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "5.51.6"
}

variable "admin_password" {
  description = "Admin password for ArgoCD (leave empty for auto-generated)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ingress_enabled" {
  description = "Enable ingress for ArgoCD server"
  type        = bool
  default     = true
}

variable "ingress_hostname" {
  description = "Hostname for ArgoCD server ingress"
  type        = string
  default     = "argocd.local"
}

variable "argocd_users" {
  description = "Map of ArgoCD users with their capabilities and role"
  type = map(object({
    capabilities = list(string)
    role         = string
    enabled      = optional(bool, true)
  }))
  default = {}
}

variable "argocd_roles" {
  description = "Map of ArgoCD roles with their policies"
  type = map(object({
    policies = list(string)
  }))
  default = {}
}
