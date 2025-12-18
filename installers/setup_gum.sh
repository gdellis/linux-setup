#!/usr/bin/env bash
#
# setup_gum.sh - Gum TUI Tool Installation Script
# Description: Installs Gum, a tool for creating beautiful shell scripts and TUIs
# Usage: ./setup_gum.sh
#        Can also be run remotely with: bash <(curl -fsSL https://raw.githubusercontent.com/user/repo/main/installers/setup_gum.sh)
#

set -euo pipefail

# Save and change directories
readonly ORIG_PWD=$(pwd)

# Detect if we're running locally or remotely
is_running_remotely() {
    local script_path="${BASH_SOURCE[0]}"
    # If script is in a temporary directory, it's likely running remotely
    if [[ "$script_path" == /tmp/* ]] || [[ "$script_path" == /var/tmp/* ]]; then
        return 0  # true
    else
        return 1  # false
    fi
}

# Function to source library remotely or locally
source_library() {
    local library_name="$1"
    
    if is_running_remotely; then
        # Source library from GitHub
        local repo_user="yourusername"  # Replace with actual username
        local repo_name="linux-setup"   # Replace with actual repo name
        
        echo "Sourcing $library_name from remote repository..."
        if ! source <(curl -fsSL "https://raw.githubusercontent.com/$repo_user/$repo_name/main/lib/$library_name"); then
            echo "ERROR: Failed to source $library_name from remote repository"
            exit 1
        fi
    else
        # Source library locally
        local script_dir
        script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
        
        if [[ -f "$script_dir/../lib/$library_name" ]]; then
            # shellcheck source=/dev/null
            source "$script_dir/../lib/$library_name"
        else
            echo "ERROR: Local library $library_name not found"
            exit 1
        fi
    fi
}

# Source required libraries
source_library "logging.sh"

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

    log_info "Cleanup complete"
    # shellcheck disable=SC2086
    exit $exit_code
}

# Set trap for various exit signals
trap cleanup EXIT INT TERM ERR

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

readonly GUM_VERSION="0.14.5"
readonly GUM_REPO_KEY_URL="https://repo.charm.sh/apt/gpg.key"
readonly GUM_REPO_URL="https://repo.charm.sh/apt/"

# ------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------

detect_architecture() {
    local arch
    arch=$(uname -m)

    case "$arch" in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l)
            echo "armhf"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            return 1
            ;;
    esac
}

# ------------------------------------------------------------
# Installation Functions
# ------------------------------------------------------------

install_via_apt() {
    log_info "Installing Gum via APT repository..."

    # Add GPG key
    if ! sudo mkdir -p /etc/apt/keyrings; then
        log_error "Failed to create keyrings directory"
        return 1
    fi

    if ! curl -fsSL "$GUM_REPO_KEY_URL" | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg; then
        log_error "Failed to add GPG key"
        return 1
    fi

    # Add repository
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] $GUM_REPO_URL * *" | \
        sudo tee /etc/apt/sources.list.d/charm.list > /dev/null

    # Install gum
    if ! sudo nala update; then
        log_error "Failed to update package lists"
        return 1
    fi

    if ! sudo nala install -y gum; then
        log_error "Failed to install gum"
        return 1
    fi

    log_success "Gum installed successfully via APT"
    return 0
}

install_via_download() {
    log_info "Installing Gum via direct download..."

    local arch
    if ! arch=$(detect_architecture); then
        return 1
    fi

    local deb_url="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_${arch}.deb"
    local deb_file="$DL_DIR/gum_${GUM_VERSION}_${arch}.deb"

    log_info "Downloading from: $deb_url"

    if ! curl -fsSL -o "$deb_file" "$deb_url"; then
        log_error "Failed to download gum package"
        return 1
    fi

    log_success "Download completed"

    if ! sudo nala install -y "$deb_file"; then
        log_error "Failed to install gum package"
        return 1
    fi

    log_success "Gum installed successfully via direct download"
    return 0
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

main() {
    log_info "Starting Gum installation..."

    # Check if already installed
    if command -v gum &> /dev/null; then
        local installed_version
        installed_version=$(gum --version 2>&1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        log_warning "Gum is already installed (version: $installed_version)"
        read -rp "Do you want to reinstall? [y/N]: " reinstall
        if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled"
            exit 0
        fi
    fi

    # Try APT repository first (cleaner, gets updates)
    if install_via_apt; then
        log_success "===================================="
        log_success "Gum installation completed!"
        log_success "===================================="
        echo
        echo "Try it out:"
        echo "  gum style --foreground 212 'Hello, World!'"
        echo "  gum choose 'Option 1' 'Option 2' 'Option 3'"
        echo
        exit 0
    fi

    log_warning "APT installation failed, trying direct download..."

    # Fallback to direct download
    if install_via_download; then
        log_success "===================================="
        log_success "Gum installation completed!"
        log_success "===================================="
        echo
        echo "Try it out:"
        echo "  gum style --foreground 212 'Hello, World!'"
        echo "  gum choose 'Option 1' 'Option 2' 'Option 3'"
        echo
        exit 0
    fi

    log_error "All installation methods failed"
    exit 1
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
