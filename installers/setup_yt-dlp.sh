#!/usr/bin/env bash
#
# setup_yt-dlp.sh - yt-dlp Installation Script
# Description: Installs yt-dlp, a command-line program to download videos from YouTube and other sites
# Category: Utilities
# Usage: ./setup_yt-dlp.sh [OPTIONS]
#        -y, --yes, --non-interactive    Skip confirmation prompts
#        -h, --help                      Show help message
#        Can also be run remotely with: bash <(curl -fsSL https://raw.githubusercontent.com/user/repo/main/installers/setup_yt-dlp.sh)
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
        script_url=$(curl -fsSL -w "%{url_effective}\n" -o /dev/null "https://raw.githubusercontent.com/$repo_user/$repo_name/$repo_branch/installers/setup_yt-dlp.sh" 2>/dev/null || echo "")
        
        if [[ -n "$script_url" ]] && [[ "$script_url" == *"raw.githubusercontent.com"* ]]; then
            # Extract branch from URL if possible
            local url_branch
            url_branch=$(echo "$script_url" | sed -E "s@.*raw.githubusercontent.com/[^/]+/[^/]+/([^/]+)/.*@\1@")
            if [[ -n "$url_branch" ]] && [[ "$url_branch" != "setup_yt-dlp.sh" ]]; then
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
            echo "ERROR: Local library $library_name not found" >&2
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
readonly DL_DIR="${HOME}/Downloads/$APP_NAME"
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
# Main Installation Logic
# ------------------------------------------------------------

main() {
    log_info "Starting yt-dlp installation..."

    # Check if already installed
    if command -v yt-dlp &> /dev/null; then
        local installed_version
        installed_version=$(yt-dlp --version 2>&1 || echo "unknown")
        log_warning "yt-dlp is already installed (version: $installed_version)"
        
        if [[ "$NON_INTERACTIVE" == "true" ]]; then
            log_info "Non-interactive mode: Proceeding with reinstallation"
        else
            read -rp "Do you want to reinstall? [y/N]: " reinstall
            if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
                log_info "Installation cancelled"
                exit 0
            fi
        fi
    fi

    # Install yt-dlp using the dependency management functions
    if install_package "yt-dlp"; then
        log_success "===================================="
        log_success "yt-dlp installation completed!"
        log_success "===================================="
        echo
        echo "yt-dlp is now ready to use. Try it out:"
        echo "  yt-dlp --version"
        echo "  yt-dlp --help"
        echo
        echo "Basic usage examples:"
        echo "  yt-dlp https://www.youtube.com/watch?v=VIDEO_ID"
        echo "  yt-dlp -f bestvideo+bestaudio https://www.youtube.com/watch?v=VIDEO_ID"
        echo
        exit 0
    else
        log_error "yt-dlp installation failed"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi