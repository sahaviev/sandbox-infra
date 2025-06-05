# HashiCorp Vault Automated Infrastructure

An educational, fully automated HashiCorp Vault deployment solution for Kubernetes with High Availability (HA) using Raft storage backend. Perfect for learning, development, and testing environments.

## 🎯 Overview

This repository provides a complete infrastructure-as-code solution for learning and deploying HashiCorp Vault in Kubernetes environments. The solution includes:

- **Terraform modules** for infrastructure provisioning
- **Ansible playbooks** for Vault initialization and unsealing
- **Bash automation scripts** with comprehensive logging
- **High Availability** configuration with Raft consensus
- **Development-focused** setup with educational value

## 🚀 Quick Start

### Prerequisites

- **Kubernetes cluster** (tested on Minikube, suitable for development)
- **kubectl** configured and accessible
- **Helm 3.6+** installed
- **Terraform** installed
- **Ansible** installed
- **jq** for JSON processing

> ⚠️ **Note:** This setup is designed for development and learning. For production use, additional security measures are required.

### Deploy Complete Vault Infrastructure

All scripts support verbose (default) and quiet modes for different use cases:

```bash
# Deploy everything - infrastructure, initialization, and unsealing
./deploy-vault.sh

# Or run in quiet mode for minimal output
./deploy-vault.sh --quiet
```

### Check Cluster Status

```bash
# Quick status check
./status-vault.sh

# Detailed status with networking info
./status-vault.sh --detailed

# Continuous monitoring
./status-vault.sh --watch
```

### Unsealing After Pod Restarts

When Vault pods restart, they return to sealed state:

```bash
# Unseal all sealed pods
./unseal-vault.sh

# Unseal specific pod
./unseal-vault.sh --pod vault-1

# Continuous monitoring and auto-unsealing
./unseal-vault.sh --watch

# Quiet mode for automation/CI-CD
./unseal-vault.sh --quiet
```

### Destroy Vault Infrastructure

```bash
# Destroy complete infrastructure
./destroy-vault.sh

# Force destroy without confirmation (for automation)
./destroy-vault.sh --force

# Quiet destroy for CI/CD pipelines
./destroy-vault.sh --force --quiet
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Vault HA Cluster                        │
├─────────────────┬─────────────────┬─────────────────────────┤
│   vault-0       │   vault-1       │   vault-2               │
│   (Leader)      │   (Follower)    │   (Follower)            │
└─────────────────┴─────────────────┴─────────────────────────┘
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                 Kubernetes Services                        │
│  • vault (main)  • vault-ui  • vault-internal             │
└─────────────────────────────────────────────────────────────┘
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                    Ingress Controller                      │
│              (nginx with TLS termination)                  │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
hashicorp-vault/
├── terraform/                 # Infrastructure as Code
│   ├── main.tf               # Main Terraform configuration  
│   ├── variables.tf          # Variable definitions
│   ├── outputs.tf            # Output definitions
│   ├── vault-values.yaml.tpl # Helm chart values template
│   └── README.md             # Terraform documentation
├── ansible/                  # Configuration management
│   ├── vault-init.yml        # Vault initialization playbook
│   ├── vault-unseal.yml      # Vault unsealing playbook
│   └── README.md             # Ansible documentation
├── logs/                     # Operation logs (auto-generated)
├── data/                     # Vault secrets (auto-generated)
├── deploy-vault.sh           # 🚀 Main deployment script
├── unseal-vault.sh           # 🔓 Unseal automation script
├── status-vault.sh           # 📊 Cluster monitoring script
├── destroy-vault.sh          # 🗑️ Clean destruction script
└── README.md
```

## 📚 Component Documentation

For detailed information about specific components:

- **📖 [Terraform Configuration](./terraform/README.md)** - Infrastructure provisioning details
- **📖 [Ansible Playbooks](ansible/README.md)** - Vault initialization and unsealing

## 📊 Logging and Monitoring

All operational scripts generate comprehensive execution logs with detailed operation tracking.

### Log Files Location
```
logs/
├── 2025-06-05_14:30:45_deploy-vault.log
├── 2025-06-05_14:35:12_unseal-vault.log
└── 2025-06-05_14:40:33_destroy-vault.log
```

### Viewing Logs
```bash
# Recent deployment logs
tail -f logs/*deploy-vault.log

# All unseal operations
cat logs/*unseal-vault.log

# Search for errors
grep -i error logs/*.log
```

## 🔒 Security Features

### Current Implementation (Development/Learning)
- ✅ **Raft Integrated Storage** with automatic replication
- ✅ **Pod Anti-Affinity** for high availability
- ✅ **Secure initialization** with local key storage
- ✅ **Namespace isolation** in Kubernetes
- ✅ **Non-root containers** with security contexts
- ⚠️ **TLS disabled** for simplicity (development only)

### Missing for Production
- ❌ **TLS encryption** (internal and external)
- ❌ **Auto-unseal** with cloud KMS integration
- ❌ **Monitoring and alerting** setup
- ❌ **Audit logging** configuration
- ❌ **Backup strategies** for Raft storage
- ❌ **Network policies** and advanced RBAC
- ❌ **Vault Agent** for secret injection

## 🚦 Environment Suitability

### ✅ Perfect For
- **Learning HashiCorp Vault** concepts and operations
- **Development environments** with realistic HA setup
- **Testing integrations** and workflows
- **Prototyping** Vault-based solutions
- **Understanding** infrastructure automation

### ❌ NOT Suitable For
- **Production workloads** without additional hardening
- **Sensitive data** storage (missing encryption)
- **Compliance requirements** (no audit logs)
- **Internet-facing** deployments (security gaps)

### 🔄 Production Migration Path
To move this to production, you'll need:
1. **Enable TLS** for all communications
2. **Set up auto-unseal** with cloud KMS
3. **Implement monitoring** (Prometheus/Grafana)
4. **Configure audit logging** and backup strategies
5. **Add network policies** and advanced RBAC
6. **Use HashiCorp Vault Enterprise** for advanced features

## 👨‍💻 Author

**Rail Sakhaviev**  
📧 Email: rail.sakhaviev@gmail.com  
🐙 GitHub: [@sahaviev](https://github.com/sahaviev)  
📱 Telegram: [@sahaviev](https://t.me/sahaviev)  
💼 LinkedIn: [Rail Sakhaviev](https://linkedin.com/in/rail.sakhaviev)

## 📄 License

MIT License - see [LICENSE](../LICENSE.md) file for details.
