#!/bin/bash

# Unseal Vault pods after restarts
# Usage: ./unseal-vault.sh [--pod vault-0] [--watch] [--quiet]

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Config
PROJECT_ROOT=$(pwd)
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"
DATA_DIR="$PROJECT_ROOT/data"
LOGS_DIR="$PROJECT_ROOT/logs"

# Parse args
SPECIFIC_POD=""
WATCH_MODE=false
QUIET_MODE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --pod)
      SPECIFIC_POD="$2"
      shift 2
      ;;
    --watch|-w)
      WATCH_MODE=true
      shift
      ;;
    --quiet|-q)
      QUIET_MODE=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--pod vault-0] [--watch] [--quiet]"
      echo "  --pod NAME    Unseal specific pod"
      echo "  --watch       Monitor and auto-unseal"
      echo "  --quiet       Minimal output"
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

# Create logs directory
mkdir -p "$LOGS_DIR"

# Generate log file name with timestamp
LOG_TIMESTAMP=$(date '+%Y-%m-%d_%H:%M:%S')
LOG_FILE="$LOGS_DIR/${LOG_TIMESTAMP}_unseal-vault.log"

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
log "=== Vault Unseal Started ==="
log "Project Root: $PROJECT_ROOT"
log "Specific Pod: ${SPECIFIC_POD:-all}"
log "Watch Mode: $WATCH_MODE"
log "Quiet Mode: $QUIET_MODE"

# Get namespace from terraform
if [ -f "$TERRAFORM_DIR/terraform.tfstate" ]; then
    cd "$TERRAFORM_DIR"
    NAMESPACE=$(terraform output -raw vault_namespace 2>/dev/null || echo "vault-namespace")
    cd "$PROJECT_ROOT"
else
    NAMESPACE="vault-namespace"
fi

log "Retrieved namespace: $NAMESPACE"

# Check init file exists
if [ ! -f "$DATA_DIR/vault-init.json" ]; then
    echo_log "${RED}❌ Init file not found. Run ./deploy-vault.sh first${NC}"
    exit 1
fi

log "Init file found at: $DATA_DIR/vault-init.json"

# Get pods to unseal
if [ -n "$SPECIFIC_POD" ]; then
    PODS="$SPECIFIC_POD"
    log "Target pod: $SPECIFIC_POD"
else
    PODS=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=vault -o name 2>/dev/null | sed 's/pod\///' || echo "")
    log "Found pods: $PODS"
fi

# Function to unseal pod
unseal_pod() {
    local pod=$1

    # Check if pod needs unsealing
    local status=$(kubectl exec -n "$NAMESPACE" "$pod" -- vault status -format=json 2>/dev/null || echo '{}')
    local sealed=$(echo "$status" | jq -r '.sealed // true' 2>/dev/null)
    local initialized=$(echo "$status" | jq -r '.initialized // false' 2>/dev/null)

    log "Pod $pod status: initialized=$initialized, sealed=$sealed"

    if [ "$initialized" = "true" ] && [ "$sealed" = "true" ]; then
        echo_log "${BLUE}🔓 Unsealing $pod...${NC}"
        if log_command "Unseal $pod" ansible-playbook "$ANSIBLE_DIR/vault-unseal.yml" \
            -e "namespace=$NAMESPACE" \
            -e "vault_pod=$pod" \
            -e "data_dir=$DATA_DIR"; then
            echo_log "${GREEN}✅ $pod unsealed${NC}"
            log "Successfully unsealed $pod"
        else
            echo_log "${RED}❌ Failed to unseal $pod${NC}"
            log "Failed to unseal $pod"
        fi
    else
        echo_log "${GREEN}✓ $pod already unsealed${NC}"
        log "Pod $pod already unsealed or not initialized"
    fi
}

# Main unseal function
unseal_all() {
    if [ -z "$PODS" ]; then
        echo_log "${RED}❌ No Vault pods found${NC}"
        return 1
    fi

    log "Starting unseal process for pods: $PODS"

    for pod in $PODS; do
        unseal_pod "$pod"
    done

    log "Unseal process completed"
}

# Watch mode
if [ "$WATCH_MODE" = true ]; then
    echo_log "${YELLOW}👁️  Watch mode - Press Ctrl+C to stop${NC}"
    if [ "$QUIET_MODE" = true ]; then
        echo_log "${YELLOW}📝 Running in quiet mode. Full logs: $LOG_FILE${NC}"
    else
        echo_log "${YELLOW}📝 Full logs also saved to: $LOG_FILE${NC}"
    fi

    iteration=0
    while true; do
        iteration=$((iteration + 1))
        echo_log "${BLUE}🔄 Check #$iteration - $(date '+%H:%M:%S') - Checking pods...${NC}"
        log "=== Watch iteration $iteration ==="
        unseal_all
        sleep 30
    done
else
    echo_log "${BLUE}🔐 Unsealing Vault pods in namespace: $NAMESPACE${NC}"
    if [ "$QUIET_MODE" = true ]; then
        echo_log "${YELLOW}📝 Running in quiet mode. Full logs: $LOG_FILE${NC}"
    else
        echo_log "${YELLOW}📝 Full logs also saved to: $LOG_FILE${NC}"
    fi

    unseal_all

    log "=== Vault Unseal Completed ==="
    echo_log "${YELLOW}📝 Full logs: $LOG_FILE${NC}"
fi
