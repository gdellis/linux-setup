#!/usr/bin/env bash
#
# setup_obsidian.sh - Obsidian Notetaking App Installer
# Description: Installs Obsidian, a powerful knowledge base that works on local Markdown files
# Category: Productivity
# Usage: ./setup_obsidian.sh [OPTIONS]
#        -y, --yes, --non-interactive    Skip confirmation prompts
#        -h, --help                      Show help message
#        --version <version>             Install specific version (default: latest)
#        --format <format>               Install format: appimage, deb, snap (default: appimage)
#

set -euo pipefail

# Parse command line arguments
NON_INTERACTIVE=false
VERSION="latest"
FORMAT="appimage"

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
            echo "  --version <version>             Install specific version (default: latest)"
            echo "  --format <format>               Install format: appimage, deb, snap (default: appimage)"
            echo ""
            echo "Description:"
            echo "  Installs Obsidian, a powerful knowledge base that works on local Markdown files."
            echo "  Obsidian lets you turn a folder of Markdown files into your personal knowledge base."
            echo ""
            echo "Examples:"
            echo "  ./setup_obsidian.sh"
            echo "  ./setup_obsidian.sh --version 1.11.7 --format deb"
            echo "  ./setup_obsidian.sh --format snap --non-interactive"
            exit 0
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
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
readonly VERSION
readonly FORMAT
readonly DL_DIR="${HOME}/Downloads/$APP_NAME"
readonly LOG_DIR="${HOME}/logs/$APP_NAME"
readonly LOG_FILE="${LOG_DIR}/$(date +%Y%m%d_%H%M%S)_${APP_NAME}.log"
readonly CONFIG_DIR="$HOME/.config/obsidian"
readonly OBSIDIAN_URL="https://obsidian.md"

# Ensure directories exist
mkdir -p "$DL_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$CONFIG_DIR"

log_info "Starting Obsidian installation..."
log_info "Format: $FORMAT"
log_info "Version: ${VERSION:-latest}"

# Check dependencies
check_dependencies "curl" "wget"

# Get latest version if not specified
get_latest_version() {
    log_info "Fetching latest Obsidian version..."
    
    # Scrape the download page or use GitHub API
    local latest_info
    if latest_info=$(curl -fsSL "https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest" 2>/dev/null); then
        echo "$latest_info" | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/'
    else
        # Fallback version from the page (as of Feb 2025: v1.11.7)
        echo "1.11.7"
    fi
}

# Determine download URL
get_download_url() {
    local version="$1"
    local format="$2"
    
    # If version is "latest", fetch it or use fallback
    if [[ "$version" == "latest" ]]; then
        version=$(get_latest_version)
        log_info "Latest version: $version"
    fi
    
    # Strip 'v' prefix if present
    version="${version#v}"
    
    case "$format" in
        appimage)
            echo "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/Obsidian-${version}.AppImage"
            ;;
        deb)
            echo "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/obsidian_${version}_amd64.deb"
            ;;
        snap)
            # Snap uses a different name pattern
            echo "snap"
            ;;
        *)
            log_error "Unsupported format: $format"
            exit 1
            ;;
    esac
}

# Download Obsidian
download_obsidian() {
    local url="$1"
    local output="$2"
    
    log_info "Downloading Obsidian from: $url"
    
    if ! curl -fsSL --output "$output" --progress-bar "$url"; then
        log_error "Failed to download Obsidian"
        exit 1
    fi
    
    log_success "Download complete: $output"
}

# Install AppImage
install_appimage() {
    local appimage_path="$1"
    local install_dir="/opt/obsidian"
    
    log_info "Installing Obsidian AppImage..."
    
    # Create install directory
    sudo mkdir -p "$install_dir"
    sudo mv "$appimage_path" "$install_dir/obsidian.AppImage"
    sudo chmod +x "$install_dir/obsidian.AppImage"
    
    # Create desktop entry
    cat > /tmp/obsidian.desktop << 'EOF'
[Desktop Entry]
Name=Obsidian
Comment=A knowledge base that works on local Markdown files
Exec=/opt/obsidian/obsidian.AppImage %U
Terminal=false
Type=Application
Icon=obsidian
Categories=Office;TextEditor;Utility;
MimeType=text/plain;text/markdown;
EOF
    
    sudo mv /tmp/obsidian.desktop /usr/share/applications/
    sudo cp "$SCRIPT_DIR/../assets/obsidian-icon.png" /usr/share/icons/hicolor/256x256/apps/obsidian.png 2>/dev/null || true
    
    log_success "AppImage installed to $install_dir"
}

# Install Deb package
install_deb() {
    local deb_path="$1"
    
    log_info "Installing Obsidian deb package..."
    
    if sudo apt-get install -y "$deb_path" 2>/dev/null || sudo dpkg -i "$deb_path"; then
        log_success "Deb package installed"
    else
        log_error "Failed to install deb package"
        exit 1
    fi
}

# Install Snap
install_snap() {
    log_info "Installing Obsidian via Snap..."
    
    if command_exists snap; then
        sudo snap install obsidian --classic
        log_success "Snap package installed"
    else
        log_error "Snap is not installed on this system"
        exit 1
    fi
}

# Main installation process
main() {
    log_info "=== Obsidian Installer Started ==="
    
    # Get download URL
    local download_url
    download_url=$(get_download_url "$VERSION" "$FORMAT")
    
    # Handle snap separately
    if [[ "$FORMAT" == "snap" ]]; then
        install_snap
        log_success "Obsidian installation complete!"
        log_info "Launch Obsidian from your applications menu"
        exit 0
    fi
    
    log_info "Download URL: $download_url"
    
    # Download file
    local filename
    filename="obsidian-${VERSION:-latest}.${FORMAT}"
    local output_path="$DL_DIR/$filename"
    
    if [[ -f "$output_path" ]]; then
        log_warn "File already exists: $output_path"
        read -rp "Delete and re-download? [y/N]: " confirm
        if [[ "$confirm" == [yY] ]]; then
            rm "$output_path"
        else
            log_info "Using existing file"
        fi
    fi
    
    if [[ ! -f "$output_path" ]]; then
        download_obsidian "$download_url" "$output_path"
    fi
    
    # Install based on format
    case "$FORMAT" in
        appimage)
            install_appimage "$output_path"
            ;;
        deb)
            install_deb "$output_path"
            ;;
    esac
    
    # Create config backup
    if [[ -d "$CONFIG_DIR" ]]; then
        backup_file "$CONFIG_DIR"
    fi
    
    log_success "Obsidian installation complete!"
    log_info "Configuration directory: $CONFIG_DIR"
    log_info "Launch Obsidian from your applications menu"
    log_info "Visit $OBSIDIAN_URL to learn more"
}

# Run main if executed directly
main "$@"