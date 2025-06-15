# cert-manager Deployment

[Terraform](https://terraform.io/) configuration for deploying cert-manager on Kubernetes with self-signed CA setup for local development.

## Features

- 🔐 Deploys cert-manager using official Jetstack Helm chart
- 🏗️ Automatically creates cluster-wide certificate issuers
- 📜 Sets up self-signed CA for local development certificates
- ⚡ Ready-to-use certificate infrastructure

## What's Included

This deployment sets up:

- **cert-manager** - Core certificate management controller
- **selfsigned-cluster-issuer** - Basic self-signed certificate issuer
- **ca-cluster-issuer** - CA-signed certificate issuer (recommended for applications)
- **Self-signed CA certificate** - Root CA for signing application certificates

## Usage

```hcl
# Deploy cert-manager
terraform init
terraform apply
```

## Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `kubeconfig_path` | Path to kubeconfig file for Kubernetes cluster | `string` | `"~/.kube/config"` |
| `cert_manager_version` | cert-manager Helm chart version | `string` | `"v1.13.3"` |

## Outputs

- `cluster_issuers` - Available ClusterIssuers with descriptions
- `ca_certificate_command` - Command to extract CA certificate for browser trust

## Quick Start

1. **Deploy cert-manager:**
   ```bash
   terraform init
   terraform apply
   ```

2. **View available issuers:**
   ```bash
   terraform output cluster_issuers
   ```

3. **Extract CA certificate for browser trust:**
   ```bash
   # Get the command from Terraform output
   terraform output -raw ca_certificate_command
   
   # Run the command to save CA certificate
   kubectl get secret selfsigned-ca-secret -n cert-manager -o jsonpath='{.data.tls\.crt}' | base64 -d > local-ca.crt
   ```

4. **Import CA certificate to your browser/system trust store**

## Using Certificate Issuers

After deployment, you can create certificates using the configured issuers:

### Example: Create a certificate for your application

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
   name: my-app-tls
   namespace: my-namespace
spec:
   secretName: my-app-tls
   duration: 2160h # 90 days
   renewBefore: 360h # 15 days
   commonName: my-app.local
   dnsNames:
      - my-app.local
      - localhost
   ipAddresses:
      - 127.0.0.1
   issuerRef:
      name: ca-cluster-issuer
      kind: ClusterIssuer
      group: cert-manager.io
```

### Example: Integration with ArgoCD (Real-world usage)

```hcl
# ArgoCD TLS Certificate using cert-manager
resource "kubectl_manifest" "argocd_certificate" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: argocd-server-tls
  namespace: ${var.namespace}
spec:
  secretName: argocd-server-tls
  duration: 2160h # 90 days
  renewBefore: 360h # 15 days
  commonName: ${var.ingress_hostname}
  dnsNames:
  - ${var.ingress_hostname}
  - localhost
  ipAddresses:
  - 127.0.0.1
  issuerRef:
    name: ca-cluster-issuer
    kind: ClusterIssuer
    group: cert-manager.io
YAML
}
```

## Prerequisites

- Terraform >= 1.0
- Kubernetes cluster
- `kubectl` configured and accessible
- Helm provider permissions

## Important Notes

🔐 **Local Development:** This setup creates a self-signed CA perfect for local development and testing environments.

⚠️ **Production Use:** For production environments, consider using Let's Encrypt or your organization's CA instead of self-signed certificates.

🌐 **Browser Trust:** To avoid browser security warnings, import the generated `local-ca.crt` into your browser's trusted certificate authorities.

## File Structure

```
cert-manager/
├── main.tf         # Main cert-manager resources
├── variables.tf    # Input variables
├── outputs.tf      # Module outputs
└── providers.tf    # Provider requirements
```

## Verification

After deployment, verify cert-manager is working:

```bash
# Check cert-manager pods
kubectl get pods -n cert-manager

# List available ClusterIssuers
kubectl get clusterissuers

# Check CA certificate
kubectl get certificate selfsigned-ca -n cert-manager

# View CA certificate details
kubectl describe certificate selfsigned-ca -n cert-manager
```

## Author

**Rail Sakhaviev**  
📧 Email: rail.sakhaviev@gmail.com  
🐙 GitHub: [@sahaviev](https://github.com/sahaviev)  
📱 Telegram: [@sahaviev](https://t.me/sahaviev)  
💼 LinkedIn: [Rail Sakhaviev](https://www.linkedin.com/in/rail-sakhaviev/)

## License

MIT License - see [LICENSE](../LICENSE.md) file for details.