# Vault Terraform Module

[Terraform](https://terraform.io/) module for deploying HashiCorp Vault on Kubernetes using Helm.

## Features

- 🚀 Deploys Vault cluster using official HashiCorp Helm chart
- 🔧 Configurable storage, ingress, and cluster settings
- 📊 Comprehensive outputs with management commands
- 🎯 Production-ready defaults

## Usage

```hcl
module "vault" {
  source = "./vault-terraform"

  namespace           = "vault"
  vault_chart_version = "0.27.0"
  vault_image_tag     = "1.15.2"
  storage_size        = "20Gi"
  storage_class       = "gp2"
  ingress_enabled     = true
  ingress_hostname    = "vault.yourdomain.com"
}
```

## Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `namespace` | Kubernetes namespace for Vault | `string` | `"vault-namespace"` |
| `vault_chart_version` | Version of HashiCorp Vault Helm chart | `string` | `"0.27.0"` |
| `vault_image_tag` | Vault Docker image tag | `string` | `"1.15.2"` |
| `storage_class` | Storage class for Vault data | `string` | `"standard"` |
| `storage_size` | Storage size for each Vault instance | `string` | `"10Gi"` |
| `ingress_enabled` | Enable ingress for Vault | `bool` | `true` |
| `ingress_hostname` | Hostname for Vault ingress | `string` | `"vault.local"` |

## Outputs

- `vault_service_name` - Name of the Vault service
- `vault_namespace` - Namespace where Vault is deployed
- `vault_ui_service` - Vault UI service name
- `helm_release_status` - Status of the Helm release
- `initialization_commands` - Complete setup commands for Vault cluster
- `terraform_values_example` - Example terraform.tfvars configuration

## Quick Start

1. **Deploy infrastructure:**
   ```bash
   terraform init
   terraform apply
   ```

2. **Initialize and unseal Vault:**
   ```bash
   # Use the commands from terraform output
   terraform output -raw initialization_commands
   ```

3. **Access Vault UI:**
   ```bash
   # Port-forward method
   kubectl port-forward -n vault svc/vault 8200:8200
   
   # Or use ingress (if enabled)
   open http://vault.yourdomain.com
   ```

## Prerequisites

- Terraform >= 1.0
- Kubernetes cluster
- `kubectl` configured and accessible
- Helm provider permissions

## Important Notes

⚠️ **Security:** The module outputs include complete initialization commands with examples for managing vault keys and tokens. Always store these securely!

🔧 **Customization:** Create a `vault-values.yaml` file in the module directory to customize Helm chart values beyond the provided variables.

## File Structure

```
vault-terraform/
├── main.tf              # Main Vault resources
├── variables.tf         # Input variables
├── outputs.tf          # Module outputs
├── versions.tf         # Provider requirements
└── vault-values.yaml   # Helm chart values template
```

## Author

**Rail Sakhaviev**  
📧 Email: rail.sakhaviev@gmail.com  
🐙 GitHub: [@sahaviev](https://github.com/sahaviev)  
📱 Telegram: [@sahaviev](https://t.me/sahaviev)  
💼 LinkedIn: [Rail Sakhaviev](https://linkedin.com/in/rail.sakhaviev)

## License

MIT License - see [LICENSE](LICENSE) file for details.