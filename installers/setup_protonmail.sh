#!/usr/bin/env bash
#
# setup_protonmail.sh - Proton Mail Desktop Application Installation Script
# Description: Downloads and installs the Proton Mail beta desktop client for Linux
# Usage: ./setup_protonmail.sh
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

log_info "📥 Downloading Proton Mail"

readonly PROTON_URL="https://proton.me/download/mail/linux/1.11.0/ProtonMail-desktop-beta.deb"
readonly PROTON_FILE="$DL_DIR/protonmail.deb"

# TODO: Add checksum verification once Proton provides official checksums
# ProtonMail does not currently provide SHA256 checksums on their download page
# For manual verification, compute the checksum after download:
#   sha256sum "$FILE"
# Then compare with checksum from Proton's official communication channels

if curl --output "$PROTON_FILE" "$PROTON_URL";then
    log_warning "Note: Checksum verification not available for ProtonMail downloads"
    log_info "Download complete. For manual verification, run: sha256sum $PROTON_FILE"

    sudo nala update && sudo nala install -y "$PROTON_FILE"
    log_success "protonmail installed successfully"
    exit 0
else log_error "Error downloading package"
    exit 1
fi

exit 0
