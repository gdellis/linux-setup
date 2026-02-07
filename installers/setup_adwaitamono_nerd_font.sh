#!/usr/bin/env bash
#
# setup_adwaitamono_nerd_font.sh - AdwaitaMono Nerd Font Installation Script
# Description: Downloads and installs AdwaitaMono Nerd Font from official releases
# Category: Desktop
# Usage: ./setup_adwaitamono_nerd_font.sh [OPTIONS]
#        -y, --yes, --non-interactive    Skip confirmation prompts
#        -h, --help                      Show this help message
#        Can also be run remotely with: bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/installers/setup_adwaitamono_nerd_font.sh)
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
    if [[ "$script_path" == /tmp/* ]] || [[ "$script_path" == /var/tmp/* ]]; then
        return 0
    else
        return 1
    fi
}

# Function to source library remotely or locally
source_library() {
    local library_name="$1"
    
    if is_running_remotely; then
        local repo_user="${REPO_USER:-gdellis}"
        local repo_name="${REPO_NAME:-linux-setup}"
        local repo_branch="${REPO_BRANCH:-main}"
        
        echo "Sourcing $library_name from remote repository ($repo_user/$repo_name/$repo_branch)..." >&2
        if ! source <(curl -fsSL "https://raw.githubusercontent.com/$repo_user/$repo_name/$repo_branch/lib/$library_name"); then
            echo "ERROR: Failed to source $library_name from remote repository" >&2
            exit 1
        fi
    else
        local script_dir
        script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
        
        if [[ -f "$script_dir/../lib/$library_name" ]]; then
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
SCRIPT_NAME=$(basename "$0" .sh)
readonly APP_NAME="${SCRIPT_NAME/setup_/}"
readonly DL_DIR="${HOME}/fonts/$APP_NAME"
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

cleanup()
{
    local exit_code=$?
    log_info "Cleaning up..."
    cd "$ORIG_PWD" 2>/dev/null || true
    log_info "Cleanup complete"
    exit $exit_code
}

# Set trap for various exit signals
trap cleanup EXIT INT TERM ERR

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

readonly NERD_FONTS_VERSION="v3.4.0"
readonly FONT_DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/AdwaitaMono.tar.xz"
readonly FONT_ARCHIVE="$DL_DIR/AdwaitaMono.tar.xz"
readonly FONT_EXTRACT_DIR="$DL_DIR/AdwaitaMono"
readonly SYSTEM_FONT_DIR="$HOME/.local/share/fonts"

# ------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------

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

download_font() {
    log_info "Downloading AdwaitaMono Nerd Font..."
    
    ensure_dependencies --auto-install curl
    
    if ! download_file "$FONT_DOWNLOAD_URL" "$FONT_ARCHIVE"; then
        log_error "Failed to download AdwaitaMono Nerd Font"
        return 1
    fi
    
    log_success "AdwaitaMono Nerd Font downloaded successfully"
}

extract_font() {
    log_info "Extracting font archive..."
    
    ensure_dependencies --auto-install tar
    
    if [[ -d "$FONT_EXTRACT_DIR" ]]; then
        log_info "Removing existing extraction directory..."
        rm -rf "$FONT_EXTRACT_DIR"
    fi
    
    mkdir -p "$FONT_EXTRACT_DIR"
    
    if ! tar -xf "$FONT_ARCHIVE" -C "$FONT_EXTRACT_DIR"; then
        log_error "Failed to extract font archive"
        return 1
    fi
    
    log_success "Font archive extracted successfully"
}

install_font() {
    log_info "Installing fonts to system..."
    
    if [[ ! -d "$SYSTEM_FONT_DIR" ]]; then
        log_info "Creating font directory: $SYSTEM_FONT_DIR"
        mkdir -p "$SYSTEM_FONT_DIR"
    fi
    
    local font_files=("$FONT_EXTRACT_DIR"/*.ttf "$FONT_EXTRACT_DIR"/*.otf)
    
    if [[ ${#font_files[@]} -eq 0 ]]; then
        log_error "No font files found in extraction directory"
        return 1
    fi
    
    log_info "Copying ${#font_files[@]} font files to $SYSTEM_FONT_DIR..."
    
    local copied_count=0
    for font_file in "${font_files[@]}"; do
        if [[ -f "$font_file" ]]; then
            if cp "$font_file" "$SYSTEM_FONT_DIR/"; then
                ((copied_count++))
            else
                log_warning "Failed to copy: $(basename "$font_file")"
            fi
        fi
    done
    
    if [[ $copied_count -eq 0 ]]; then
        log_error "No fonts were successfully installed"
        return 1
    fi
    
    log_success "$copied_count font files installed successfully"
}

update_font_cache() {
    log_info "Updating font cache..."
    
    if command -v fc-cache >/dev/null 2>&1; then
        if fc-cache -f "$SYSTEM_FONT_DIR"; then
            log_success "Font cache updated successfully"
            return 0
        else
            log_warning "Font cache update may have failed"
        fi
    else
        log_warning "fc-cache command not found. You may need to install fontconfig"
    fi
    
    return 0
}

cleanup_files() {
    log_info "Cleaning up temporary files..."
    
    if [[ -d "$FONT_EXTRACT_DIR" ]]; then
        rm -rf "$FONT_EXTRACT_DIR"
        log_info "Removed extraction directory"
    fi
    
    if [[ -f "$FONT_ARCHIVE" ]] && [[ "$NON_INTERACTIVE" == "true" ]]; then
        rm -f "$FONT_ARCHIVE"
        log_info "Removed downloaded archive"
    elif [[ -f "$FONT_ARCHIVE" ]]; then
        log_info "Downloaded archive preserved at: $FONT_ARCHIVE"
    fi
}

# ------------------------------------------------------------
# Main Installation Logic
# ------------------------------------------------------------

main() {
    log_info "Starting AdwaitaMono Nerd Font installation..."
    
    # Install fontconfig if needed for fc-cache
    if ! command -v fc-cache >/dev/null 2>&1; then
        log_info "Installing fontconfig for font cache management..."
        if ! install_package fontconfig; then
            log_warning "Failed to install fontconfig. Continuing without font cache update."
        fi
    fi
    
    # Download font
    if ! download_font; then
        log_error "Font download failed"
        exit 1
    fi
    
    # Extract font
    if ! extract_font; then
        log_error "Font extraction failed"
        exit 1
    fi
    
    # Install font
    if ! install_font; then
        log_error "Font installation failed"
        exit 1
    fi
    
    # Update font cache
    if ! update_font_cache; then
        log_error "Font cache update failed"
        exit 1
    fi
    
    # Cleanup
    cleanup_files
    
    log_success "========================================"
    log_success "✓ AdwaitaMono Nerd Font installation completed!"
    log_success "========================================"
    log_info "Fonts installed to: $SYSTEM_FONT_DIR"
    log_info "You can now use AdwaitaMono Nerd Font in your terminal and applications."
    log_info "Look for font names containing 'AdwaitaMono' in your application font settings."
    exit 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi