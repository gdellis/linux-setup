#!/usr/bin/env bash
#
# setup_1password.sh - 1Password Installation Script
# Description: Installs 1Password password manager on Debian/Ubuntu-based systems
# Usage: ./setup_1password.sh
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
    if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi

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

readonly OP_GPG_KEY_URL="https://downloads.1password.com/linux/keys/1password.asc"
readonly OP_GPG_KEY_FILE="$DL_DIR/1password.asc"
readonly OP_DEB_REPO="https://downloads.1password.com/linux/debian/amd64/stable"
readonly OP_DEB_COMPONENTS="stable"
readonly OP_PACKAGE_NAME="1password"

# ------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------

# Install 1Password
install_1password() {
    log_info "Installing 1Password..."
    
    # Ensure dependencies
    ensure_dependencies --auto-install curl gpg apt-transport-https
    
    # Update package lists
    log_info "Updating package lists..."
    update_package_lists
    
    # Import the GPG key
    log_info "Importing 1Password GPG key..."
    if ! curl -fsSL "$OP_GPG_KEY_URL" | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg; then
        log_error "Failed to import 1Password GPG key"
        return 1
    fi
    
    # Add the repository
    log_info "Adding 1Password repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] $OP_DEB_REPO $OP_DEB_COMPONENTS main" | \
        sudo tee /etc/apt/sources.list.d/1password.list > /dev/null
    
    # Add the debsig policy directory
    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    
    # Download and install the policy file
    if ! curl -fsSL https://downloads.1password.com/linux/debian/debsig/1password.pol | \
       sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol > /dev/null; then
        log_warning "Failed to download debsig policy file"
    fi
    
    # Create the key directory and import the key for debsig verification
    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    
    if ! curl -fsSL https://downloads.1password.com/linux/keys/1password.asc | \
       sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg; then
        log_warning "Failed to import debsig GPG key"
    fi
    
    # Update package lists again to include the new repository
    log_info "Updating package lists with 1Password repository..."
    update_package_lists
    
    # Install 1Password
    log_info "Installing 1Password package..."
    if ! sudo apt install -y "$OP_PACKAGE_NAME"; then
        log_error "Failed to install 1Password"
        return 1
    fi
    
    log_success "1Password installed successfully"
}

# ------------------------------------------------------------
# Main Installation Logic
# ------------------------------------------------------------

main() {
    log_info "Starting 1Password installation..."
    
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
    
    # Install 1Password
    if ! install_1password; then
        log_error "1Password installation failed"
        exit 1
    fi
    
    log_success "================================"
    log_success "✓ 1Password installation completed!"
    log_success "================================"
    log_info "You can now launch 1Password from your applications menu"
    log_info "or by running '1password' from the terminal."
    exit 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi