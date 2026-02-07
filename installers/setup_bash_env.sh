#!/usr/bin/env bash
#
# setup_bash_env.sh - Bash Environment Setup Installer
# Description: Clones bash_files repository and sets up bash environment
# Category: Environment
# Usage: ./setup_bash_env.sh [OPTIONS]
#        -y, --yes, --non-interactive    Skip confirmation prompts
#        -h, --help                      Show this help message
#        Can also be run remotely with: bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/installers/setup_bash_env.sh)
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
readonly LOG_DIR="${HOME}/logs/$APP_NAME"
readonly LOG_FILE="${LOG_DIR}/$(date +%Y%m%d_%H%M%S)_${APP_NAME}.log"

# Ensure directories exist
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

readonly BASH_FILES_REPO="https://github.com/gdellis/bash_files.git"
readonly BASH_CONFIG_DIR="$HOME/.config/bash"
readonly BASH_CONFIG_FILE="$BASH_CONFIG_DIR/.bashrc"
readonly USER_BASHRC="$HOME/.bashrc"
readonly BASH_CONFIG_BACKUP="$HOME/.bashrc.bak"

# ------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------

check_existing_bashrc() {
    if [[ -f "$USER_BASHRC" ]] && [[ ! -L "$USER_BASHRC" ]]; then
        log_info "Found existing .bashrc file"
        
        if [[ -f "$BASH_CONFIG_BACKUP" ]]; then
            log_warning "Backup file already exists: $BASH_CONFIG_BACKUP"
            if [[ "$NON_INTERACTIVE" == "false" ]]; then
                read -rp "Overwrite existing backup? (y/N): " confirm
                if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
                    log_info "Skipping backup creation"
                    return 0
                fi
            fi
        fi
        
        log_info "Creating backup of existing .bashrc..."
        if cp "$USER_BASHRC" "$BASH_CONFIG_BACKUP"; then
            log_success "Backup created: $BASH_CONFIG_BACKUP"
        else
            log_error "Failed to create backup"
            return 1
        fi
    elif [[ -L "$USER_BASHRC" ]]; then
        log_info "Found existing symlink for .bashrc"
        local link_target
        link_target=$(readlink "$USER_BASHRC")
        log_info "Current symlink points to: $link_target"
    else
        log_info "No existing .bashrc file found"
    fi
    
    return 0
}

# Check for local changes in git repository
has_local_changes() {
    local repo_dir="$1"
    
    if [[ ! -d "$repo_dir" ]]; then
        return 1
    fi
    
    cd "$repo_dir"
    
    # Check for modified, untracked, or staged files
    if [[ -n "$(git status --porcelain)" ]]; then
        return 0  # Local changes found
    fi
    
    return 1  # No local changes
}

# Safely update git repository respecting local changes
update_repository() {
    local repo_dir="$1"
    local branch="${2:-main}"
    
    cd "$repo_dir"
    
    # Fetch latest changes
    if ! git fetch origin "$branch"; then
        log_error "Failed to fetch latest changes from remote"
        return 1
    fi
    
    # Check for local changes
    if has_local_changes "$repo_dir"; then
        log_warning "Local changes detected in repository"
        
        # Show what files have changed
        log_info "Local changes:"
        git status --short | while IFS= read -r line; do
            log_info "  $line"
        done
        
        if [[ "$NON_INTERACTIVE" == "false" ]]; then
            read -rp "Stash local changes and update? (y/N): " confirm
            if [[ "$confirm" == "y" ]] || [[ "$confirm" == "Y" ]]; then
                log_info "Stashing local changes..."
                git stash push -m "Auto-stash before update at $(date)"
                log_success "Local changes stashed"
            else
                log_info "Skipping repository update to preserve local changes"
                return 1
            fi
        else
            # In non-interactive mode, we stash changes automatically
            log_info "Non-interactive mode: Stashing local changes..."
            git stash push -m "Auto-stash before update at $(date)"
            log_success "Local changes stashed"
        fi
    fi
    
    # Update the repository
    if ! git merge --ff-only "origin/$branch"; then
        log_error "Failed to update repository. There may be conflicts."
        return 1
    fi
    
    log_success "Repository updated successfully"
    return 0
}

clone_bash_files() {
    log_info "Cloning bash_files repository..."
    
    ensure_dependencies --auto-install git
    
    if [[ -d "$BASH_CONFIG_DIR" ]]; then
        log_info "Found existing bash config directory: $BASH_CONFIG_DIR"
        
        if [[ -d "$BASH_CONFIG_DIR/.git" ]]; then
            log_info "Existing directory is a git repository"
            
            if [[ "$NON_INTERACTIVE" == "false" ]]; then
                read -rp "Update existing repository? (y/N): " confirm
                if [[ "$confirm" == "y" ]] || [[ "$confirm" == "Y" ]]; then
                    log_info "Updating existing repository..."
                    cd "$BASH_CONFIG_DIR"
                    if ! git pull origin main; then
                        log_error "Failed to update repository"
                        return 1
                    fi
                    log_success "Repository updated successfully"
                    return 0
                else
                    log_info "Skipping repository update"
                    return 0
                fi
            else
                log_info "Updating existing repository (non-interactive mode)..."
                cd "$BASH_CONFIG_DIR"
                if ! git pull origin main; then
                    log_error "Failed to update repository"
                    return 1
                fi
                log_success "Repository updated successfully"
                return 0
            fi
        else
            log_warning "Directory exists but is not a git repository"
            if [[ "$NON_INTERACTIVE" == "false" ]]; then
                read -rp "Remove existing directory and clone fresh? (y/N): " confirm
                if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
                    log_error "Cannot proceed without removing existing directory"
                    return 1
                fi
            fi
            
            log_info "Removing existing directory..."
            rm -rf "$BASH_CONFIG_DIR"
        fi
    fi
    
    log_info "Cloning repository to $BASH_CONFIG_DIR..."
    if ! git clone "$BASH_FILES_REPO" "$BASH_CONFIG_DIR"; then
        log_error "Failed to clone repository"
        return 1
    fi
    
    log_success "Repository cloned successfully"
    return 0
}

create_bashrc_symlink() {
    log_info "Setting up .bashrc symlink..."
    
    if [[ ! -f "$BASH_CONFIG_FILE" ]]; then
        log_error "Bash config file not found: $BASH_CONFIG_FILE"
        return 1
    fi
    
    # Remove existing .bashrc if it's not a symlink to our config
    if [[ -f "$USER_BASHRC" ]] && [[ ! -L "$USER_BASHRC" ]]; then
        log_info "Removing existing .bashrc file..."
        rm -f "$USER_BASHRC"
    elif [[ -L "$USER_BASHRC" ]]; then
        local link_target
        link_target=$(readlink "$USER_BASHRC")
        if [[ "$link_target" != "$BASH_CONFIG_FILE" ]]; then
            log_info "Removing existing symlink pointing to different target..."
            rm -f "$USER_BASHRC"
        else
            log_info "Symlink already correctly configured"
            return 0
        fi
    fi
    
    log_info "Creating symlink: $USER_BASHRC -> $BASH_CONFIG_FILE"
    if ln -sf "$BASH_CONFIG_FILE" "$USER_BASHRC"; then
        log_success "Symlink created successfully"
    else
        log_error "Failed to create symlink"
        return 1
    fi
    
    return 0
}

install_dependencies() {
    log_info "Installing bash completion..."
    
    if [[ -f "/usr/share/bash-completion/bash_completion" ]]; then
        log_info "Bash completion already installed"
        return 0
    fi
    
    if ! install_package bash-completion; then
        log_warning "Failed to install bash-completion, but continuing..."
    fi
    
    return 0
}

setup_starship_config() {
    log_info "Setting up starship.toml configuration..."
    
    local starship_config_dir="$HOME/.config"
    local starship_config_file="$starship_config_dir/starship.toml"
    local starship_backup_file="$starship_config_file.bak"
    
    ensure_dependencies --auto-install curl
    
    # Create .config directory if it doesn't exist
    if [[ ! -d "$starship_config_dir" ]]; then
        mkdir -p "$starship_config_dir"
    fi
    
    # Backup existing starship.toml if it exists and is not a symlink
    if [[ -f "$starship_config_file" && ! -L "$starship_config_file" ]]; then
        log_info "Found existing starship.toml file, backing up..."
        if mv "$starship_config_file" "$starship_backup_file"; then
            log_success "Backup created: $starship_backup_file"
        else
            log_warning "Failed to create backup, but continuing..."
        fi
    elif [[ -L "$starship_config_file" ]]; then
        local link_target
        link_target=$(readlink "$starship_config_file")
        log_info "Found existing symlink pointing to: $link_target"
        
        # Check if it's already pointing to our config
        if echo "$link_target" | grep -q "bash_files"; then
            log_info "Symlink already correctly configured"
            return 0
        else
            # Remove the symlink as it points elsewhere
            rm -f "$starship_config_file"
        fi
    fi
    
    # Download starship.toml to bash config directory
    local local_starship_toml="$BASH_CONFIG_DIR/starship.toml"
    log_info "Downloading starship.toml configuration..."
    
    if ! curl -sSL "$STARSHIP_TOML_URL" -o "$local_starship_toml"; then
        log_error "Failed to download starship.toml"
        return 1
    fi
    
    # Create symlink from .config to our local copy
    if ln -sf "$local_starship_toml" "$starship_config_file"; then
        log_success "starship.toml symlink created successfully"
        return 0
    else
        log_error "Failed to create symlink for starship.toml"
        return 1
    fi
}

# ------------------------------------------------------------
# Main Installation Logic
# ------------------------------------------------------------

main() {
    log_info "Starting Bash Environment Setup..."
    
    # Install bash-completion if not present
    if ! install_dependencies; then
        log_warning "Failed to install some dependencies, but continuing..."
    fi
    
    # Backup existing .bashrc
    if ! check_existing_bashrc; then
        log_error "Failed to check existing bash configuration"
        exit 1
    fi
    
    # Clone repository
    if ! clone_bash_files; then
        log_error "Failed to clone bash_files repository"
        exit 1
    fi
    
    # Create symlink
    if ! create_bashrc_symlink; then
        log_error "Failed to create .bashrc symlink"
        exit 1
    fi
    
    # Setup starship configuration
    if ! setup_starship_config; then
        log_error "Failed to setup starship configuration"
        exit 1
    fi
    
    log_success "========================================"
    log_success "✓ Bash Environment Setup completed!"
    log_success "========================================"
    log_info "Configuration files installed to: $BASH_CONFIG_DIR"
    log_info "Main config file: $BASH_CONFIG_FILE"
    log_info "Symlink created: $USER_BASHRC -> $BASH_CONFIG_FILE"
    if [[ -f "$BASH_CONFIG_BACKUP" ]]; then
        log_info "Backup of original .bashrc: $BASH_CONFIG_BACKUP"
    fi
    log_info ""
    log_info "To activate the new configuration, either:"
    log_info "  - Restart your terminal"
    log_info "  - Run: source $USER_BASHRC"
    log_info "  - Run: exec bash"
    exit 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi