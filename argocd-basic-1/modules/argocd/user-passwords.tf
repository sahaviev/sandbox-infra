resource "random_password" "user_passwords" {
  for_each = var.argocd_users

  length  = 16
  special = true
}
