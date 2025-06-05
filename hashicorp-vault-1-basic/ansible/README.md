# Vault Ansible Basic Playbooks

This directory contains [Ansible](https://www.ansible.com/) playbooks for managing HashiCorp Vault in Kubernetes.

## Playbooks

### `vault-init.yml`
Initializes Vault if it's not already initialized. The playbook:
- Checks current Vault status
- Initializes Vault if needed
- Saves initialization output (including unseal keys and root token) to `vault-init.json`

### `vault-unseal.yml`
Unseals Vault using the keys from initialization. The playbook:
- Reads unseal keys from `vault-init.json`
- Uses the first 3 unseal keys to unseal Vault

## Usage

1. **Initialize Vault:**
   ```bash
   ansible-playbook vault-init.yml
   ```

2. **Unseal Vault:**
   ```bash
   ansible-playbook vault-unseal.yml
   ```

## Configuration

Default configuration:
- **Namespace:** `vault-namespace`
- **Pod:** `vault-0`
- **Init file:** `./vault-init.json`

## Prerequisites

- Kubernetes cluster with Vault deployed
- `kubectl` configured and accessible
- Ansible installed
- Vault pods must be running and ready
- 
## Important Notes

⚠️ **Hardcoded Configuration:** These playbooks are currently hardcoded to work with `vault-0` pod only. For a full Vault cluster setup:

1. **Initialization:** Only needs to be done once (on `vault-0`)
2. **Unsealing:** Must be done for each Vault pod in the cluster
    - Manually update the `vault_pod` variable for each additional pod
    - Run the unseal playbook for `vault-1`, `vault-2`, etc.

Example for additional pods:
```bash
# For vault-1
ansible-playbook vault-unseal.yml -e vault_pod=vault-1

# For vault-2
ansible-playbook vault-unseal.yml -e vault_pod=vault-2
```

## Security Note

Keep `vault-init.json` secure as it contains sensitive unseal keys and root token! 🔒

## Author

**Rail Sakhaviev**  
📧 Email: rail.sakhaviev@gmail.com  
🐙 GitHub: [@sahaviev](https://github.com/sahaviev)  
📱 Telegram: [@sahaviev](https://t.me/sahaviev)  
💼 LinkedIn: [Rail Sakhaviev](https://linkedin.com/in/rail.sakhaviev)

## License

MIT License - see [LICENSE](../../LICENSE.md) file for details.