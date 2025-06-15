# ArgoCD Deployment Example

This example demonstrates how to deploy ArgoCD using the ArgoCD Terraform module with custom user management and RBAC configuration.

📖 **For detailed module documentation, see:** [ArgoCD Module README](./modules/argocd/README.md)

## What's Included

This example sets up:

- 🏗️ **Kubernetes namespace** for ArgoCD with proper labels and annotations
- 🚀 **ArgoCD deployment** using the custom Terraform module
- 👥 **User management** with two users: admin (`rail`) and read-only (`developer`)
- 🔐 **RBAC policies** defining permissions for different roles
- 🌐 **Ingress configuration** for local access via `argocd.local`

## File Structure

```
argocd-example/
├── main.tf         # ArgoCD module configuration
├── namespace.tf    # Kubernetes namespace creation
├── outputs.tf      # Output values from the module
├── providers.tf    # Terraform and provider configurations
└── variables.tf    # Input variables
```

## Quick Start

1. **Initialize Terraform:**
   ```bash
   terraform init
   ```

2. **Deploy ArgoCD:**
   ```bash
   terraform apply
   ```

3. **Get getting started guide:**
   ```bash
   terraform output -raw argocd_getting_started
   ```

## Accessing Sensitive Data

Terraform marks passwords as sensitive for security. Use these commands to view them:

```bash
# Admin password (plain text)
terraform output -raw argocd_admin_password

# All user passwords (JSON format)
terraform output argocd_user_passwords

# Extract specific user password using jq
terraform output -json argocd_user_passwords | jq -r '.USERNAME'

# Example: Get rail's password
terraform output -json argocd_user_passwords | jq -r '.rail'

# Example: Get developer's password  
terraform output -json argocd_user_passwords | jq -r '.developer'
```


## Configuration Details

### Users and Roles

The example creates two users with different access levels:

- **`rail`** - Admin user with full permissions (`login`, `apiKey` capabilities)
- **`developer`** - Read-only user with limited access (`login` capability only)

### RBAC Policies

- **`admin` role** - Full access to applications and repositories
- **`readonly` role** - Read-only access to applications and repositories

## Prerequisites

- Terraform >= 1.0
- Kubernetes cluster with NGINX ingress controller
- cert-manager installed for TLS certificates
- `kubectl` configured and accessible

## Customization

To customize the deployment, modify:

- **Namespace**: Change namespace name in `namespace.tf`
- **Users**: Add/modify users in `argocd_users` block in `main.tf`
- **Roles**: Adjust RBAC policies in `argocd_roles` block in `main.tf`
- **Ingress**: Update `ingress_hostname` for different domain

## Author

**Rail Sakhaviev**  
📧 Email: rail.sakhaviev@gmail.com  
🐙 GitHub: [@sahaviev](https://github.com/sahaviev)  
📱 Telegram: [@sahaviev](https://t.me/sahaviev)  
💼 LinkedIn: [Rail Sakhaviev](https://www.linkedin.com/in/rail-sakhaviev/)
