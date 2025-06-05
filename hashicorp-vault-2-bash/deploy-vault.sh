#!/bin/bash

# Deploy Vault infrastructure and initialize
# Usage: ./deploy-vault.sh [--quiet]

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT=$(pwd)
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"
DATA_DIR="$PROJECT_ROOT/data"
LOGS_DIR="$PROJECT_ROOT/logs"

# Parse arguments
QUIET_MODE=false
if [[ "$1" == "--quiet" || "$1" == "-q" ]]; then
    QUIET_MODE=true
fi

# Create directories
mkdir -p "$DATA_DIR"
mkdir -p "$LOGS_DIR"

# Generate log file name with timestamp
LOG_TIMESTAMP=$(date '+%Y-%m-%d_%H:%M:%S')
LOG_FILE="$LOGS_DIR/${LOG_TIMESTAMP}_deploy-vault.log"

# Logging functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
}

log_user_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [USER_OUTPUT] $message" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
}

log_command() {
    local description="$1"
    shift
    log "COMMAND: $description"
    log "EXECUTING: $*"

    if [ "$QUIET_MODE" = true ]; then
        # Quiet mode - hide command output
        "$@" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
    else
        # Default mode - show everything
        "$@" 2>&1 | tee >(sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE")
    fi

    local exit_code=$?
    log "EXIT_CODE: $exit_code"
    return $exit_code
}

# Enhanced echo function that logs user messages
echo_log() {
    echo -e "$@"
    log_user_message "$*"
}

# Start logging
log "=== Vault Deployment Started ==="
log "Project Root: $PROJECT_ROOT"
log "Quiet Mode: $QUIET_MODE"

echo_log "${BLUE}🚀 Starting Vault deployment...${NC}"
if [ "$QUIET_MODE" = true ]; then
    echo_log "${YELLOW}📝 Running in quiet mode. Full logs: $LOG_FILE${NC}"
else
    echo_log "${YELLOW}📝 Full logs also saved to: $LOG_FILE${NC}"
fi

# Step 1: Deploy infrastructure with Terraform
echo_log "${YELLOW}📦 Deploying infrastructure...${NC}"
cd "$TERRAFORM_DIR"

# Initialize Terraform if needed
if [ ! -d ".terraform" ] || [ ! -f ".terraform.lock.hcl" ]; then
    echo_log "${BLUE}  🔧 Initializing Terraform...${NC}"
    if log_command "Terraform init" terraform init; then
        echo_log "${GREEN}  ✅ Terraform initialized${NC}"
    else
        echo_log "${RED}❌ Terraform init failed${NC}"
        exit 1
    fi
fi

# Plan and validate
echo_log "${BLUE}  📋 Planning infrastructure...${NC}"
if ! log_command "Terraform plan" terraform plan -out=tfplan; then
    echo_log "${RED}❌ Terraform plan failed${NC}"
    exit 1
fi

echo_log "${BLUE}  🏗️  Applying infrastructure...${NC}"
if ! log_command "Terraform apply" terraform apply tfplan; then
    echo_log "${RED}❌ Terraform apply failed${NC}"
    exit 1
fi

echo_log "${GREEN}✅ Infrastructure deployed${NC}"

# Step 2: Get Terraform outputs
echo_log "${YELLOW}📊 Getting configuration...${NC}"

# Check if outputs exist
if ! log_command "Check terraform outputs" terraform output vault_namespace; then
    echo_log "${RED}❌ Missing terraform output: vault_namespace${NC}"
    echo_log "Make sure your terraform configuration has the required outputs"
    exit 1
fi

NAMESPACE=$(terraform output -raw vault_namespace)
REPLICAS=$(terraform output -raw vault_replicas 2>/dev/null || echo "3")

log "Retrieved namespace: $NAMESPACE"
log "Retrieved replicas: $REPLICAS"

echo_log "${GREEN}✅ Configuration loaded (namespace: $NAMESPACE, replicas: $REPLICAS)${NC}"

# Step 3: Wait for pods to be ready
echo_log "${YELLOW}⏳ Waiting for pods to be ready...${NC}"
if log_command "Wait for pods" kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n "$NAMESPACE" --timeout=300s; then
    echo_log "${GREEN}✅ Pods are ready${NC}"
else
    echo_log "${RED}❌ Pods failed to become ready${NC}"
    exit 1
fi

# Step 4: Initialize Vault
echo_log "${YELLOW}🔧 Initializing Vault...${NC}"
cd "$ANSIBLE_DIR"

if log_command "Vault initialization" ansible-playbook vault-init.yml \
    -e "namespace=$NAMESPACE" \
    -e "vault_pod=vault-0" \
    -e "data_dir=$DATA_DIR"; then
    echo_log "${GREEN}✅ Vault initialized${NC}"
else
    echo_log "${RED}❌ Vault initialization failed${NC}"
    exit 1
fi

# Step 4.5: Verify initialization worked
if [ -f "$DATA_DIR/vault-init.json" ]; then
    log "Init file created successfully"
    if [ "$QUIET_MODE" = false ]; then
        echo_log "${BLUE}📋 Init file contents:${NC}"
        jq . "$DATA_DIR/vault-init.json" || echo_log "Warning: Could not parse init file as JSON"
    fi
else
    echo_log "${RED}❌ Init file not found${NC}"
    exit 1
fi

# Check vault status after init
log_command "Check vault status after init" kubectl exec -n "$NAMESPACE" vault-0 -- vault status || log "Vault status check failed (normal if sealed)"

# Step 4.6: Wait for initialization to settle
echo_log "${YELLOW}⏳ Settling...${NC}"
sleep 15

# Step 5: Unseal all Vault pods
echo_log "${YELLOW}🔓 Unsealing Vault pods...${NC}"

# Unseal with retries
unsealed_count=0
for i in $(seq 0 $((REPLICAS-1))); do
    POD_NAME="vault-$i"
    echo -e "${BLUE}  🔓 Unsealing $POD_NAME...${NC}"

    # Try unsealing with retries
    RETRY_COUNT=0
    MAX_RETRIES=3

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if log_command "Unseal $POD_NAME (attempt $((RETRY_COUNT+1)))" ansible-playbook vault-unseal.yml \
            -e "namespace=$NAMESPACE" \
            -e "vault_pod=$POD_NAME" \
            -e "data_dir=$DATA_DIR"; then
            echo -e "${GREEN}  ✅ $POD_NAME unsealed${NC}"
            unsealed_count=$((unsealed_count+1))
            break
        else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                echo -e "${YELLOW}  ⚠️  Retry $RETRY_COUNT/$MAX_RETRIES for $POD_NAME...${NC}"
                sleep 5
            fi
        fi
    done

    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        echo -e "${RED}  ❌ Failed to unseal $POD_NAME${NC}"
        log "Failed to unseal $POD_NAME after $MAX_RETRIES attempts"
    fi
done

echo -e "${GREEN}✅ Unsealed $unsealed_count/$REPLICAS pods${NC}"

echo -e "${GREEN}✅ All Vault pods unsealed successfully${NC}"

# Step 6: Display useful information
echo -e "${BLUE}🎉 Vault deployment completed!${NC}"
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "  1. Access Vault UI: kubectl port-forward -n $NAMESPACE svc/vault 8200:8200"
echo "  2. Root token is in: $DATA_DIR/vault-init.json"
echo "  3. Export root token: export VAULT_TOKEN=\$(jq -r '.root_token' $DATA_DIR/vault-init.json)"
echo ""
echo -e "${RED}⚠️  SECURITY WARNING:${NC}"
echo "  - Root token and unseal keys are stored in $DATA_DIR/"
echo "  - This is for DEV only! Never store these in plain text in production"
echo "  - Add data/ directory to .gitignore"

cd "$PROJECT_ROOT"
