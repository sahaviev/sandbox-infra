#!/bin/bash

# Check Vault cluster status
# Usage: ./status-vault.sh [--detailed] [--watch]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT=$(pwd)
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
DATA_DIR="$PROJECT_ROOT/data"
VAULT_INIT_FILE="$DATA_DIR/vault-init.json"

# Parse command line arguments
DETAILED_MODE=false
WATCH_MODE=false

for arg in "$@"; do
    case $arg in
        --detailed|-d)
            DETAILED_MODE=true
            ;;
        --watch|-w)
            WATCH_MODE=true
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --detailed, -d    Show detailed information"
            echo "  --watch, -w       Watch mode (refresh every 5 seconds)"
            echo "  --help, -h        Show this help"
            exit 0
            ;;
    esac
done

# Function to get Terraform outputs
get_terraform_outputs() {
    if [ -f "$TERRAFORM_DIR/terraform.tfstate" ]; then
        cd "$TERRAFORM_DIR"
        NAMESPACE=$(terraform output -raw vault_namespace 2>/dev/null || echo "unknown")
        REPLICAS=$(terraform output -raw vault_replicas 2>/dev/null || echo "3")
        cd "$PROJECT_ROOT"
    else
        NAMESPACE="unknown"
        REPLICAS="unknown"
    fi
}

# Function to check if kubectl context is available
check_kubectl() {
    if ! command -v kubectl >/dev/null 2>&1; then
        echo -e "${RED}❌ kubectl not found${NC}"
        exit 1
    fi

    if ! kubectl cluster-info >/dev/null 2>&1; then
        echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
        exit 1
    fi
}

# Function to get vault auth info
get_vault_auth() {
    if [ -f "$VAULT_INIT_FILE" ]; then
        ROOT_TOKEN=$(jq -r '.root_token' "$VAULT_INIT_FILE" 2>/dev/null || echo "unknown")
        UNSEAL_KEYS_COUNT=$(jq -r '.unseal_keys_b64 | length' "$VAULT_INIT_FILE" 2>/dev/null || echo "unknown")
    else
        ROOT_TOKEN="not_found"
        UNSEAL_KEYS_COUNT="not_found"
    fi
}

# Function to check single pod status
check_pod_status() {
    local pod_name=$1
    local namespace=$2

    # Check if pod exists and is running
    local pod_status=$(kubectl get pod "$pod_name" -n "$namespace" -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
    local pod_ready=$(kubectl get pod "$pod_name" -n "$namespace" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")

    if [ "$pod_status" = "NotFound" ]; then
        echo -e "  ${RED}❌ $pod_name: Pod not found${NC}"
        return 1
    fi

    # Get Vault status from pod
    local vault_status_json=$(kubectl exec -n "$namespace" "$pod_name" -- vault status -format=json 2>/dev/null || echo '{}')
    local sealed=$(echo "$vault_status_json" | jq -r '.sealed // true')
    local initialized=$(echo "$vault_status_json" | jq -r '.initialized // false')
    local version=$(echo "$vault_status_json" | jq -r '.version // "unknown"')
    local ha_enabled=$(echo "$vault_status_json" | jq -r '.ha_enabled // false')
    local is_leader=$(echo "$vault_status_json" | jq -r '.is_leader // false')
    local leader_address=$(echo "$vault_status_json" | jq -r '.leader_address // "unknown"')

    # Status indicators
    local status_icon="❓"
    local status_color="$YELLOW"

    if [ "$pod_status" = "Running" ] && [ "$pod_ready" = "True" ]; then
        if [ "$sealed" = "false" ] && [ "$initialized" = "true" ]; then
            status_icon="✅"
            status_color="$GREEN"
        elif [ "$sealed" = "true" ] && [ "$initialized" = "true" ]; then
            status_icon="🔒"
            status_color="$YELLOW"
        else
            status_icon="❌"
            status_color="$RED"
        fi
    else
        status_icon="❌"
        status_color="$RED"
    fi

    # Basic status line
    local leader_indicator=""
    if [ "$is_leader" = "true" ]; then
        leader_indicator=" ${PURPLE}👑 LEADER${NC}"
    fi

    echo -e "  ${status_color}${status_icon} $pod_name${NC} | Pod: $pod_status | Ready: $pod_ready | Sealed: $sealed$leader_indicator"

    # Detailed information
    if [ "$DETAILED_MODE" = true ]; then
        echo -e "    ${CYAN}├─ Initialized: $initialized${NC}"
        echo -e "    ${CYAN}├─ Version: $version${NC}"
        echo -e "    ${CYAN}├─ HA Enabled: $ha_enabled${NC}"
        if [ "$leader_address" != "unknown" ] && [ "$leader_address" != "null" ]; then
            echo -e "    ${CYAN}└─ Leader: $leader_address${NC}"
        else
            echo -e "    ${CYAN}└─ Leader: not available${NC}"
        fi
    fi
}

# Function to show cluster overview
show_cluster_overview() {
    echo -e "${BLUE}🏗️  Vault Cluster Overview${NC}"
    echo -e "${BLUE}═══════════════════════════${NC}"
    echo "  Namespace: $NAMESPACE"
    echo "  Expected Replicas: $REPLICAS"
    echo "  Init File: $([ -f "$VAULT_INIT_FILE" ] && echo "✅ Found" || echo "❌ Missing")"
    echo "  Root Token: $([ "$ROOT_TOKEN" != "not_found" ] && echo "✅ Available" || echo "❌ Missing")"
    echo "  Unseal Keys: $UNSEAL_KEYS_COUNT"
    echo ""
}

# Function to show pod statuses
show_pod_statuses() {
    echo -e "${BLUE}📦 Pod Status${NC}"
    echo -e "${BLUE}═════════════${NC}"

    if [ "$NAMESPACE" = "unknown" ]; then
        echo -e "  ${RED}❌ Cannot determine namespace${NC}"
        return 1
    fi

    # Get actual pods from Kubernetes
    local actual_pods=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=vault -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")

    if [ -z "$actual_pods" ]; then
        echo -e "  ${RED}❌ No Vault pods found in namespace $NAMESPACE${NC}"
        return 1
    fi

    for pod in $actual_pods; do
        check_pod_status "$pod" "$NAMESPACE"
    done
    echo ""
}

# Function to show services and networking
show_networking() {
    if [ "$DETAILED_MODE" = true ] && [ "$NAMESPACE" != "unknown" ]; then
        echo -e "${BLUE}🌐 Networking${NC}"
        echo -e "${BLUE}═══════════${NC}"

        # Services
        local services=$(kubectl get svc -n "$NAMESPACE" -l app.kubernetes.io/name=vault -o custom-columns=NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,PORT:.spec.ports[0].port --no-headers 2>/dev/null || echo "")
        if [ -n "$services" ]; then
            echo -e "  ${CYAN}Services:${NC}"
            echo "$services" | while read line; do
                echo "    $line"
            done
        fi

        # Ingress
        local ingress=$(kubectl get ingress -n "$NAMESPACE" -o custom-columns=NAME:.metadata.name,HOSTS:.spec.rules[0].host,ADDRESS:.status.loadBalancer.ingress[0].ip --no-headers 2>/dev/null || echo "")
        if [ -n "$ingress" ]; then
            echo -e "  ${CYAN}Ingress:${NC}"
            echo "$ingress" | while read line; do
                echo "    $line"
            done
        fi
        echo ""
    fi
}

# Function to show quick actions
show_quick_actions() {
    echo -e "${BLUE}⚡ Quick Actions${NC}"
    echo -e "${BLUE}═══════════════${NC}"

    if [ "$ROOT_TOKEN" != "not_found" ] && [ "$ROOT_TOKEN" != "unknown" ]; then
        echo -e "  ${GREEN}Export root token:${NC}"
        echo "    export VAULT_TOKEN=$ROOT_TOKEN"
        echo ""
    fi

    if [ "$NAMESPACE" != "unknown" ]; then
        echo -e "  ${GREEN}Access Vault UI:${NC}"
        echo "    kubectl port-forward -n $NAMESPACE svc/vault 8200:8200"
        echo "    Then open: http://localhost:8200"
        echo ""

        echo -e "  ${GREEN}Connect to Vault pod:${NC}"
        echo "    kubectl exec -it -n $NAMESPACE vault-0 -- /bin/sh"
        echo ""
    fi

    echo -e "  ${GREEN}Other commands:${NC}"
    echo "    ./deploy-vault.sh    # Deploy/redeploy Vault"
    echo "    ./destroy-vault.sh   # Destroy Vault"
    echo "    $0 --detailed        # Show detailed status"
    echo "    $0 --watch           # Watch mode"
}

# Main status check function
main_status_check() {
    clear
    echo -e "${PURPLE}🔐 Vault Cluster Status$([ "$WATCH_MODE" = true ] && echo " (Watch Mode - Press Ctrl+C to exit)")${NC}"
    echo -e "${PURPLE}$(date)${NC}"
    echo ""

    get_terraform_outputs
    get_vault_auth

    show_cluster_overview
    show_pod_statuses
    show_networking

    if [ "$WATCH_MODE" = false ]; then
        show_quick_actions
    fi
}

# Main execution
check_kubectl

if [ "$WATCH_MODE" = true ]; then
    # Watch mode - refresh every 5 seconds
    while true; do
        main_status_check
        sleep 5
    done
else
    # Single run
    main_status_check
fi
