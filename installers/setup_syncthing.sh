#!/usr/bin/env bash
#
# setup_syncthing.sh - Syncthing File Synchronization Installation Script
# Description: Configures APT repository and installs Syncthing with stable or candidate releases
# Usage: ./setup_syncthing.sh [stable|candidate]
#        Default: stable
#

set -euo pipefail

# Save and change directories
readonly ORIG_PWD=$(pwd)

# Get script directory and source logging library
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# shellcheck source=../lib/logging.sh
source "$SCRIPT_DIR/../lib/logging.sh"

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

    # Return to original directory
    cd "$ORIG_PWD" 2>/dev/null || true

    echo "Cleanup complete"
    # shellcheck disable=SC2086
    exit $exit_code
}

# Set trap for various exit signals
trap cleanup EXIT INT TERM ERR

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

readonly KEYRING_PATH="/etc/apt/keyrings/syncthing-archive-keyring.gpg"
readonly KEYRING_URL="https://syncthing.net/release-key.gpg"
readonly SOURCES_LIST="/etc/apt/sources.list.d/syncthing.list"
readonly PREFERENCES_FILE="/etc/apt/preferences.d/syncthing.pref"

# ------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root. It will use sudo when needed."
        return 1
    fi
    return 0
}

# ------------------------------------------------------------
# Installation Functions
# ------------------------------------------------------------

add_gpg_key() {
    log_info "Adding Syncthing GPG key..."

    # Create keyrings directory if it doesn't exist
    if ! sudo mkdir -p /etc/apt/keyrings; then
        log_error "Failed to create keyrings directory"
        return 1
    fi

    # Download and install the GPG key
    if sudo curl -L -o "$KEYRING_PATH" "$KEYRING_URL"; then
        log_success "GPG key added successfully"
    else
        log_error "Failed to download GPG key"
        return 1
    fi
}

setup_repository() {
    local channel="${1:-stable}"

    log_info "Setting up Syncthing APT repository (channel: $channel)..."

    local repo_line
    if [[ "$channel" == "stable" ]]; then
        repo_line="deb [signed-by=$KEYRING_PATH] https://apt.syncthing.net/ syncthing stable-v2"
    elif [[ "$channel" == "candidate" ]]; then
        repo_line="deb [signed-by=$KEYRING_PATH] https://apt.syncthing.net/ syncthing candidate"
    else
        log_error "Invalid channel: $channel. Must be 'stable' or 'candidate'"
        return 1
    fi

    if echo "$repo_line" | sudo tee "$SOURCES_LIST" > /dev/null; then
        log_success "Repository configured successfully"
    else
        log_error "Failed to configure repository"
        return 1
    fi
}

setup_package_priority() {
    log_info "Setting up package priority..."

    local pref_content="Package: *
Pin: origin apt.syncthing.net
Pin-Priority: 990"

    if printf "%s\n" "$pref_content" | sudo tee "$PREFERENCES_FILE" > /dev/null; then
        log_success "Package priority configured successfully"
    else
        log_warning "Failed to configure package priority (non-critical)"
    fi
}

install_syncthing() {
    log_info "Updating package lists..."

    if ! sudo nala update; then
        log_error "Failed to update package lists"
        return 1
    fi

    log_info "Installing Syncthing..."

    if sudo nala install -y syncthing; then
        log_success "Syncthing installed successfully"
    else
        log_error "Failed to install Syncthing"
        return 1
    fi
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

main() {
    if ! check_root; then
        exit 1
    fi

    # Determine channel (default to stable)
    local channel="stable"
    if [[ $# -gt 0 ]]; then
        if [[ "$1" == "candidate" ]]; then
            channel="candidate"
        elif [[ "$1" != "stable" ]]; then
            log_warning "Unknown channel '$1', using stable"
        fi
    fi

    log_info "Starting Syncthing installation (channel: $channel)..."

    # Add GPG key
    if ! add_gpg_key; then
        log_error "Failed to add GPG key"
        exit 1
    fi

    # Setup repository
    if ! setup_repository "$channel"; then
        log_error "Failed to setup repository"
        exit 1
    fi

    # Setup package priority (non-critical)
    setup_package_priority

    # Install Syncthing
    if ! install_syncthing; then
        log_error "Failed to install Syncthing"
        exit 1
    fi

    log_success "===================================="
    log_success "Syncthing installation completed!"
    log_success "===================================="

    echo
    echo "To start Syncthing for your user:"
    echo "  systemctl --user enable --now syncthing.service"
    echo
    echo "To access the web UI, open:"
    echo "  http://localhost:8384"
    echo

    exit 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
