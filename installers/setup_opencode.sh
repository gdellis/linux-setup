#!/usr/bin/env bash
#
# setup_opencode.sh - OpenCode AI Coding Agent Installation
# Description: Installs OpenCode, an open source AI coding agent
# Category: AI/ML
# Usage: ./setup_opencode.sh [OPTIONS]
#        -y, --yes, --non-interactive    Skip confirmation prompts
#        -h, --help                      Show help message
#

set -euo pipefail

# Parse command line arguments
NON_INTERACTIVE=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes|--non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -y, --yes, --non-interactive    Skip confirmation prompts"
            echo "  -h, --help                      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Get script directory and source logging library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/logging.sh
source "$SCRIPT_DIR/../lib/logging.sh"
# shellcheck source=../lib/dependencies.sh
source "$SCRIPT_DIR/../lib/dependencies.sh"

# ------------------------------------------------------------
# Setup Logging
# ------------------------------------------------------------
readonly APP_NAME=opencode
readonly LOG_DIR="${HOME}/logs/$APP_NAME"
readonly LOG_FILE="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$LOG_DIR"

log_info "=== $APP_NAME Installer Started ==="
log_info "Log file: $LOG_FILE"
if [[ "$NON_INTERACTIVE" == "true" ]]; then
    log_info "Running in non-interactive mode"
fi

handle_error() {
    local msg="$1"
    log_error "ERROR: $msg"
    exit 1
}

# ------------------------------------------------------------
# Dependency Checks
# ------------------------------------------------------------

check_dependencies() {
    local missing_deps=()
    
    if command -v bun >/dev/null 2>&1; then
        return 0
    elif command -v npm >/dev/null 2>&1; then
        return 0
    else
        missing_deps+=("bun or npm")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        handle_error "Required dependencies are missing: ${missing_deps[*]}. Please install bun or npm first."
    fi
}

# ------------------------------------------------------------
# Core Functions
# ------------------------------------------------------------

is_opencode_installed() {
    command -v opencode &> /dev/null
}

install_opencode() {
    log_info "Installing OpenCode..."

    if command -v bun >/dev/null 2>&1; then
        log_info "Using bun to install opencode..."
        if ! bun add -g opencode-ai 2>&1 | tee -a "$LOG_FILE"; then
            handle_error "OpenCode installation via bun failed"
        fi
    elif command -v npm >/dev/null 2>&1; then
        log_info "Using npm to install opencode..."
        if ! npm install -g opencode-ai 2>&1 | tee -a "$LOG_FILE"; then
            handle_error "OpenCode installation via npm failed"
        fi
    fi

    if ! is_opencode_installed; then
        handle_error "OpenCode command not found after installation. You may need to add the npm global bin directory to your PATH."
    fi

    log_success "OpenCode installed successfully"
}

main() {
    log_info "Starting OpenCode setup..."

    check_dependencies "$@"

    if is_opencode_installed; then
        log_warning "OpenCode is already installed"
        if [[ "$NON_INTERACTIVE" == "false" ]]; then
            echo
            read -rp "Do you want to reinstall? [y/N]: " reinstall
            if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
                log_info "Installation cancelled"
                exit 0
            fi
        fi
    fi

    install_opencode

    log_success "===================================="
    log_success "OpenCode installation completed"
    log_success "===================================="

    echo
    echo "Run 'opencode --help' to get started"
    echo
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
