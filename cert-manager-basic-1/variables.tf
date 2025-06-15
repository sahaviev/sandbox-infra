variable "kubeconfig_path" {
  description = "Path to kubeconfig file for Kubernetes cluster"
  type        = string
  default     = "~/.kube/config"
}

variable "cert_manager_version" {
  description = "cert-manager Helm chart version"
  type        = string
  default     = "v1.13.3"
}
