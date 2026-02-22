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
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
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

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------

handle_error() {
    local msg="$1"
    log_error "ERROR: $msg"
    exit 1
}

# ------------------------------------------------------------
# Dependency Checks
# ------------------------------------------------------------

check_dependencies() {
    if ! ensure_dependencies curl; then
        handle_error "Required dependency (curl) is missing and could not be installed"
    fi
}

# ------------------------------------------------------------
# Core Functions
# ------------------------------------------------------------

is_opencode_installed() {
    command -v opencode &> /dev/null
}

install_opencode() {
    log "Installing OpenCode..."

    if ! curl -fsSL https://opencode.ai/install | bash 2>/tmp/opencode_install_error.log; then
        handle_error "OpenCode installation failed. Check /tmp/opencode_install_error.log"
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
