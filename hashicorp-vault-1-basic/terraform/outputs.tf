
# outputs.tf
output "vault_service_name" {
  description = "Name of the Vault service"
  value       = "${helm_release.vault.name}"
}

output "vault_namespace" {
  description = "Namespace where Vault is deployed"
  value       = var.namespace
}

output "vault_ui_service" {
  description = "Vault UI service name"
  value       = "${helm_release.vault.name}-ui"
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.vault.status
}

output "initialization_commands" {
  description = "Commands to initialize and manage Vault cluster"
  value = <<-EOT
    # 1. Check pod status
    kubectl get pods -n ${var.namespace} -l app.kubernetes.io/name=vault

    # 2. Initialize Vault on the first pod (only once!)
    kubectl exec -n ${var.namespace} vault-0 -- vault operator init \
      -key-shares=5 \
      -key-threshold=3 \
      -format=json > vault-keys.json

    # 3. Extract keys for convenience
    VAULT_UNSEAL_KEY_1=$(cat vault-keys.json | jq -r '.unseal_keys_b64[0]')
    VAULT_UNSEAL_KEY_2=$(cat vault-keys.json | jq -r '.unseal_keys_b64[1]')
    VAULT_UNSEAL_KEY_3=$(cat vault-keys.json | jq -r '.unseal_keys_b64[2]')
    VAULT_ROOT_TOKEN=$(cat vault-keys.json | jq -r '.root_token')

    # 4. Unseal all pods
    for i in 0 1 2; do
      kubectl exec -n ${var.namespace} vault-$i -- vault operator unseal $VAULT_UNSEAL_KEY_1
      kubectl exec -n ${var.namespace} vault-$i -- vault operator unseal $VAULT_UNSEAL_KEY_2
      kubectl exec -n ${var.namespace} vault-$i -- vault operator unseal $VAULT_UNSEAL_KEY_3
    done

    # 5. Check cluster status
    kubectl exec -n ${var.namespace} vault-0 -- vault status
    kubectl exec -n ${var.namespace} vault-0 -- vault operator raft list-peers

    # 6. Login with root token
    kubectl exec -n ${var.namespace} vault-0 -- vault auth $VAULT_ROOT_TOKEN

    # 7. Access Vault UI
    kubectl port-forward -n ${var.namespace} svc/vault 8200:8200
    # Then open http://localhost:8200

    # 8. Or if ingress is enabled
    echo "Vault UI available at: http://${var.ingress_hostname}"

    # 9. Useful management commands
    # List all pods in raft cluster:
    kubectl exec -n ${var.namespace} vault-0 -- vault operator raft list-peers

    # Check leader:
    kubectl exec -n ${var.namespace} vault-0 -- vault status | grep "HA Mode"

    # Remove failed node (if needed):
    # kubectl exec -n ${var.namespace} vault-0 -- vault operator raft remove-peer <node-id>
  EOT
}

output "terraform_values_example" {
  description = "Example terraform.tfvars content"
  value = <<-EOT
    # terraform.tfvars example
    namespace = "vault"
    vault_chart_version = "0.27.0"
    vault_image_tag = "1.15.2"
    storage_class = "gp2"  # or your preferred storage class
    storage_size = "20Gi"
    ingress_enabled = true
    ingress_hostname = "vault.yourdomain.com"
  EOT
}
