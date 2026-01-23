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
# Latest version as of script creation
readonly BEYOND_COMPARE_VERSION="5.1.7.31736"
readonly BEYOND_COMPARE_URL="https://www.scootersoftware.com/files/bcompare-${BEYOND_COMPARE_VERSION}_amd64.deb"
readonly BEYOND_COMPARE_FILE="$DL_DIR/bcompare-${BEYOND_COMPARE_VERSION}_amd64.deb"
readonly GPG_KEY_URL="https://www.scootersoftware.com/DEB-GPG-KEY-scootersoftware.asc"
readonly GPG_KEY_FILE="$DL_DIR/DEB-GPG-KEY-scootersoftware.asc"
readonly REPO_LIST_URL="https://www.scootersoftware.com/scootersoftware.list"
readonly REPO_LIST_FILE="$DL_DIR/scootersoftware.list"

# ------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------

# Check if Beyond Compare is already installed
is_beyondcompare_installed() {
    if command -v bcompare >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Get installed version of Beyond Compare
get_installed_version() {
    if is_beyondcompare_installed; then
        echo "Beyond Compare is installed"
    else
        echo "Not installed"
    fi
}

# Install Beyond Compare
install_beyondcompare() {
    log_info "Installing Beyond Compare..."

    # Ensure dependencies
    ensure_dependencies --auto-install curl wget

    # Update package lists
    log_info "Updating package lists..."
    update_package_lists

    # Check if already installed
    if is_beyondcompare_installed; then
        local installed_version
        installed_version=$(get_installed_version)
        log_warning "Beyond Compare is already installed (version: $installed_version)"
        if [[ "$NON_INTERACTIVE" == "false" ]]; then
            if ! confirm_action "Do you want to continue with the installation?"; then
                log_info "Installation cancelled by user"
                return 0
            fi
        else
            log_info "Continuing with installation in non-interactive mode"
        fi
    fi

    # Download Beyond Compare package
    log_info "Downloading Beyond Compare v${BEYOND_COMPARE_VERSION}..."
    if ! wget --show-progress -qO "$BEYOND_COMPARE_FILE" "$BEYOND_COMPARE_URL"; then
        log_error "Failed to download Beyond Compare"
        return 1
    fi

    # Install Beyond Compare package
    log_info "Installing Beyond Compare..."
    if ! install_package "$BEYOND_COMPARE_FILE"; then
        log_error "Failed to install Beyond Compare package"
        return 1
    fi

    # Add repository for future updates (optional)
    if [[ "$NON_INTERACTIVE" == "false" ]]; then
        if confirm_action "Do you want to add the Scooter Software repository for automatic updates?"; then
            add_beyondcompare_repo
        fi
    else
        # In non-interactive mode, add the repo by default
        add_beyondcompare_repo
    fi

    log_success "Beyond Compare installed successfully"
}

# Add Beyond Compare repository for automatic updates
add_beyondcompare_repo() {
    log_info "Adding Beyond Compare repository for automatic updates..."

    # Download GPG key
    if ! wget -qO "$GPG_KEY_FILE" "$GPG_KEY_URL"; then
        log_warning "Failed to download GPG key. Continuing without repository setup..."
        return 1
    fi

    # Download repository list
    if ! wget -qO "$REPO_LIST_FILE" "$REPO_LIST_URL"; then
        log_warning "Failed to download repository list. Continuing without repository setup..."
        return 1
    fi

    # Install GPG key
    if ! sudo cp "$GPG_KEY_FILE" /etc/apt/trusted.gpg.d/; then
        log_warning "Failed to install GPG key. Continuing without repository setup..."
        return 1
    fi

    # Install repository list
    if ! sudo cp "$REPO_LIST_FILE" /etc/apt/sources.list.d/; then
        log_warning "Failed to install repository list. Continuing without repository setup..."
        return 1
    fi

    # Update package lists
    if ! update_package_lists; then
        log_warning "Failed to update package lists after adding repository"
        return 1
    fi

    log_success "Beyond Compare repository added successfully"
}

# ------------------------------------------------------------
# Main Installation Logic
# ------------------------------------------------------------

main() {
    log_info "Starting Beyond Compare installation..."
    log_info "Current Beyond Compare installation status: $(get_installed_version)"

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
        ubuntu|debian|zorin|linuxmint|pop)
            log_info "OS is supported: $ID"
            ;;
        *)
            log_warning "OS $ID may not be officially supported. Proceeding with installation anyway."
            ;;
    esac

    # Check if user wants to prevent repository addition
    if [[ "$NON_INTERACTIVE" == "false" ]]; then
        if confirm_action "Do you want to prevent the automatic addition of the Beyond Compare repository?"; then
            log_info "Creating /etc/default/bcompare to prevent repository addition..."
            if ! sudo touch /etc/default/bcompare; then
                log_warning "Failed to create /etc/default/bcompare. Repository may be added automatically."
            fi
        fi
    fi

    # Install Beyond Compare
    if ! install_beyondcompare; then
        log_error "Beyond Compare installation failed"
        exit 1
    fi

    log_success "========================================"
    log_success "✓ Beyond Compare installation completed!"
    log_success "========================================"
    log_info "You can now launch Beyond Compare from your applications menu"
    log_info "or by running 'bcompare' from the terminal."
    log_info "Installed version: $(get_installed_version)"
    exit 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi