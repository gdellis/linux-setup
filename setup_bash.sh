#!/usr/bin/env bash
# ----------------------------------------------------------------------------
# Setup Script for Bash Configuration Files
# ----------------------------------------------------------------------------
# This script sets up bash configuration files on a new machine by:
# 1. Backing up existing configuration files
# 2. Copying new configuration files to ~/.config/bash
# 3. Creating symbolic links from ~/.config/bash to $HOME
# ----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# ----------------------------------------------------------------------------
# Configuration Variables
# ----------------------------------------------------------------------------
readonly SCRIPT_NAME="setup_bash.sh"
readonly TIMESTAMP=$(date '+%Y-%m-%d_%H%M%S')
readonly BACKUP_DIR="$HOME/backups/bash_$TIMESTAMP"

# Destination for configuration files
readonly BASH_CFG_DEST="${BASH_CFG_DEST:-$HOME/.config}"
readonly BASH_CFG_DIR="$BASH_CFG_DEST/bash"

# Files to be managed
readonly BASH_FILES=(
    ".bashrc"
    ".bash_aliases"
    ".bash_profile"
    ".bash_logout"
    ".inputrc"
)

# ----------------------------------------------------------------------------
# Utility Functions
# ----------------------------------------------------------------------------

# Print colored output
print_info() {
    echo -e "\033[1;36m[INFO]\033[0m $*"
}

print_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $*"
}

print_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $*"
}

print_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $*" >&2
}

# Error handling
handle_error() {
    local line_number="$1"
    local error_code="$2"
    print_error "Error occurred at line $line_number with exit code $error_code"
    exit "$error_code"
}

trap 'handle_error $LINENO $?' ERR

# ----------------------------------------------------------------------------
# Project Root Detection
# ----------------------------------------------------------------------------
detect_project_root() {
    local script_dir project_root
    script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
    
    # 1️⃣ Prefer Git if we are inside a repo
    if project_root=$(git rev-parse --show-toplevel 2>/dev/null); then
        print_info "Found Git repository root: $project_root"
        TOP="$project_root"
        return 0
    fi
    
    # 2️⃣ If not a Git repo, look for a known marker (e.g., .topdir)
    local dir="$script_dir"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/.topdir" ]]; then
            TOP="$dir"
            print_info "Found project root via .topdir marker: $TOP"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    
    # 3️⃣ Give up with a clear error if we still have no root
    print_error "Unable to locate project root. Ensure you are inside a Git repo or that a .topdir file exists."
    exit 1
}

# ----------------------------------------------------------------------------
# Logging Setup
# ----------------------------------------------------------------------------
setup_logging() {
    local lib_dir="$TOP/lib"
    
    # Source Logger if available
    if [[ -f "$lib_dir/logging.sh" ]]; then
        source "$lib_dir/logging.sh"
        print_info "Using shared logging library"
    else
        print_warn "Shared logging library not found, using built-in logging"
    fi
}

# ----------------------------------------------------------------------------
# Dependency Management
# ----------------------------------------------------------------------------
install_starship() {
    if command -v starship &>/dev/null; then
        print_info "Starship is already installed"
        return 0
    fi
    
    print_info "Installing Starship prompt..."
    
    # Install Starship
    if curl -sS https://starship.rs/install.sh | sh -s -- -y; then
        print_success "Starship installed successfully"
    else
        print_error "Failed to install Starship"
        return 1
    fi
    
    # Note about Nerd Fonts (manual step for user)
    print_info "Please install a Nerd Font for full Starship functionality:"
    print_info "https://www.nerdfonts.com/font-downloads"
}

# ----------------------------------------------------------------------------
# Backup Functions
# ----------------------------------------------------------------------------
create_backup_directory() {
    if [[ ! -d "$(dirname "$BACKUP_DIR")" ]]; then
        print_info "Creating backup parent directory"
        mkdir -p "$(dirname "$BACKUP_DIR")"
    fi
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        print_info "Creating backup directory: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
    fi
}

backup_file() {
    local file_path=$1
    local file_name
    
    file_name=$(basename "$file_path")
    
    if [[ -f "$file_path" ]]; then
        print_info "Backing up $file_name"
        cp "$file_path" "$BACKUP_DIR/"
        print_success "Backed up $file_name to $BACKUP_DIR/"
    else
        print_info "No existing $file_name to backup"
    fi
}

backup_existing_configurations() {
    print_info "Starting backup process..."
    create_backup_directory
    
    for file in "${BASH_FILES[@]}"; do
        backup_file "$HOME/$file"
    done
    
    print_success "Backup process completed"
}

# ----------------------------------------------------------------------------
# Configuration Deployment
# ----------------------------------------------------------------------------
create_config_directories() {
    print_info "Creating configuration directories..."
    
    # Create main config directory
    if [[ ! -d "$BASH_CFG_DEST" ]]; then
        print_info "Creating $BASH_CFG_DEST"
        mkdir -p "$BASH_CFG_DEST"
    fi
    
    # Create bash config directory
    if [[ ! -d "$BASH_CFG_DIR" ]]; then
        print_info "Creating $BASH_CFG_DIR"
        mkdir -p "$BASH_CFG_DIR"
    fi
}

copy_configuration_files() {
    print_info "Copying configuration files..."
    
    # Change to script directory
    local script_dir
    script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
    
    # Copy bash directory
    if [[ -d "$script_dir/bash" ]]; then
        print_info "Copying bash configuration files..."
        cp -r "$script_dir/bash"/* "$BASH_CFG_DIR/" || {
            print_error "Failed to copy bash files"
            return 1
        }
        print_success "Configuration files copied successfully"
    else
        print_error "Source bash directory not found: $script_dir/bash"
        return 1
    fi
}

create_symbolic_links() {
    print_info "Creating symbolic links..."
    
    for file in "${BASH_FILES[@]}"; do
        local target="$BASH_CFG_DIR/$file"
        local link_name="$HOME/$file"
        
        # Skip if source file doesn't exist
        if [[ ! -f "$target" ]]; then
            print_warn "Source file not found, skipping: $target"
            continue
        fi
        
        # Backup existing file if it exists and is not a symlink
        if [[ -f "$link_name" && ! -L "$link_name" ]]; then
            print_info "Backing up existing $file"
            backup_file "$link_name"
        fi
        
        # Remove existing symlink or file
        if [[ -e "$link_name" ]]; then
            rm -f "$link_name"
        fi
        
        # Create symbolic link
        ln -sf "$target" "$link_name"
        print_success "Created symlink: $link_name -> $target"
    done
}

# ----------------------------------------------------------------------------
# Cleanup and Finalization
# ----------------------------------------------------------------------------
cleanup() {
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        print_success "$SCRIPT_NAME completed successfully"
    else
        print_error "$SCRIPT_NAME failed with exit code $exit_code"
    fi
    
    return $exit_code
}

trap cleanup EXIT

# ----------------------------------------------------------------------------
# Main Execution
# ----------------------------------------------------------------------------
main() {
    print_info "Starting bash configuration setup..."
    
    # Setup error handling
    set -euo pipefail
    
    # Detect project root
    detect_project_root
    
    # Setup logging
    setup_logging
    
    # Parse command line arguments
    local install_deps=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--install-deps)
                install_deps=true
                shift
                ;;
            -h|--help)
                echo "Usage: $SCRIPT_NAME [OPTIONS]"
                echo "Options:"
                echo "  -d, --install-deps    Install dependencies (Starship)"
                echo "  -h, --help           Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Install dependencies if requested
    if [[ "$install_deps" == true ]]; then
        install_starship
    fi
    
    # Backup existing configurations
    backup_existing_configurations
    
    # Create directories
    create_config_directories
    
    # Copy configuration files
    copy_configuration_files
    
    # Create symbolic links
    create_symbolic_links
    
    print_success "Bash configuration setup completed!"
    print_info "Backup location: $BACKUP_DIR"
    
    if [[ "$install_deps" == true ]]; then
        print_info "To enable Starship prompt, restart your terminal or run:"
        echo "  source ~/.bashrc"
    fi
}

# Execute main function
main "$@"