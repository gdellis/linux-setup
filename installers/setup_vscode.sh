#!/usr/bin/env bash
#
# setup_vscode.sh - Visual Studio Code Installation Script
# Description: Downloads and installs Visual Studio Code editor
# Category: Development
# Usage: ./setup_vscode.sh
#

set -euo pipefail

# Save and change directories
readonly ORIG_PWD=$(pwd)

# Get script directory and source logging library
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# shellcheck source=../lib/logging.sh
source "$SCRIPT_DIR/../lib/logging.sh"
# shellcheck source=../lib/dependencies.sh
source "$SCRIPT_DIR/../lib/dependencies.sh"

# ------------------------------------------------------------
# Setup Logging
# ------------------------------------------------------------
# region
SCRIPT_NAME=$(basename "$0" .sh)
readonly APP_NAME="${SCRIPT_NAME/setup_/}"
readonly DL_DIR="${HOME}/downloads/$APP_NAME"
readonly LOG_DIR="${HOME}/logs/$APP_NAME"
readonly LOG_FILE="${LOG_DIR}/$(date +%Y%m%d_%H%M%S)_${APP_NAME}.log"

# Ensure directories exist
mkdir -p "$DL_DIR"
mkdir -p "$LOG_DIR"

log_info "=== $APP_NAME Installer Started ==="
log_info "Log file: $LOG_FILE"
# endregion

cleanup()
{
    local exit_code=$?

    log_info "Cleaning up..."

    # Remove temporary files/directories
    # if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
    #     rm -rf "$TEMP_DIR"
    # fi

    # Kill background processes spawned by this script
    # if [[ -n "${BG_PIDS:-}" ]]; then
    #     for pid in $BG_PIDS; do
    #         kill "$pid" 2>/dev/null || true
    #     done
    # fi

    # Return to original directory
    cd "$ORIG_PWD" 2>/dev/null || true

    log_info "Cleanup complete"
    # shellcheck disable=SC2086
    exit $exit_code
}

# Set trap for various exit signals
trap cleanup EXIT INT TERM ERR

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

readonly VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
readonly VSCODE_FILE="$DL_DIR/vscode.deb"

# ------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------

# Install VS Code
install_vscode() {
    log_info "Installing Visual Studio Code..."
    
    # Ensure dependencies
    ensure_dependencies --auto-install curl
    
    # Update package lists
    log_info "Updating package lists..."
    update_package_lists
    
    # Download VS Code
    log_info "Downloading Visual Studio Code..."
    if ! curl -fsSL --output "$VSCODE_FILE" "$VSCODE_URL"; then
        log_error "Failed to download Visual Studio Code"
        return 1
    fi
    
    # Install VS Code
    log_info "Installing Visual Studio Code..."
    if ! sudo apt install -y "$VSCODE_FILE"; then
        log_error "Failed to install Visual Studio Code"
        return 1
    fi
    
    # Install additional recommended extensions (optional)
    log_info "Installing recommended dependencies..."
    if ! sudo apt install -y apt-transport-https; then
        log_warning "Failed to install apt-transport-https. Continuing..."
    fi
    
    log_success "Visual Studio Code installed successfully"
}

# ------------------------------------------------------------
# Main Installation Logic
# ------------------------------------------------------------

main() {
    log_info "Starting Visual Studio Code installation..."
    
    # Check if running on Ubuntu/Debian system
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot determine OS. This script is designed for Ubuntu/Debian systems."
        exit 1
    fi
    
    # Source OS information
    . /etc/os-release
    log_info "Detected OS: $ID $VERSION_ID"
    
    # Verify supported OS
    case "$ID" in
        ubuntu|debian|zorin|linuxmint)
            log_info "OS is supported: $ID"
            ;;
        *)
            log_warning "OS $ID may not be officially supported. Proceeding with installation anyway."
            ;;
    esac
    
    # Install VS Code
    if ! install_vscode; then
        log_error "Visual Studio Code installation failed"
        exit 1
    fi
    
    log_success "========================================"
    log_success "✓ Visual Studio Code installation completed!"
    log_success "========================================"
    log_info "You can now launch Visual Studio Code from your applications menu"
    log_info "or by running 'code' from the terminal."
    exit 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi