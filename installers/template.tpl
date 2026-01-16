#!/usr/bin/env bash
#
# Template for creating new installer scripts
# Description: Boilerplate installer script with logging, error handling, and checksum verification
# Usage: Use new_installer.sh to create a new script from this template
#        Can also be run remotely with: bash <(curl -fsSL https://raw.githubusercontent.com/user/repo/main/installers/script.sh)
#        Automatically detects branch when run from non-main branches
#

set -euo pipefail

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
        script_url=$(curl -fsSL -w "%{url_effective}\n" -o /dev/null "https://raw.githubusercontent.com/$repo_user/$repo_name/$repo_branch/installers/template.tpl" 2>/dev/null || echo "")
        
        if [[ -n "$script_url" ]] && [[ "$script_url" == *"raw.githubusercontent.com"* ]]; then
            # Extract branch from URL if possible
            local url_branch
            url_branch=$(echo "$script_url" | sed -E "s@.*raw.githubusercontent.com/[^/]+/[^/]+/([^/]+)/.*@\1@")
            if [[ -n "$url_branch" ]] && [[ "$url_branch" != "template.tpl" ]]; then
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

# Example configuration (customize as needed)
# readonly DOWNLOAD_URL="https://example.com/package.deb"
# readonly DOWNLOAD_FILE="$DL_DIR/package.deb"
# readonly EXPECTED_SHA256="your_sha256_checksum_here"

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

# Download file with error checking
download_file() {
    local url="$1"
    local dest="$2"

    log_info "Downloading from: $url"

    if ! curl -fsSL --output "$dest" "$url"; then
        log_error "Failed to download file"
        return 1
    fi

    log_success "Download completed: $dest"
    return 0
}

# ------------------------------------------------------------
# Main Installation Logic
# ------------------------------------------------------------

main() {
    log_info "Starting $APP_NAME installation..."

    # Example installation workflow:
    # 1. Download the package
    # if ! download_file "$DOWNLOAD_URL" "$DOWNLOAD_FILE"; then
    #     log_error "Download failed"
    #     exit 1
    # fi

    # 2. Verify checksum (if available)
    # if ! verify_checksum "$DOWNLOAD_FILE" "$EXPECTED_SHA256"; then
    #     log_error "Checksum verification failed"
    #     exit 1
    # fi

    # 3. Install the package
    # if ! sudo nala install -y "$DOWNLOAD_FILE"; then
    #     log_error "Installation failed"
    #     exit 1
    # fi

    # Add your installation logic here
    log_warning "TODO: Add installation logic"

    log_success "$APP_NAME installation completed!"
    exit 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
