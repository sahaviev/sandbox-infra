output "argocd_server_url" {
  description = "ArgoCD Server URL"
  value = var.ingress_enabled ? "https://argocd.local" : "Access via: kubectl port-forward svc/argocd-server -n ${var.namespace} 8080:443"
}

output "argocd_namespace" {
  description = "ArgoCD Namespace"
  value       = var.namespace
}

output "argocd_admin_username" {
  description = "ArgoCD Admin Username"
  value       = "admin"
}

output "argocd_admin_password" {
  description = "ArgoCD Admin Password"
  value       = var.admin_password != "" ? var.admin_password : try(data.kubernetes_secret.argocd_initial_admin_secret.data.password, "Password not available yet")
  sensitive   = true
}

output "argocd_user_passwords" {
  description = "Generated passwords for ArgoCD users"
  value = {
    for username in keys(var.argocd_users) :
    username => random_password.user_passwords[username].result
  }
  sensitive = true
}

output "getting_started" {
  description = "Getting started commands"
  value = <<-EOT
    # Get ArgoCD admin password:
    kubectl -n ${var.namespace} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

    # Add argocd.local to /etc/hosts (for local access):
    echo "$(minikube ip) argocd.local" | sudo tee -a /etc/hosts

    # Access ArgoCD UI via HTTPS:
    https://argocd.local

    # Or port forward to access ArgoCD UI:
    kubectl port-forward svc/argocd-server -n ${var.namespace} 8080:443

    # To trust certificates in browser - get CA cert:
    kubectl get secret selfsigned-ca-secret -n cert-manager -o jsonpath='{.data.tls\.crt}' | base64 -d > argocd-ca.crt
    # Then import argocd-ca.crt to browser trust store

    # Debug commands:
    # Check certificate: kubectl get certificate argocd-server-tls -n ${var.namespace}
    # Check cert-manager: kubectl get pods -n cert-manager
    # Check ingress: kubectl describe ingress argocd-server -n ${var.namespace}
  EOT
}
