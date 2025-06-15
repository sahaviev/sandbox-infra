# ArgoCD Terraform Module

[Terraform](https://terraform.io/) module for deploying ArgoCD on Kubernetes using Helm.

## Features

- 🚀 Deploys ArgoCD using official Argo Helm chart
- 👥 User and role management with RBAC policies
- 🔐 Automatic password generation for users
- 🌐 Configurable ingress with TLS certificates
- 📊 Comprehensive outputs with getting started commands

## Usage

```hcl
module "argocd" {
  source = "./modules/argocd"

  namespace = kubernetes_namespace.argocd.metadata[0].name
  ingress_enabled = true
  ingress_hostname   = "argocd.local"

  argocd_users = {
    "rail" = {
      capabilities = ["login", "apiKey"]
      role = "admin"
    }
    "developer" = {
      capabilities = ["login"]
      role = "readonly"
    }
  }

  argocd_roles = {
    "readonly" = {
      policies = [
        "p, role:readonly, applications, get, */*, allow",
        "p, role:readonly, repositories, get, */*, allow"
      ]
    }
    "admin" = {
      policies = [
        "p, role:admin, applications, *, */*, allow",
        "p, role:admin, repositories, *, */*, allow"
      ]
    }
  }

  providers = {
    helm = helm
    kubectl = kubectl
  }

  depends_on = [kubernetes_namespace.argocd]
}
```

## Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `namespace` | Namespace for ArgoCD deployment | `string` | `"argocd-namespace"` |
| `chart_version` | ArgoCD Helm chart version | `string` | `"5.51.6"` |
| `admin_password` | Admin password for ArgoCD (leave empty for auto-generated) | `string` | `""` |
| `ingress_enabled` | Enable ingress for ArgoCD server | `bool` | `true` |
| `ingress_hostname` | Hostname for ArgoCD server ingress | `string` | `"argocd.local"` |
| `argocd_users` | Map of ArgoCD users with their capabilities and role | `map(object)` | `{}` |
| `argocd_roles` | Map of ArgoCD roles with their policies | `map(object)` | `{}` |

## Outputs

- `argocd_server_url` - ArgoCD Server URL or port-forward command
- `argocd_namespace` - ArgoCD deployment namespace
- `argocd_admin_username` - ArgoCD admin username (always "admin")
- `argocd_admin_password` - ArgoCD admin password (sensitive)
- `argocd_user_passwords` - Generated passwords for additional users (sensitive)
- `getting_started` - Complete getting started guide with all commands

## Quick Start

1. **Deploy ArgoCD:**
   ```bash
   terraform init
   terraform apply
   ```

2. **Access ArgoCD UI:**
   ```bash
   # Use the complete getting started guide
   terraform output -raw getting_started
   
   # Quick access via port-forward
   kubectl port-forward svc/argocd-server -n argocd-namespace 8080:443
   ```

3. **Get admin password:**
   ```bash
   terraform output -raw argocd_admin_password
   ```

4. **Login to ArgoCD:**
   ```bash
   # Via browser: https://argocd.local
   ```

## Prerequisites

- Terraform >= 1.0
- Kubernetes cluster with NGINX ingress controller
- cert-manager installed for TLS certificates
- `kubectl` configured and accessible
- Helm provider permissions

## Important Notes

⚠️ **Security:** User passwords are automatically generated and stored in Terraform state. Always secure your state files!

🔐 **TLS Certificates:** The module creates certificates using cert-manager with `ca-cluster-issuer`. Ensure cert-manager is properly configured.

🌐 **Ingress:** For local development, add the ingress hostname to your `/etc/hosts` file pointing to your cluster IP.

📝 **RBAC:** The module supports flexible RBAC configuration through roles and policies. Customize the `argocd_roles` variable to define your access control.

## File Structure

```
argocd-terraform/
├── main.tf              # Main ArgoCD Helm release
├── variables.tf         # Input variables
├── outputs.tf          # Module outputs
├── certificate.tf      # TLS certificate resource
└── user-passwords.tf   # User password generation
```

## User Management

The module supports creating additional ArgoCD users with specific capabilities and roles:

### User Capabilities
- `login` - Allow user to login via UI/CLI
- `apiKey` - Allow user to generate API keys

### Example User Creation
```hcl
argocd_users = {
  # Admin user with full capabilities
  "rail" = {
    capabilities = ["login", "apiKey"]  # Can login and generate API keys
    role = "admin"                      # Assigned to admin role
  }
  
  # Developer with read-only access
  "developer" = {
    capabilities = ["login"]            # Can only login via UI/CLI
    role = "readonly"                   # Assigned to readonly role
  }
  
  # DevOps engineer with sync permissions
  "devops" = {
    capabilities = ["login", "apiKey"]
    role = "deployer"
    enabled = true                      # Explicitly enabled (optional)
  }
}

argocd_roles = {
  # Role definitions with RBAC policies
  "readonly" = {
    policies = [
      "p, role:readonly, applications, get, */*, allow",
      "p, role:readonly, repositories, get, */*, allow"
    ]
  }
  
  "deployer" = {
    policies = [
      "p, role:deployer, applications, get, */*, allow",
      "p, role:deployer, applications, sync, */*, allow",
      "p, role:deployer, applications, action/*, */*, allow"
    ]
  }
  
  "admin" = {
    policies = [
      "p, role:admin, applications, *, */*, allow",
      "p, role:admin, repositories, *, */*, allow",
      "p, role:admin, clusters, *, *, allow"
    ]
  }
}
```

### Example RBAC Policies
```hcl
# Read-only access to all applications
"p, role:readonly, applications, get, */*, allow"

# Sync permissions for specific project
"p, role:developer, applications, sync, myproject/*, allow"

# Full application management in specific namespace
"p, role:developer, applications, *, default/*, allow"

# Repository management
"p, role:admin, repositories, *, */*, allow"

# Cluster administration
"p, role:admin, clusters, *, *, allow"

# Certificate management
"p, role:admin, certificates, *, *, allow"
```


## Author

**Rail Sakhaviev**  
📧 Email: rail.sakhaviev@gmail.com  
🐙 GitHub: [@sahaviev](https://github.com/sahaviev)  
📱 Telegram: [@sahaviev](https://t.me/sahaviev)  
💼 LinkedIn: [Rail Sakhaviev](https://www.linkedin.com/in/rail-sakhaviev/)

## License

MIT License - see [LICENSE](../../../LICENSE.md) file for details.
