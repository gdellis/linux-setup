#!/usr/bin/env bash
set -euo pipefail

# Save and change directories
readonly ORIG_PWD=$(pwd)

# shellcheck disable=SC2034
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )



# ------------------------------------------------------------
# Setup Logging
# ------------------------------------------------------------
# region
SCRIPT_NAME=$(basename "$0" .sh)
APP_NAME="${SCRIPT_NAME/setup_/}"
readonly DL_DIR="${HOME}/downloads/$APP_NAME"
readonly LOG_DIR="${HOME}/logs/$APP_NAME"
readonly LOG_FILE="${LOG_DIR}/$(date +%Y%m%d_%H%M%S)_${APP_NAME}.log"

# Ensure directories exist
mkdir -p "$DL_DIR"
mkdir -p "$LOG_DIR"

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Logging functions with color and file output
log()
{
    local colored_msg plain_msg
    colored_msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"

    # Strip ANSI color codes for log file
    plain_msg=$(echo -e "$colored_msg" | sed -E 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mK]//g')

    # Output to terminal (with colors)
    echo -e "$colored_msg"

    # Output to log file (without colors)
    echo "$plain_msg" >> "$LOG_FILE"
}

# shellcheck disable=SC2329
log_info() { log "${GREEN}[INFO]${NC} $*";}
# shellcheck disable=SC2329
log_error() { log "${RED}[ERROR]${NC} $*";}
# shellcheck disable=SC2329
log_success() { log "${GREEN}[SUCCESS]${NC} $*";}
# shellcheck disable=SC2329
log_warning() { log "${YELLOW}[WARNING]${NC} $*";}

log_info "=== $APP_NAME Installer Started ==="
log_info "Log file: $LOG_FILE"
# endregion

# shellcheck disable=SC2329
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
        exit 1
    fi
}

# ------------------------------------------------------------
# Installation Functions
# ------------------------------------------------------------

add_gpg_key() {
    log_info "Adding Syncthing GPG key..."

    # Create keyrings directory if it doesn't exist
    if ! sudo mkdir -p /etc/apt/keyrings; then
        log_error "Failed to create keyrings directory"
        exit 1
    fi

    # Download and install the GPG key
    if sudo curl -L -o "$KEYRING_PATH" "$KEYRING_URL"; then
        log_success "GPG key added successfully"
    else
        log_error "Failed to download GPG key"
        exit 1
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
        exit 1
    fi

    if echo "$repo_line" | sudo tee "$SOURCES_LIST" > /dev/null; then
        log_success "Repository configured successfully"
    else
        log_error "Failed to configure repository"
        exit 1
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
        exit 1
    fi

    log_info "Installing Syncthing..."

    if sudo nala install -y syncthing; then
        log_success "Syncthing installed successfully"
    else
        log_error "Failed to install Syncthing"
        exit 1
    fi
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

main() {
    check_root

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
    add_gpg_key

    # Setup repository
    setup_repository "$channel"

    # Setup package priority
    setup_package_priority

    # Install Syncthing
    install_syncthing

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
