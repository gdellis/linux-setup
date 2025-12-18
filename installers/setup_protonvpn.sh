#!/usr/bin/env bash
#
# setup_protonvpn.sh - Proton VPN Installation Script
# Description: Downloads, verifies, and installs Proton VPN with GNOME desktop integration
# Usage: ./setup_protonvpn.sh
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
    
    # # Kill background processes spawned by this script
    # if [[ -n "${BG_PIDS:-}" ]]; then
    #     for pid in $BG_PIDS; do
    #         kill "$pid" 2>/dev/null || true
    #     done
    # fi
    
    # Close file descriptors if opened
    # exec 3>&- 4>&- 2>/dev/null || true
    
    # Restore terminal settings if modified
    # stty sane 2>/dev/null || true

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

readonly PROTON_URL="https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.8_all.deb"
readonly PROTON_FILE="$DL_DIR/protonvpn.deb"
readonly EXPECTED_SHA256="0b14e71586b22e498eb20926c48c7b434b751149b1f2af9902ef1cfe6b03e180"

# ------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------

# Install Proton VPN
install_protonvpn() {
    log_info "📥 Downloading Proton VPN"
    
    # Ensure dependencies
    ensure_dependencies --auto-install curl
    
    # Download the package
    if ! curl -fsSL --output "$PROTON_FILE" "$PROTON_URL"; then
        log_error "Error downloading package"
        return 1
    fi
    
    log_info "Verifying download integrity"
    
    # Calculate the actual checksum
    local actual_sha256
    actual_sha256=$(sha256sum "$PROTON_FILE" | awk '{print $1}')
    
    if [[ "$actual_sha256" != "$EXPECTED_SHA256" ]]; then
        log_error "Checksum verification failed!"
        log_error "Expected: $EXPECTED_SHA256"
        log_error "Got:      $actual_sha256"
        return 1
    fi
    
    log_success "Checksum verification passed"
    
    # Update package lists
    log_info "Updating package lists..."
    update_package_lists
    
    # Install the package
    log_info "Installing Proton VPN release package..."
    if ! sudo apt install -y "$PROTON_FILE"; then
        log_error "Failed to install Proton VPN release package"
        return 1
    fi
    
    # Update package lists again to include Proton VPN repository
    log_info "Updating package lists with Proton VPN repository..."
    update_package_lists
    
    # Install Proton VPN GNOME desktop integration
    log_info "Installing Proton VPN GNOME desktop integration..."
    if ! sudo apt install -y proton-vpn-gnome-desktop; then
        log_warning "Failed to install proton-vpn-gnome-desktop. Continuing with basic installation..."
    fi
    
    log_success "Proton VPN installed successfully"
    return 0
}

# ------------------------------------------------------------
# Main Installation Logic
# ------------------------------------------------------------

main() {
    log_info "Starting Proton VPN installation..."
    
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
    
    # Install Proton VPN
    if ! install_protonvpn; then
        log_error "Proton VPN installation failed"
        exit 1
    fi
    
    log_success "================================"
    log_success "✓ Proton VPN installation completed!"
    log_success "================================"
    log_info "You can now launch Proton VPN from your applications menu"
    log_info "or by running 'protonvpn' from the terminal."
    exit 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi