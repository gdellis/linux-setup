#!/usr/bin/env bash
#
# setup_shell_prompt.sh - Shell Prompt Setup Installer
# Description: Downloads and installs Starship prompt with AdwaitaMono Nerd Font
# Category: Desktop
# Usage: ./setup_shell_prompt.sh [OPTIONS]
#        -y, --yes, --non-interactive    Skip confirmation prompts
#        -h, --help                      Show this help message
#        Can also be run remotely with: bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/installers/setup_shell_prompt.sh)
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
readonly FONT_NAME="AdwaitaMono Nerd Font"
readonly FONT_DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/AdwaitaMono.tar.xz"
readonly FONT_ARCHIVE="$DL_DIR/AdwaitaMono.tar.xz"
readonly FONT_EXTRACT_DIR="$DL_DIR/AdwaitaMono"
readonly SYSTEM_FONT_DIR="$HOME/.local/share/fonts"
readonly STARSHIP_INSTALL_URL="https://starship.rs/install.sh"
readonly STARSHIP_BIN_DIR="$HOME/.local/bin"

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

# Check if font is already installed
font_installed() {
    local font_name="$1"
    
    if command -v fc-list >/dev/null 2>&1; then
        if fc-list :family | grep -iq "$font_name"; then
            log_info "Font '$font_name' is already installed"
            return 0
        fi
    fi
    
    return 1
}

# Install AdwaitaMono Nerd Font
install_font() {
    log_info "Installing font '$FONT_NAME'..."
    
    ensure_dependencies --auto-install curl tar
    
    # Download font
    if [[ ! -f "$FONT_ARCHIVE" ]]; then
        if ! download_file "$FONT_DOWNLOAD_URL" "$FONT_ARCHIVE"; then
            log_error "Font download failed"
            return 1
        fi
    else
        log_info "Using cached font archive: $FONT_ARCHIVE"
    fi
    
    # Extract font
    if [[ -d "$FONT_EXTRACT_DIR" ]]; then
        log_info "Removing existing extraction directory..."
        rm -rf "$FONT_EXTRACT_DIR"
    fi
    
    mkdir -p "$FONT_EXTRACT_DIR"
    
    if ! tar -xf "$FONT_ARCHIVE" -C "$FONT_EXTRACT_DIR"; then
        log_error "Failed to extract font archive"
        return 1
    fi
    
    # Create font directory under system font dir with font family name
    local font_install_dir="$SYSTEM_FONT_DIR/$FONT_NAME"
    if [[ -d "$font_install_dir" ]]; then
        log_info "Removing existing font installation directory..."
        rm -rf "$font_install_dir"
    fi
    
    mkdir -p "$font_install_dir"
    
    # Copy font files
    local font_files=("$FONT_EXTRACT_DIR"/*.ttf)
    
    if [[ ${#font_files[@]} -eq 0 ]]; then
        log_error "No font files found in extraction directory"
        return 1
    fi
    
    log_info "Copying ${#font_files[@]} font files..."
    
    local copied_count=0
    for font_file in "${font_files[@]}"; do
        if [[ -f "$font_file" ]]; then
            if cp "$font_file" "$font_install_dir/"; then
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
    
    log_success "Font installed successfully ($copied_count files)"
    
    # Update font cache
    if command -v fc-cache >/dev/null 2>&1; then
        log_info "Updating font cache..."
        if fc-cache -f "$SYSTEM_FONT_DIR"; then
            log_success "Font cache updated"
        else
            log_warning "Font cache update may have failed"
        fi
    else
        log_warning "fc-cache not available in this system"
    fi
    
    return 0
}

# Install Starship prompt
install_starship() {
    if command -v starship >/dev/null 2>&1; then
        log_info "Starship is already installed"
        return 0
    fi
    
    log_info "Installing Starship..."
    
    ensure_dependencies --auto-install curl
    
    # Set installation directory
    export BINDIR="$STARSHIP_BIN_DIR"
    
    # Install via pipe (following official method)
    if ! curl -sSL "$STARSHIP_INSTALL_URL" | sh -s -- --yes; then
        log_error "Starship installation failed"
        return 1
    fi
    
    log_success "Starship installed successfully"
    
    # Check if binary exists
    if [[ ! -f "$STARSHIP_BIN_DIR/starship" ]] && ! command -v starship >/dev/null 2>&1; then
        log_error "Starship binary not found after installation"
        return 1
    fi
    
    return 0
}

# Add Starship binary directory to PATH
add_to_path() {
    local targets=()
    
    # Add to bashrc if exists
    if [[ -f "$HOME/.bashrc" ]]; then
        targets+=("$HOME/.bashrc")
    fi
    
    # Add to zshrc if exists
    if [[ -f "$HOME/.zshrc" ]]; then
        targets+=("$HOME/.zshrc")
    fi
    
    # Add fish config if fish is installed
    if command -v fish >/dev/null 2>&1; then
        local fish_config_dir="$HOME/.config/fish"
        local fish_config_file="$fish_config_dir/config.fish"
        
        if [[ -f "$fish_config_file" ]]; then
            targets+=("$fish_config_file")
        fi
    fi
    
    local path_added=false
    
    for target_file in "${targets[@]}"; do
        if [[ -f "$target_file" ]]; then
            if ! grep -q "$STARSHIP_BIN_DIR" "$target_file"; then
                log_info "Adding $STARSHIP_BIN_DIR to PATH in $target_file..."
                if ! echo "export PATH=\"$STARSHIP_BIN_DIR:\$PATH\"" >> "$target_file"; then
                    log_warning "Failed to update $target_file"
                    continue
                fi
                path_added=true
            else
                log_info "Starship bin directory already in PATH in $target_file"
            fi
        fi
    done
    
    if [[ "$path_added" == "true" ]]; then
        log_success "Added $STARSHIP_BIN_DIR to PATH"
        log_info "Restart your shell or run 'source' on your config file to update PATH"
    else
        log_info "Starship already in PATH or no shell config files found"
    fi
    
    return 0
}

# Configure shells to use Starship
configure_shell() {
    log_info "Configuring shells to use Starship..."
    
    local configure_failed=false
    
    # Configure bash
    if [[ -f "$HOME/.bashrc" ]]; then
        if ! grep -q "starship init bash" "$HOME/.bashrc"; then
            log_info "Configuring Starship for Bash..."
            if ! echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"; then
                log_error "Failed to configure Starship for Bash"
                configure_failed=true
            fi
        else
            log_info "Starship already configured for Bash"
        fi
    fi
    
    # Configure zsh
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -q "starship init zsh" "$HOME/.zshrc"; then
            log_info "Configuring Starship for Zsh..."
            if ! echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"; then
                log_error "Failed to configure Starship for Zsh"
                configure_failed=true
            fi
        else
            log_info "Starship already configured for Zsh"
        fi
    fi
    
    # Configure fish
    if command -v fish >/dev/null 2>&1; then
        local fish_config_file="$HOME/.config/fish/config.fish"
        if [[ -f "$fish_config_file" ]]; then
            if ! grep -q "starship init fish" "$fish_config_file"; then
                log_info "Configuring Starship for Fish..."
                if ! echo 'starship init fish | source' >> "$fish_config_file"; then
                    log_warning "Failed to configure Starship for Fish"
                fi
            else
                log_info "Starship already configured for Fish"
            fi
        fi
    fi
    
    if [[ "$configure_failed" == "true" ]]; then
        log_error "Shell configuration failed for at least one shell"
        return 1
    fi
    
    log_success "Shell configuration completed"
    return 0
}

# Cleanup temporary files
cleanup_files() {
    log_info "Cleaning up temporary files..."
    
    # Remove extracted font files
    if [[ -d "$FONT_EXTRACT_DIR" ]]; then
        rm -rf "$FONT_EXTRACT_DIR"
        log_info "Removed extracted font files"
    fi
    
    # Remove downloaded archive if in non-interactive mode
    if [[ -f "$FONT_ARCHIVE" ]] && [[ "$NON_INTERACTIVE" == "true" ]]; then
        rm -f "$FONT_ARCHIVE"
        log_info "Removed downloaded font archive"
    fi
}

# ------------------------------------------------------------
# Main Installation Logic
# ------------------------------------------------------------

main() {
    log_info "Starting Shell Prompt (Starship + AdwaitaMono) installation..."
    
    # Install fontconfig if needed
    if ! command -v fc-cache >/dev/null 2>&1; then
        log_info "Installing fontconfig for font cache management..."
        if ! install_package fontconfig; then
            log_warning "Failed to install fontconfig. Continuing without font cache update."
        fi
    fi
    
    # Install font
    if ! font_installed "$FONT_NAME"; then
        if ! install_font; then
            log_error "Font installation failed"
            exit 1
        fi
    fi
    
    # Install Starship
    if ! install_starship; then
        log_error "Starship installation failed"
        exit 1
    fi
    
    # Add to PATH
    if ! add_to_path; then
        log_warning "PATH update failed, but Starship may still be functional"
    fi
    
    # Configure shells
    if ! configure_shell; then
        log_error "Shell configuration failed"
        exit 1
    fi
    
    # Cleanup
    cleanup_files
    
    log_success "========================================"
    log_success "✓ Shell Prompt installation completed!"
    log_success "========================================"
    log_info "To activate Starship in your current shell:"
    log_info "  source ~/.bashrc    # For bash"
    log_info "  source ~/.zshrc     # For zsh"
    log_info "  source ~/.config/fish/config.fish  # For fish (if installed)"
    log_info ""
    log_info "AdwaitaMono Nerd Font is installed for powerline symbols"
    log_info "Starship configuration file: ~/.config/starship.toml"
    log_info "Run 'starship preset > ~/.config/starship.toml' to create a default configuration"
    log_success "Enjoy your new beautiful shell prompt!"
    exit 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi