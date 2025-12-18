#!/usr/bin/env bash
#
# setup_protonmail.sh - Proton Mail Desktop Application Installation Script
# Description: Downloads and installs the Proton Mail beta desktop client for Linux
# Category: Productivity
# Usage: ./setup_protonmail.sh [OPTIONS]
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
if [[ "$NON_INTERACTIVE" == "true" ]]; then
    log_info "Running in non-interactive mode"
fi
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

# Ensure dependencies
ensure_dependencies --auto-install curl

# Download file with error checking
log_info "📥 Downloading Proton Mail"

readonly PROTON_URL="https://proton.me/download/mail/linux/1.11.0/ProtonMail-desktop-beta.deb"
readonly PROTON_FILE="$DL_DIR/protonmail.deb"

if curl --output "$PROTON_FILE" "$PROTON_URL"; then
    log_warning "Note: Checksum verification not available for ProtonMail downloads"
    log_info "Download complete. For manual verification, run: sha256sum $PROTON_FILE"

    # Install using the dependency library function
    if ! install_package "$PROTON_FILE"; then
        log_error "Failed to install Proton Mail"
        exit 1
    fi
    
    log_success "Proton Mail installed successfully"
    exit 0
else 
    log_error "Error downloading package"
    exit 1
fi

exit 0
