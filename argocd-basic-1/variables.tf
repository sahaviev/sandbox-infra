variable "kubeconfig_path" {
  description = "Path to kubeconfig file for Kubernetes cluster"
  type        = string
  default     = "~/.kube/config"
}
