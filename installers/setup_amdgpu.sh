#!/usr/bin/env bash
#
# setup_amdgpu.sh - AMD GPU Driver Installation Script
# Description: Installs AMD GPU drivers and ROCm development tools
# Usage: ./setup_amdgpu.sh
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

readonly AMDGPU_DEB_URL="https://repo.radeon.com/amdgpu-install/7.1.1/ubuntu/jammy/amdgpu-install_7.1.1.70101-1_all.deb"
readonly AMDGPU_DEB_FILE="$DL_DIR/amdgpu-install_7.1.1.70101-1_all.deb"
readonly AMDGPU_DEB_SHA256=""  # TODO: Add checksum when available

# ------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------

# Install AMD GPU drivers
install_amdgpu_drivers() {
    log_info "Installing AMD GPU drivers..."
    
    # Ensure dependencies
    ensure_dependencies --auto-install curl wget apt-transport-https
    
    # Update package lists
    log_info "Updating package lists..."
    update_package_lists
    
    # Download the AMD GPU installer package
    log_info "Downloading AMD GPU installer package..."
    if ! curl -fsSL --output "$AMDGPU_DEB_FILE" "$AMDGPU_DEB_URL"; then
        log_error "Failed to download AMD GPU installer package"
        return 1
    fi
    
    # Verify checksum if available
    if [[ -n "$AMDGPU_DEB_SHA256" ]]; then
        log_info "Verifying download integrity..."
        if ! echo "$AMDGPU_DEB_SHA256 $AMDGPU_DEB_FILE" | sha256sum -c --quiet; then
            log_error "Checksum verification failed"
            return 1
        fi
        log_success "Checksum verification passed"
    else
        log_warning "No checksum provided for verification"
    fi
    
    # Install the package
    log_info "Installing AMD GPU installer package..."
    if ! sudo apt install -y "$AMDGPU_DEB_FILE"; then
        log_error "Failed to install AMD GPU installer package"
        return 1
    fi
    
    # Run the AMD GPU installer with graphics and ROCm use cases
    log_info "Running AMD GPU installer..."
    if ! sudo amdgpu-install -y --usecase=graphics,rocm; then
        log_error "Failed to install AMD GPU drivers"
        return 1
    fi
    
    log_success "AMD GPU drivers installed successfully"
}

# Add user to GPU groups
configure_user_groups() {
    log_info "Adding user to GPU groups..."
    
    # Add current user to render and video groups
    if ! sudo usermod -a -G render,video "$USER"; then
        log_warning "Failed to add user to GPU groups. You may need to do this manually."
        return 1
    fi
    
    log_success "User added to GPU groups. You may need to log out and back in for changes to take effect."
}

# ------------------------------------------------------------
# Main Installation Logic
# ------------------------------------------------------------

main() {
    log_info "Starting AMD GPU driver installation..."
    
    # Check if running on Ubuntu/Debian system
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot determine OS. This script is designed for Ubuntu/Debian systems."
        exit 1
    fi
    
    # Install AMD GPU drivers
    if ! install_amdgpu_drivers; then
        log_error "AMD GPU driver installation failed"
        exit 1
    fi
    
    # Configure user groups
    if ! configure_user_groups; then
        log_warning "User group configuration failed. You may need to configure this manually."
    fi
    
    log_success "=========================================="
    log_success "✓ AMD GPU driver installation completed!"
    log_success "=========================================="
    log_info "Note: You may need to reboot your system for changes to take effect."
    log_info "Note: You may need to log out and back in for group changes to take effect."
    exit 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi