#!/usr/bin/env bash
#
# setup_neovim.sh - Neovim Installation Script
# Description: Installs the latest stable version of Neovim from official releases
# Category: Development
# Usage: ./setup_neovim.sh [OPTIONS]
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

readonly NVIM_VERSION="v0.10.2"
readonly NVIM_DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux64.tar.gz"
readonly NVIM_TARBALL="$DL_DIR/nvim-linux64.tar.gz"
readonly NVIM_INSTALL_DIR="/opt/nvim"
readonly NVIM_BINARY_LINK="/usr/local/bin/nvim"
readonly NVIM_CONFIG_DIR="${HOME}/.config/nvim"
readonly BACKUP_DIR="${HOME}/backups/nvim"

# SHA256 checksum for v0.10.2
readonly EXPECTED_SHA256="0b395ea5331b5c7b61be1e7d2e1abe53e90b2f3419b0ebe4fea86e4f3d5e73a8"

# ------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------

# Verify SHA256 checksum of downloaded file
verify_checksum() {
    local file="$1"
    local expected="$2"

    log_info "Verifying download integrity..."

    # Calculate the actual checksum
    local actual
    actual=$(sha256sum "$file" | awk '{print $1}')

    if [[ "$actual" != "$expected" ]]; then
        log_error "Checksum verification failed!"
        log_error "Expected: $expected"
        log_error "Got:      $actual"
        return 1
    fi

    log_success "Checksum verification passed"
    return 0
}

# Download file with error checking and progress
download_file() {
    local url="$1"
    local dest="$2"

    log_info "📥 Downloading from: $url"
    echo

    if ! curl -L --progress-bar --output "$dest" "$url"; then
        log_error "❌ Failed to download file"
        return 1
    fi

    echo
    log_success "✓ Download completed: $dest"
    return 0
}

# Backup Neovim configuration
backup_config() {
    if [[ ! -d "$NVIM_CONFIG_DIR" ]]; then
        log_info "ℹ️  No existing Neovim configuration found"
        return 0
    fi

    log_info "💾 Backing up existing Neovim configuration..."

    # Create backup directory
    mkdir -p "$BACKUP_DIR"

    local backup_name="nvim-config-$(date +%Y%m%d_%H%M%S)"
    local backup_path="${BACKUP_DIR}/${backup_name}"

    if ! cp -r "$NVIM_CONFIG_DIR" "$backup_path"; then
        log_error "❌ Failed to backup configuration"
        return 1
    fi

    log_success "✓ Configuration backed up to: $backup_path"
    return 0
}

# ------------------------------------------------------------
# Installation Functions
# ------------------------------------------------------------

check_existing_installation() {
    if command -v nvim &> /dev/null; then
        local installed_version
        installed_version=$(nvim --version | head -n1 | grep -oP 'v\d+\.\d+\.\d+' || echo "unknown")

        echo
        log_warning "⚠️  Neovim is already installed (version: $installed_version)"
        log_info "📦 Target version: $NVIM_VERSION"
        echo

        if [[ "$NON_INTERACTIVE" == "true" ]]; then
            log_info "Non-interactive mode: Proceeding with reinstallation"
        else
            read -rp "Do you want to reinstall? [y/N]: " reinstall
            if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
                log_info "Installation cancelled"
                exit 0
            fi
        fi
        return 1
    fi
    return 0
}

remove_old_installation() {
    log_info "🗑️  Removing old Neovim installation..."

    # Remove old installation directory
    if [[ -d "$NVIM_INSTALL_DIR" ]]; then
        if ! sudo rm -rf "$NVIM_INSTALL_DIR"; then
            log_error "❌ Failed to remove old installation directory"
            return 1
        fi
        log_success "✓ Removed old installation directory"
    fi

    # Remove old symlink
    if [[ -L "$NVIM_BINARY_LINK" ]]; then
        if ! sudo rm -f "$NVIM_BINARY_LINK"; then
            log_error "❌ Failed to remove old symlink"
            return 1
        fi
        log_success "✓ Removed old symlink"
    fi

    return 0
}

install_neovim() {
    log_info "🚀 Installing Neovim..."
    echo

    # Download the tarball
    if ! download_file "$NVIM_DOWNLOAD_URL" "$NVIM_TARBALL"; then
        log_error "❌ Download failed"
        return 1
    fi

    # Verify checksum
    if ! verify_checksum "$NVIM_TARBALL" "$EXPECTED_SHA256"; then
        log_error "❌ Checksum verification failed"
        return 1
    fi

    # Extract to /opt
    log_info "📦 Extracting Neovim to $NVIM_INSTALL_DIR..."
    if ! sudo mkdir -p /opt; then
        log_error "❌ Failed to create /opt directory"
        return 1
    fi

    if ! sudo tar -xzf "$NVIM_TARBALL" -C /opt/; then
        log_error "❌ Failed to extract tarball"
        return 1
    fi

    # Rename to standard location
    if [[ -d "/opt/nvim-linux64" ]]; then
        sudo rm -rf "$NVIM_INSTALL_DIR" 2>/dev/null || true
        if ! sudo mv /opt/nvim-linux64 "$NVIM_INSTALL_DIR"; then
            log_error "❌ Failed to move to installation directory"
            return 1
        fi
    fi

    log_success "✓ Neovim extracted successfully"

    # Create symlink
    log_info "🔗 Creating symlink in /usr/local/bin..."
    if ! sudo ln -sf "${NVIM_INSTALL_DIR}/bin/nvim" "$NVIM_BINARY_LINK"; then
        log_error "❌ Failed to create symlink"
        return 1
    fi

    log_success "✓ Symlink created successfully"

    # Verify installation
    if ! command -v nvim &> /dev/null; then
        log_error "❌ Neovim installation verification failed"
        return 1
    fi

    local installed_version
    installed_version=$(nvim --version | head -n1)
    log_success "✓ Neovim installed successfully: $installed_version"

    return 0
}

# ------------------------------------------------------------
# Main Installation Logic
# ------------------------------------------------------------

main() {
    echo
    log_info "🎯 Starting Neovim installation..."
    echo

    # Backup existing configuration
    if ! backup_config; then
        log_warning "⚠️  Configuration backup failed, but continuing..."
    fi

    # Check if already installed
    if ! check_existing_installation; then
        # User chose to reinstall
        if ! remove_old_installation; then
            log_error "❌ Failed to remove old installation"
            exit 1
        fi
    fi

    # Install Neovim
    if ! install_neovim; then
        log_error "❌ Neovim installation failed"
        exit 1
    fi

    echo
    log_success "===================================="
    log_success "✓ Neovim installation completed!"
    log_success "===================================="
    echo

    # Installation summary
    cat << EOF
📍 Installation Details:
   • Neovim directory: $NVIM_INSTALL_DIR
   • Binary location: $NVIM_BINARY_LINK
   • Config directory: $NVIM_CONFIG_DIR
   • Backup location: $BACKUP_DIR

🚀 Quick Start:
   nvim --version          # Check version
   nvim                    # Launch Neovim
   nvim filename.txt       # Edit a file

📚 Configuration:
   Create or edit: ~/.config/nvim/init.lua

   Popular Neovim distributions:
   • LazyVim   → https://www.lazyvim.org/
   • NvChad    → https://nvchad.com/
   • AstroNvim → https://astronvim.com/
   • Kickstart → https://github.com/nvim-lua/kickstart.nvim

💡 Tips:
   • Run ':Tutor' inside Neovim for an interactive tutorial
   • Run ':checkhealth' to verify your installation
   • Visit ':help' for comprehensive documentation

EOF

    exit 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
