#!/bin/bash

# Destroy Vault infrastructure and clean up data
# Usage: ./destroy-vault.sh [--force] [--quiet]

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
DATA_DIR="$PROJECT_ROOT/data"
LOGS_DIR="$PROJECT_ROOT/logs"

# Parse arguments
FORCE_MODE=false
QUIET_MODE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --force|-f)
      FORCE_MODE=true
      shift
      ;;
    --quiet|-q)
      QUIET_MODE=true
      shift
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
LOG_FILE="$LOGS_DIR/${LOG_TIMESTAMP}_destroy-vault.log"

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
log "=== Vault Destruction Started ==="
log "Project Root: $PROJECT_ROOT"
log "Force Mode: $FORCE_MODE"
log "Quiet Mode: $QUIET_MODE"

echo_log "${RED}🔥 Vault Destruction Script${NC}"
echo_log "${YELLOW}This will destroy ALL Vault infrastructure and data!${NC}"
if [ "$QUIET_MODE" = true ]; then
    echo_log "${YELLOW}📝 Running in quiet mode. Full logs: $LOG_FILE${NC}"
else
    echo_log "${YELLOW}📝 Full logs also saved to: $LOG_FILE${NC}"
fi
echo ""

# Safety check - don't allow in production-like environments
if kubectl config current-context | grep -E "(prod|production)" > /dev/null 2>&1; then
    echo_log "${RED}❌ ABORT: Current kubectl context seems to be production!${NC}"
    echo_log "Current context: $(kubectl config current-context)"
    echo_log "This script is only for development environments."
    exit 1
fi

# Display what will be destroyed
echo_log "${BLUE}📋 What will be destroyed:${NC}"
cd "$TERRAFORM_DIR"

if [ -f "terraform.tfstate" ] || [ -d ".terraform" ]; then
    echo_log "  • Terraform infrastructure:"
    if [ "$QUIET_MODE" = false ]; then
        terraform show -no-color 2>/dev/null | head -20 || echo_log "    (unable to show terraform state)"
    else
        echo_log "    (terraform state exists)"
    fi
else
    echo_log "  • No Terraform state found"
fi

if [ -d "$DATA_DIR" ]; then
    echo_log "  • Local data directory: $DATA_DIR"
    echo_log "    Files: $(find "$DATA_DIR" -type f 2>/dev/null | wc -l) files"
else
    echo_log "  • No local data directory found"
fi

echo ""

# Confirmation (skip if --force)
if [ "$FORCE_MODE" = false ]; then
    echo_log "${YELLOW}⚠️  This action cannot be undone!${NC}"
    echo_log "${RED}Type 'destroy' to confirm destruction:${NC}"
    read -r confirmation

    if [ "$confirmation" != "destroy" ]; then
        echo_log "${GREEN}✅ Destruction cancelled${NC}"
        exit 0
    fi
fi

echo_log "${RED}🚨 Starting destruction process...${NC}"

# Step 1: Get namespace before destroying (if possible)
NAMESPACE=""
if [ -f "terraform.tfstate" ] && command -v terraform >/dev/null 2>&1; then
    echo_log "${YELLOW}📊 Getting namespace from Terraform...${NC}"
    NAMESPACE=$(terraform output -raw vault_namespace 2>/dev/null || echo "")
    log "Retrieved namespace: $NAMESPACE"
fi

# Step 2: Destroy Terraform infrastructure (this should handle most cleanup)
if [ -f "terraform.tfstate" ] || [ -d ".terraform" ]; then
    echo_log "${YELLOW}🏗️  Destroying Terraform infrastructure...${NC}"
    cd "$TERRAFORM_DIR"

    if log_command "Terraform destroy" terraform destroy -auto-approve; then
        echo_log "${GREEN}✅ Terraform destruction completed${NC}"
    else
        echo_log "${RED}❌ Terraform destruction failed${NC}"
        echo_log "${YELLOW}🧹 Attempting manual cleanup of stuck resources...${NC}"

        # Only do manual cleanup if Terraform fails
        if [ -n "$NAMESPACE" ]; then
            echo_log "${YELLOW}🧹 Force cleaning stuck resources in namespace: $NAMESPACE${NC}"

            # Force delete stuck PVCs
            if kubectl get pvc -n "$NAMESPACE" 2>/dev/null; then
                log_command "Delete PVCs" kubectl delete pvc --all -n "$NAMESPACE" --force --grace-period=0 || true
            fi

            # Force delete stuck pods
            if kubectl get pods -n "$NAMESPACE" 2>/dev/null; then
                log_command "Delete pods" kubectl delete pods --all -n "$NAMESPACE" --force --grace-period=0 || true
            fi

            # Delete the namespace
            if kubectl get namespace "$NAMESPACE" 2>/dev/null; then
                log_command "Delete namespace" kubectl delete namespace "$NAMESPACE" --timeout=60s || true
            fi

            echo_log "${GREEN}✅ Manual cleanup completed${NC}"
        fi
    fi
else
    echo_log "${YELLOW}⚠️  No Terraform state found, skipping Terraform destroy${NC}"
fi

# Step 4: Clean up local data
if [ -d "$DATA_DIR" ]; then
    echo -e "${YELLOW}🗑️  Removing local data directory...${NC}"

    # Show what's being deleted
    echo -e "${BLUE}Files to be deleted:${NC}"
    find "$DATA_DIR" -type f 2>/dev/null | head -10

    if rm -rf "$DATA_DIR"; then
        echo -e "${GREEN}✅ Local data cleaned up${NC}"
    else
        echo -e "${RED}❌ Failed to clean up local data${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No local data directory found${NC}"
fi

# Step 5: Clean up Terraform files
cd "$TERRAFORM_DIR"
echo -e "${YELLOW}🧹 Cleaning up Terraform temporary files...${NC}"

# Remove terraform temporary files
rm -rf .terraform.lock.hcl .terraform/ terraform.tfstate.backup tfplan 2>/dev/null || true

echo -e "${GREEN}✅ Terraform cleanup completed${NC}"

# Final status
echo ""
echo -e "${GREEN}🎉 Vault destruction completed!${NC}"
echo -e "${BLUE}📋 Summary:${NC}"
echo "  • Kubernetes resources: cleaned up"
echo "  • Terraform infrastructure: destroyed"
echo "  • Local data: removed"
echo "  • Temporary files: cleaned up"
echo ""
echo -e "${YELLOW}💡 To redeploy Vault, run: ./deploy-vault.sh${NC}"

cd "$PROJECT_ROOT"
