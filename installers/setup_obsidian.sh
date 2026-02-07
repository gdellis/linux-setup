#!/usr/bin/env bash
#
# setup_obsidian.sh - Obsidian AppImage Installer
# Description: Installs Obsidian as AppImage
# Category: Productivity
# Usage: ./setup_obsidian.sh [OPTIONS]
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
            echo ""
            echo "Description:"
            echo "  Installs Obsidian AppImage from GitHub releases"
            echo "  URL: https://github.com/obsidianmd/obsidian-releases"
            echo ""
            echo "Examples:"
            echo "  ./setup_obsidian.sh                    # Install Obsidian"
            echo "  ./setup_obsidian.sh --non-interactive  # Skip prompts"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Source shared libraries
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../lib/dependencies.sh"

# Constants
readonly APP_NAME="obsidian"
readonly DL_DIR="${HOME}/Downloads/$APP_NAME"
readonly LOG_DIR="${HOME}/logs/$APP_NAME"
readonly LOG_FILE="${LOG_DIR}/$(date +%Y%m%d_%H%M%S)_${APP_NAME}.log"
readonly CONFIG_DIR="$HOME/.config/$APP_NAME"
readonly OBSIDIAN_URL="https://obsidian.md"

# Hardcoded AppImage URL (no scraping, no variables in URL)
# Verified working: https://github.com/obsidianmd/obsidian-releases/releases/download/v1.11.7/Obsidian-1.11.7.AppImage
readonly APPIMAGE_URL="https://github.com/obsidianmd/obsidian-releases/releases/download/v1.11.7/Obsidian-1.11.7.AppImage"

# Ensure directories exist
mkdir -p "$DL_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$CONFIG_DIR"

log_info "Starting Obsidian AppImage installation..."

# Check dependencies
check_dependencies "curl"

# Just use the hardcoded URL
get_download_url() {
    # Eventually we can add version support here
    # For now, just return the hardcoded URL
    echo "$APPIMAGE_URL"
}

# Download Obsidian
download_obsidian() {
    local url="$1"
    local output="$2"
    
    log_info "Downloading Obsidian AppImage..."
    log_info "From: $url"
    
    if ! curl -fL --output "$output" --progress-bar "$url"; then
        log_error "Failed to download Obsidian"
        exit 1
    fi
    
    log_success "Downloaded: $output ($(du -h "$output" | cut -f1))"
}

# Install AppImage
install_appimage() {
    local appimage="$1"
    local install_dir="/opt/obsidian"
    
    log_info "Installing to $install_dir..."
    
    sudo mkdir -p "$install_dir"
    sudo cp "$appimage" "$install_dir/obsidian.AppImage"
    sudo chmod +x "$install_dir/obsidian.AppImage"
    
    sudo ln -sf "$install_dir/obsidian.AppImage" /usr/local/bin/obsidian 2>/dev/null || true
    
    cat > /tmp/obsidian.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Name=Obsidian
Comment=A knowledge base on local Markdown files
Exec=/opt/obsidian/obsidian.AppImage %U
Terminal=false
Type=Application
Icon=obsidian
Categories=Office;TextEditor;Utility;
MimeType=text/plain;text/markdown;
StartupWMClass=obsidian
StartupNotify=true
EOF
    
    sudo mv /tmp/obsidian.desktop /usr/share/applications/
    sudo chmod 644 /usr/share/applications/obsidian.desktop
    sudo update-desktop-database /usr/share/applications/ 2>/dev/null || true
    
    log_success "AppImage installed"
    log_info "Run: obsidian"
}

# Main installation process
main() {
    log_info "=== Obsidian Installer ==="
    
    local download_url
    download_url=$(get_download_url)
    
    log_info "Download URL: $download_url"
    
    local filename="obsidian.appimage"
    local output_path="$DL_DIR/$filename"
    
    if [[ -f "$output_path" ]]; then
        log_warn "File exists: $output_path"
        if [[ "$NON_INTERACTIVE" == "true" ]]; then
            log_info "Using existing file (non-interactive)"
        else
            read -rp "Re-download? [y/N]: " confirm
            [[ "$confirm" == [yY] ]] && rm "$output_path" || log_info "Using existing file"
        fi
    fi
    
    if [[ ! -f "$output_path" ]]; then
        download_obsidian "$download_url" "$output_path"
    fi
    
    install_appimage "$output_path"
    sudo chmod +x "$output_path"
    
    if [[ -d "$CONFIG_DIR" ]]; then
        backup_file "$CONFIG_DIR"
    fi
    
    log_success "Obsidian installation complete!"
    log_info "Config: $CONFIG_DIR"
    log_info "Binary: /opt/obsidian/obsidian.AppImage"
    log_info "Shortcut: obsidian"
    log_info "Visit: $OBSIDIAN_URL"
}

main "$@"