#!/usr/bin/env bash
#
# setup_starship.sh - Starship Installation Script
# Description: Downloads and installs Starship, the cross-shell prompt written in Rust
# Category: Desktop
# Usage: ./setup_starship.sh [OPTIONS]
#        -y, --yes, --non-interactive    Skip confirmation prompts
#        -h, --help                      Show this help message
#        Can also be run remotely with: bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/installers/setup_starship.sh)
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

readonly STARSHIP_VERSION="v1.24.2"
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

install_starship() {
    log_info "Installing Starship..."
    
    # Set installation directory
    export BINDIR="$STARSHIP_BIN_DIR"
    
    # Run the install script via pipe
    if ! curl -sSL "$STARSHIP_INSTALL_URL" | sh -s -- --yes; then
        log_error "Starship installation failed"
        return 1
    fi
    
    log_success "Starship installed successfully"
}

add_to_path() {
    log_info "Adding Starship to PATH..."
    
    if [[ ! -d "$STARSHIP_BIN_DIR" ]]; then
        log_info "Creating binary directory: $STARSHIP_BIN_DIR"
        mkdir -p "$STARSHIP_BIN_DIR"
    fi
    
    # Check if STarship binary exists
    local starship_path="$STARSHIP_BIN_DIR/starship"
    if [[ ! -f "$starship_path" ]]; then
        log_warning "Starship binary not found at expected location: $starship_path"
        # Try to find it with 'which'
        local installed_path
        if installed_path=$(which starship 2>/dev/null); then
            log_info "Starship found at: $installed_path"
            starship_path="$installed_path"
        else
            log_error "Starship binary not found after installation"
            return 1
        fi
    fi
    
    # Add to PATH in bashrc if not already there
    local bashrc_file="$HOME/.bashrc"
    local path_added=false
    
    if [[ -f "$bashrc_file" ]]; then
        if ! grep -q "$STARSHIP_BIN_DIR" "$bashrc_file"; then
            log_info "Adding $STARSHIP_BIN_DIR to PATH in $bashrc_file..."
            if ! echo "export PATH=\"$STARSHIP_BIN_DIR:\$PATH\"" >> "$bashrc_file"; then
                log_error "Failed to update $bashrc_file"
                return 1
            fi
            path_added=true
        else
            log_info "$STARSHIP_BIN_DIR already in PATH"
        fi
    fi
    
    # Add to PATH in zshrc if it exists
    local zshrc_file="$HOME/.zshrc"
    if [[ -f "$zshrc_file" ]]; then
        if ! grep -q "$STARSHIP_BIN_DIR" "$zshrc_file"; then
            log_info "Adding $STARSHIP_BIN_DIR to PATH in $zshrc_file..."
            if ! echo "export PATH=\"$STARSHIP_BIN_DIR:\$PATH\"" >> "$zshrc_file"; then
                log_error "Failed to update $zshrc_file"
                return 1
            fi
            path_added=true
        else
            log_info "$STARSHIP_BIN_DIR already in PATH"
        fi
    fi
    
    if [[ "$path_added" == "true" ]]; then
        log_success "Added $STARSHIP_BIN_DIR to PATH"
        log_info "Restart your shell or run 'source ~/.bashrc' to make the changes effective"
    else
        log_info "Starship already in PATH"
    fi
    
    return 0
}

configure_shell() {
    log_info "Configuring shells to use Starship..."
    
    # Configure bash
    local bashrc_file="$HOME/.bashrc"
    if [[ -f "$bashrc_file" ]]; then
        if ! grep -q "starship init bash" "$bashrc_file"; then
            log_info "Configuring Starship for Bash..."
            if ! echo 'eval "$(starship init bash)"' >> "$bashrc_file"; then
                log_error "Failed to configure Starship for Bash"
                return 1
            fi
        else
            log_info "Starship already configured for Bash"
        fi
    fi
    
    # Configure zsh
    local zshrc_file="$HOME/.zshrc"
    if [[ -f "$zshrc_file" ]]; then
        if ! grep -q "starship init zsh" "$zshrc_file"; then
            log_info "Configuring Starship for Zsh..."
            if ! echo 'eval "$(starship init zsh)"' >> "$zshrc_file"; then
                log_error "Failed to configure Starship for Zsh"
                return 1
            fi
        else
            log_info "Starship already configured for Zsh"
        fi
    fi
    
    # Configure fish
    local fish_config_file="$HOME/.config/fish/config.fish"
    if [[ -f "$(command -v fish 2>/dev/null)" ]]; then
        if [[ -f "$fish_config_file" ]]; then
            if ! grep -q "starship init fish" "$fish_config_file"; then
                log_info "Configuring Starship for Fish..."
                if ! echo 'starship init fish | source' >> "$fish_config_file"; then
                    log_warning "Failed to configure Starship for Fish"
                fi
            fi
        fi
    fi
    
    log_success "Shell configuration completed"
    return 0
}

cleanup_files() {
    log_info "Cleaning up..."
    # Nothing to clean up since we used pipe installation
}

# ------------------------------------------------------------
# Main Installation Logic
# ------------------------------------------------------------

main() {
    log_info "Starting Starship installation..."
    
    # Download install script
    
    # Install Starship
    if ! install_starship; then
        log_error "Installation failed"
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
    log_success "✓ Starship installation completed!"
    log_success "========================================"
    log_info "To activate Starship in your current shell:"
    log_info "  source ~/.bashrc  # For bash"
    log_info "  source ~/.zshrc   # For zsh"
    log_info ""
    log_info "Starship configuration file: ~/.config/starship.toml"
    log_info "Run 'starship preset > ~/.config/starship.toml' to create a default configuration"
    exit 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi