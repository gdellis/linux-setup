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
    
    echo "Cleanup complete"
    # shellcheck disable=SC2086
    exit $exit_code

}

# Set trap for various exit signals
trap cleanup EXIT INT TERM ERR

# ------------------------------------------------------------

log_info "📥 Downloading Proton VPN"

readonly PROTON_URL="https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.8_all.deb"
readonly PROTON_FILE="$DL_DIR/protonvpn.deb"

if curl --output "$PROTON_FILE" "$PROTON_URL";then
    log_info "Verifying download integrity"

    # Expected SHA256 checksum for protonvpn-stable-release_1.0.8_all.deb
    readonly EXPECTED_SHA256="0b14e71586b22e498eb20926c48c7b434b751149b1f2af9902ef1cfe6b03e180"

    # Calculate the actual checksum
    actual_sha256=$(sha256sum "$PROTON_FILE" | awk '{print $1}')

    if [[ "$actual_sha256" != "$EXPECTED_SHA256" ]]; then
        log_error "Checksum verification failed!"
        log_error "Expected: $EXPECTED_SHA256"
        log_error "Got:      $actual_sha256"
        exit 1
    fi

    log_success "Checksum verification passed"

    sudo nala install -y "$PROTON_FILE"
    sudo nala update

    sudo nala -y install proton-vpn-gnome-desktop

    log_success "Proton VPN installed successfully"
    exit 0
else log_error "Error downloading package"
    exit 1
fi

exit 0
