#!/usr/bin/env bash

set -euo pipefail

# Get script directory and source logging library
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# shellcheck source=../lib/logging.sh
source "$SCRIPT_DIR/../lib/logging.sh"

# ------------------------------------------------------------
# Setup Logging
# ------------------------------------------------------------
# region
readonly APP_NAME=ollama
readonly DL_DIR="${HOME}/downloads/$APP_NAME"
readonly LOG_DIR="${HOME}/logs/$APP_NAME"
readonly LOG_FILE="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"

# Ensure directories exist
mkdir -p "$DL_DIR"
mkdir -p "$LOG_DIR"

log_info "=== $APP_NAME Installer Started ==="
log_info "Log file: $LOG_FILE"
# endregion

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

cloud_models=(
    "ministral-3:3b-cloud"
    "ministral-3:8b-cloud"
    "ministral-3:14b-cloud"
    "mistral-large-3:675b-cloud"
    "qwen3-coder:480b-cloud"
    "cogito-2.1:671b-cloud"
    "kimi-k2-thinking:cloud"
    "kimi-k2:1t-cloud"
    "minimax-m2:cloud"
    "deepseek-v3.1:671b-cloud"
    "gpt-oss:120b-cloud"
    "glm-4.6:cloud"
    "qwen3-vl:235b-instruct-cloud"
    "qwen3-vl:235b-cloud"
    "gpt-oss:20b-cloud"
)

local_models=(
    "qwen2.5-coder:1.5b"
    "nomic-embed-text:latest"
    "qwen3-embedding:latest"
    "hf.co/dat-lequoc/Fast-Apply-1.5B-v1.0_GGUF:latest"
    "dengcao/Qwen3-Reranker-8B:Q3_K_M"
    "nate/instinct:latest"
)

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------

handle_error() {
    local msg="$1"
    log_error "❌ ERROR: $msg"
    exit 1
}

# ------------------------------------------------------------
# Dependency Checks
# ------------------------------------------------------------

check_dependencies() {
    local deps=("curl" "jq")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            handle_error "$dep is required but not installed"
        fi
    done
}

# ------------------------------------------------------------
# Core Functions
# ------------------------------------------------------------

get_downloaded_models() {
    if ! /usr/local/bin/ollama list  &>/tmp/ollama_error.log; then
        handle_error "Failed to query Ollama. Is the service running?"
    fi
    /usr/local/bin/ollama list | awk '{print $1}' | sort > "/tmp/ollama_cache_$$"
}

is_model_downloaded() {
    local model="$1"
    grep -Fxq "$model" "/tmp/ollama_cache_$$"
}

install_ollama() {
    log "Installing Ollama..."
    local installer="/tmp/ollama_install.sh"
    
    if ! curl -fsSL https://ollama.com/install.sh -o "$installer"; then
        handle_error "Failed to download Ollama installer"
    fi
    
    if ! sh "$installer" 2>/tmp/ollama_install_error.log; then
        rm "$installer"
        handle_error "Ollama installation failed. Check /tmp/ollama_install_error.log"
    fi
    
    rm "$installer"
    log_success "✓ Ollama installed successfully"
}

download_model() {
    local model="$1"
    
    if is_model_downloaded "$model"; then
        log_info "⏭️  Skipping '$model' (already downloaded)"
        return 0
    fi
    
    log_info "📥 Downloading '$model'..."
    if ollama pull "$model" >/tmp/ollama_pull.log 2>&1; then
        log_success "✓ Successfully downloaded '$model'"
    else
        log_warning "⚠️  Failed to download '$model' (continuing...)"
        return 1
    fi
}

download_model_list() {
    local list_name="$1"
    shift
    local models=("$@")
    
    log_info "=== $list_name ==="
    for model in "${models[@]}"; do
        download_model "$model"
    done
}

main() {
    log_info "Starting Ollama setup..."
    
    # Check basic dependencies (curl, jq)
    check_dependencies
    
    # Check/install Ollama
    if ! command -v ollama &> /dev/null; then
        log_warning "Ollama not found. Installing..."
        install_ollama
    fi
    
    # Cache downloaded models
    get_downloaded_models
    trap 'rm -f "/tmp/ollama_cache_$$"' EXIT
    
    # Download all models
    download_model_list "Cloud Models" "${cloud_models[@]}"
    download_model_list "Local Models" "${local_models[@]}"
    
    log_success "===================================="
    log_success "✓ Model download process completed"
    log_success "===================================="
    
    echo
    echo "For cloud models, you must login to your account by running:"
    echo "  ollama signin"
    echo
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi