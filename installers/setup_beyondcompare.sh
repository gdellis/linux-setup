#!/usr/bin/env bash
#
# setup_beyondcompare.sh - Beyond Compare Installation Script
# Description: Downloads and installs Beyond Compare file comparison tool
# Category: Development
# Usage: ./setup_beyondcompare.sh [OPTIONS]
#        -y, --yes, --non-interactive    Skip confirmation prompts
#        -h, --help                      Show help message
#        Can also be run remotely with: bash <(curl -fsSL https://raw.githubusercontent.com/user/repo/main/installers/setup_beyondcompare.sh)
#        Automatically detects branch when run from non-main branches
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
        # Source library from GitHub using environment variables with defaults
        local repo_user="${REPO_USER:-gdellis}"
        local repo_name="${REPO_NAME:-linux-setup}"
        local repo_branch="${REPO_BRANCH:-main}"

        # For remote execution, try to detect branch from script URL if possible
        # This is an enhancement to handle cases where the script is run from a non-default branch
        local script_url
        script_url=$(curl -fsSL -w "%{url_effective}\n" -o /dev/null "https://raw.githubusercontent.com/$repo_user/$repo_name/$repo_branch/installers/setup_beyondcompare.sh" 2>/dev/null || echo "")

        if [[ -n "$script_url" ]] && [[ "$script_url" == *"raw.githubusercontent.com"* ]]; then
            # Extract branch from URL if possible
            local url_branch
            url_branch=$(echo "$script_url" | sed -E "s@.*raw.githubusercontent.com/[^/]+/[^/]+/([^/]+)/.*@\1@")
            if [[ -n "$url_branch" ]] && [[ "$url_branch" != "setup_beyondcompare.sh" ]]; then
                repo_branch="$url_branch"
            fi
        fi

        echo "Sourcing $library_name from remote repository ($repo_user/$repo_name/$repo_branch)..." >&2
        # shellcheck disable=SC1090
        if ! source <(curl -fsSL "https://raw.githubusercontent.com/$repo_user/$repo_name/$repo_branch/lib/$library_name"); then
            echo "ERROR: Failed to source $library_name from remote repository" >&2
            echo "Tried URL: https://raw.githubusercontent.com/$repo_user/$repo_name/$repo_branch/lib/$library_name" >&2
            echo "Please ensure REPO_USER, REPO_NAME, and REPO_BRANCH environment variables are set correctly" >&2
            echo "Current values: REPO_USER=$repo_user, REPO_NAME=$repo_name, REPO_BRANCH=$repo_branch" >&2
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
source_library "dependencies.sh"

# Save and change directories
readonly ORIG_PWD=$(pwd)

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

# Beyond Compare configuration
readonly BC_VERSION="5.1.7.31736"
readonly BC_ARCH="amd64"
readonly BC_PACKAGE_NAME="bcompare-${BC_VERSION}_${BC_ARCH}.deb"
readonly BC_DOWNLOAD_URL="https://www.scootersoftware.com/files/${BC_PACKAGE_NAME}"
readonly BC_DOWNLOAD_FILE="$DL_DIR/$BC_PACKAGE_NAME"

# ------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------

# Download Beyond Compare package
download_bcompare() {
    log_info "Downloading Beyond Compare $BC_VERSION..."

    # Ensure dependencies
    ensure_dependencies --auto-install wget curl

    # Update package lists
    log_info "Updating package lists..."
    update_package_lists

    # Download Beyond Compare
    log_info "Downloading Beyond Compare from: $BC_DOWNLOAD_URL"
    if ! curl -fsSL --output "$BC_DOWNLOAD_FILE" "$BC_DOWNLOAD_URL"; then
        log_error "Failed to download Beyond Compare"
        return 1
    fi

    log_success "Beyond Compare downloaded successfully to $BC_DOWNLOAD_FILE"
    return 0
}

# Install Beyond Compare package
install_bcompare() {
    log_info "Installing Beyond Compare..."

    # Install Beyond Compare using apt
    log_info "Installing Beyond Compare package..."
    if ! sudo apt install -y "./$BC_DOWNLOAD_FILE"; then
        log_error "Failed to install Beyond Compare"
        return 1
    fi

    log_success "Beyond Compare installed successfully"
    return 0
}

# ------------------------------------------------------------
# Main Installation Logic
# ------------------------------------------------------------

main() {
    log_info "Starting Beyond Compare installation..."

    # Check system architecture
    local system_arch
    system_arch=$(uname -m)
    case "$system_arch" in
        x86_64)
            log_info "Detected system architecture: $system_arch (supported)"
            ;;
        *)
            log_warning "System architecture: $system_arch - Beyond Compare may not be fully compatible"
            ;;
    esac

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

    # Confirm installation with user if not in non-interactive mode
    if [[ "$NON_INTERACTIVE" != "true" ]]; then
        echo
        log_warning "Beyond Compare is commercial software that requires a license for full functionality."
        log_warning "A free trial is available for evaluation purposes."
        echo
        read -r -p "Do you want to continue installing Beyond Compare? (y/N): " confirm
        case "$confirm" in
            [yY]|[yY][eE][sS])
                log_info "Continuing with installation..."
                ;;
            *)
                log_info "Installation cancelled by user"
                exit 0
                ;;
        esac
    fi

    # Download Beyond Compare
    if ! download_bcompare; then
        log_error "Beyond Compare download failed"
        exit 1
    fi

    # Install Beyond Compare
    if ! install_bcompare; then
        log_error "Beyond Compare installation failed"
        exit 1
    fi

    # Verify installation
    if command -v bcompare >/dev/null 2>&1; then
        log_success "Beyond Compare installation verified successfully"
    else
        log_warning "Could not verify Beyond Compare installation - it may not be in PATH"
    fi

    log_success "=============================================="
    log_success "✓ Beyond Compare installation completed!"
    log_success "=============================================="
    log_info "You can now launch Beyond Compare from your applications menu"
    log_info "or by running 'bcompare' from the terminal."
    log_info ""
    log_info "Note: Beyond Compare is commercial software requiring a license."
    log_info "Visit https://www.scootersoftware.com to purchase a license."
    exit 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
