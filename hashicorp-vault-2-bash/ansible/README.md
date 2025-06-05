# Vault Ansible Playbooks

This directory contains [Ansible](https://www.ansible.com/) playbooks for managing HashiCorp Vault in Kubernetes.

## Playbooks

### `vault-init.yml`
Initializes Vault if it's not already initialized. The playbook:
- Checks current Vault status
- Initializes Vault if needed
- Saves initialization output (including unseal keys and root token) to specified data directory
- Validates initialization was successful

### `vault-unseal.yml`
Unseals Vault using the keys from initialization. The playbook:
- Reads unseal keys from `vault-init.json`
- Checks if pod is ready and Vault is initialized
- Uses the first 3 unseal keys to unseal Vault
- Verifies unsealing was successful

## Usage

Both playbooks support custom parameters:

```bash
# Initialize with custom parameters
ansible-playbook vault-init.yml \
  -e "namespace=my-vault-namespace" \
  -e "vault_pod=vault-0" \
  -e "data_dir=/path/to/data"

# Unseal specific pod with custom parameters
ansible-playbook vault-unseal.yml \
  -e "namespace=my-vault-namespace" \
  -e "vault_pod=vault-1" \
  -e "data_dir=/path/to/data"
```

### Full Cluster Setup

For a complete Vault HA cluster:

1. **Initialize once** (only on one pod):
   ```bash
   ansible-playbook vault-init.yml -e "vault_pod=vault-0"
   ```

2. **Unseal all pods** in the cluster:
   ```bash
   # Unseal vault-0
   ansible-playbook vault-unseal.yml -e "vault_pod=vault-0"
   
   # Unseal vault-1
   ansible-playbook vault-unseal.yml -e "vault_pod=vault-1"
   
   # Unseal vault-2
   ansible-playbook vault-unseal.yml -e "vault_pod=vault-2"
   ```

### Supported Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `namespace` | Kubernetes namespace | `vault-namespace` | No |
| `vault_pod` | Target Vault pod name | `vault-0` | No |
| `data_dir` | Directory for storing init file | `./data` | No |

## Prerequisites

- Kubernetes cluster with Vault deployed in HA mode
- `kubectl` configured and accessible
- Ansible installed
- `jq` utility for JSON processing
- Vault pods must be running and ready

## Troubleshooting

### Common Issues

**Init file not found:**
```bash
# Ensure data directory exists and has correct permissions
mkdir -p ./data
chmod 700 ./data
```

**Pod not ready:**
```bash
# Check pod status
kubectl get pods -n vault-namespace
kubectl describe pod vault-0 -n vault-namespace
```

**Unsealing fails:**
```bash
# Verify init file exists and is valid
ls -la data/vault-init.json
jq . data/vault-init.json

# Check Vault status
kubectl exec -n vault-namespace vault-0 -- vault status
```

## Security Note

⚠️ **Important Security Notes:**

- **Init file contains sensitive data** (unseal keys and root token)
- **File permissions** are automatically set to 600 (owner read/write only)
- **Never commit** `vault-init.json` to version control
- **For production:** Consider using external secret management for unseal keys
- **Access control:** Limit who can execute these playbooks

## Author

**Rail Sakhaviev**  
📧 Email: rail.sakhaviev@gmail.com  
🐙 GitHub: [@sahaviev](https://github.com/sahaviev)  
📱 Telegram: [@sahaviev](https://t.me/sahaviev)  
💼 LinkedIn: [Rail Sakhaviev](https://linkedin.com/in/rail.sakhaviev)

## License

MIT License - see [LICENSE](../../LICENSE.md) file for details.
