output "argocd_namespace" {
  value = module.argocd.argocd_namespace
}

output "argocd_admin_password" {
  value = module.argocd.argocd_admin_password
  sensitive = true
}

output "argocd_admin_username" {
  value = module.argocd.argocd_admin_username
}

output "argocd_user_passwords" {
  value = module.argocd.argocd_user_passwords
  sensitive = true
}

output "argocd_getting_started" {
  value = module.argocd.getting_started
}
