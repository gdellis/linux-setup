#!/usr/bin/env bash
#
# setup_amdgpu.sh - AMD GPU Driver Installation Script
# Description: Installs AMD GPU drivers and ROCm development tools
# Category: System
# Usage: ./setup_amdgpu.sh [OPTIONS]
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
# OS Detection
# ------------------------------------------------------------

# Get OS ID, treating Zorin as Ubuntu
get_os_id() {
    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            zorin)
                echo "ubuntu"
                return 0
                ;;
            ubuntu|debian)
                echo "$ID"
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    fi
    return 1
}

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

# AMD GPU firmware files
readonly AMDGPU_FW_DIR="/lib/firmware/amdgpu"
readonly AMDGPU_FW_FILES=(
    "aldebaran_cap.bin"
    "cyan_skillfish_gpu_info.bin"
    "dcn_3_5_1_dmcub.bin"
    "gc_11_0_0_toc.bin"
    "gc_11_0_3_mes.bin"
    "gc_12_0_0_toc.bin"
    "gc_12_0_1_toc.bin"
    "ip_discovery.bin"
    "navi10_mes.bin"
    "navi12_cap.bin"
    "sienna_cichlid_mes.bin"
    "sienna_cichlid_mes1.bin"
    "smu_14_0_2.bin"
    "vega10_cap.bin"
    "sienna_cichlid_cap.bin"
)
readonly AMDGPU_FW_BASE_URL="https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/amdgpu"

# ------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------

# Patch amdgpu-install script to recognize Zorin OS
patch_amdgpu_install_script() {
    local installer_path="/usr/bin/amdgpu-install"
    local original_pattern='ubuntu|linuxmint|debian)'
    local replacement_pattern='zorin|ubuntu|linuxmint|debian)'

    # Check if the script exists
    if [[ ! -f "$installer_path" ]]; then
        log_warning "amdgpu-install script not found at $installer_path"
        return 0
    fi

    # Check if Zorin is already supported
    if sudo grep -q "$replacement_pattern" "$installer_path"; then
        log_info "Zorin OS already supported in amdgpu-install script"
        return 0
    fi

    # Check if the pattern we want to replace exists
    if sudo grep -q "$original_pattern" "$installer_path"; then
        log_info "Patching amdgpu-install script to support Zorin OS..."
        # Create backup first
        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)
        if sudo cp "$installer_path" "${installer_path}.backup.${timestamp}"; then
            # Replace the pattern to include Zorin
            if sudo sed -i "s/${original_pattern}/${replacement_pattern}/g" "$installer_path"; then
                log_success "Successfully patched amdgpu-install script to support Zorin OS"
                return 0
            else
                log_error "Failed to patch amdgpu-install script"
                return 1
            fi
        else
            log_error "Failed to create backup of amdgpu-install script"
            return 1
        fi
    else
        log_info "amdgpu-install script pattern not found, skipping patch"
    fi

    return 0
}

# Install AMD GPU drivers
install_amdgpu_drivers() {
    log_info "Installing AMD GPU drivers..."

    # Ensure dependencies
    ensure_dependencies --auto-install curl wget apt-transport-https

    # Get OS ID
    local os_id
    os_id=$(get_os_id) || {
        log_error "Unsupported OS. This script is designed for Ubuntu/Debian systems."
        return 1
    }

    # AMD GPU installer URL - dynamically set based on OS
    readonly AMDGPU_DEB_URL="https://repo.radeon.com/amdgpu-install/7.1.1/$os_id/jammy/amdgpu-install_7.1.1.70101-1_all.deb"
    readonly AMDGPU_DEB_FILE="$DL_DIR/amdgpu-install_7.1.1.70101-1_all.deb"
    readonly AMDGPU_DEB_SHA256=""  # TODO: Add checksum when available

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
    if ! install_package "$AMDGPU_DEB_FILE"; then
        log_error "Failed to install AMD GPU installer package"
        return 1
    fi

    # Patch the amdgpu-install script to recognize Zorin OS
    if ! patch_amdgpu_install_script; then
        log_warning "Failed to patch amdgpu-install script for Zorin OS support"
    fi

    # Run the AMD GPU installer with graphics and ROCm use cases
    log_info "Running AMD GPU installer..."
    if ! amdgpu-install -y --usecase=graphics,rocm; then
        log_error "Failed to install AMD GPU drivers"
        return 1
    fi

    log_success "AMD GPU drivers installed successfully"
}

# Download AMD GPU firmware files
download_amdgpu_firmware() {
    log_info "Downloading AMD GPU firmware files..."

    # Ensure dependencies
    ensure_dependencies --auto-install git

    # Create target directory if it doesn't exist
    log_info "Creating firmware directory: $AMDGPU_FW_DIR"
    if ! sudo mkdir -p "$AMDGPU_FW_DIR"; then
        log_error "Failed to create firmware directory: $AMDGPU_FW_DIR"
        return 1
    fi

    local file_downloaded=0
    local file
    local _path

    for file in "${AMDGPU_FW_FILES[@]}"; do
        _path="$AMDGPU_FW_DIR/$file"

        # Skip if file already exists
        if [[ -f "$_path" ]]; then
            log_info "Firmware $file already exists, skipping..."
            continue
        fi

        # Download the firmware file
        log_info "Downloading firmware: $file"
        if sudo curl -fsSL -o "$_path" "$AMDGPU_FW_BASE_URL/$file"; then
            file_downloaded=1
            log_success "Firmware $file downloaded successfully."
        else
            log_warning "Failed to download $file."
        fi
    done

    # Update initramfs if any files were downloaded
    if [[ $file_downloaded -gt 0 ]]; then
        log_info "Updating initramfs..."
        if sudo update-initramfs -u; then
            log_success "Initramfs updated successfully."
        else
            log_warning "Failed to update initramfs."
        fi
    else
        log_info "No new firmware files downloaded, initramfs update not needed."
    fi

    return 0
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

    # Source OS information
    . /etc/os-release
    log_info "Detected OS: $ID $VERSION_ID"

    # Get OS ID (treat Zorin as Ubuntu)
    local os_id
    os_id=$(get_os_id) || {
        log_error "Unsupported OS: $ID. This script is designed for Ubuntu/Debian systems."
        exit 1
    }

    if [[ "$ID" == "zorin" ]]; then
        log_info "Detected Zorin OS, treating as Ubuntu"
    fi

    log_info "Using OS ID: $os_id for AMD GPU installation"

    # Download AMD GPU firmware files
    if ! download_amdgpu_firmware; then
        log_warning "AMD GPU firmware download failed. Continuing with installation..."
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
