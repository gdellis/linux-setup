#!/usr/bin/env bash
# shellcheck disable=SC2155
# Restic Backup Tool Installer
# Description: Installs restic backup tool and sets up basic configuration
# Dependencies: lib/logging.sh, lib/dependencies.sh

set -euo pipefail

# Source shared libraries
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../lib/dependencies.sh"

# Constants
# shellcheck disable=SC2034  # INSTALLER_NAME is used by scripts that source this file
readonly INSTALLER_NAME="restic"
readonly RESTIC_VERSION="latest"
readonly RESTIC_CONFIG_DIR="$HOME/.config/restic"
readonly RESTIC_CACHE_DIR="$HOME/.cache/restic"

# Function to display help information
show_help() {
    cat << EOF
Usage: $(basename "$0") [options]

Options:
  -h, --help      Show this help message
  -y, --yes       Automatic yes to prompts (non-interactive mode)
  --version       Install specific version of restic (default: latest)

Description:
  Installs restic backup tool and sets up basic configuration.
  Restic is a modern backup program that supports encryption and deduplication.

EOF
}

# Function to install restic
install_restic() {
    local version="${1:-$RESTIC_VERSION}"

    log_info "Starting restic installation..."

    # Check if restic is already installed
    if command -v restic &> /dev/null; then
        local installed_version
        installed_version=$(restic version | awk '{print $2}')
        log_warning "Restic is already installed (version $installed_version)"
        if [[ "$version" == "latest" ]] || [[ "$installed_version" == "$version" ]]; then
            log_info "Skipping installation as requested version is already installed"
            return 0
        fi
    fi

    # Install dependencies
    ensure_dependencies_installed curl tar

    # Install restic based on distribution
    if [[ -f /etc/debian_version ]]; then
        log_info "Detected Debian-based system, installing via apt..."
        sudo apt-get update
        sudo apt-get install -y restic
    elif [[ -f /etc/redhat-release ]]; then
        log_info "Detected RHEL-based system, installing via dnf..."
        sudo dnf install -y restic
    else
        log_info "Installing restic from binary release..."
        local arch
        arch=$(uname -m)
        local os
        os=$(uname -s | tr '[:upper:]' '[:lower:]')

        # Map architecture names to restic's naming convention
        case "$arch" in
            x86_64) arch="amd64" ;;
            aarch64) arch="arm64" ;;
            *) arch="unknown" ;;
        esac

        if [[ "$arch" == "unknown" ]]; then
            log_error "Unsupported architecture: $arch"
            return 1
        fi

        # Download and install restic
        local temp_dir
        temp_dir=$(mktemp -d)
        local restic_url="https://github.com/restic/restic/releases/$version/download/restic_${version#v}_${os}_${arch}.bz2"

        log_info "Downloading restic from $restic_url..."
        curl -sSL "$restic_url" -o "$temp_dir/restic.bz2"
        bunzip2 "$temp_dir/restic.bz2"
        chmod +x "$temp_dir/restic"
        sudo mv "$temp_dir/restic" /usr/local/bin/restic
        rm -rf "$temp_dir"
    fi

    # Verify installation
    if ! command -v restic &> /dev/null; then
        log_error "Restic installation failed"
        return 1
    fi

    local installed_version
    installed_version=$(restic version | awk '{print $2}')
    log_success "Restic installed successfully (version $installed_version)"
}

# Function to set up basic restic configuration
setup_restic_config() {
    log_info "Setting up restic configuration..."

    # Create configuration directories
    mkdir -p "$RESTIC_CONFIG_DIR"
    mkdir -p "$RESTIC_CACHE_DIR"

    # Create basic configuration file
    local config_file="$RESTIC_CONFIG_DIR/config"

    if [[ -f "$config_file" ]]; then
        log_info "Restic configuration already exists, creating backup..."
        cp "$config_file" "$config_file.bak_$(date +%Y%m%d_%H%M%S)"
    fi

    # Create a basic configuration with placeholders
    cat > "$config_file" << EOF
# Restic Configuration File
# Edit this file to configure your backup repositories

# Example repository configuration (uncomment and modify):
# [repository.mybackup]
# repository = "s3:s3.amazonaws.com/bucket_name"
# password-file = "$RESTIC_CONFIG_DIR/password.txt"
# cache-dir = "$RESTIC_CACHE_DIR"

# Environment variables can also be used:
# export RESTIC_REPOSITORY="s3:s3.amazonaws.com/bucket_name"
# export RESTIC_PASSWORD_FILE="$RESTIC_CONFIG_DIR/password.txt"

EOF

    log_info "Created basic restic configuration at $config_file"
    log_info "You will need to edit this file to configure your backup repositories"
    log_info "See https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html for details"
}

# Function to create a sample backup script
create_sample_backup_script() {
    local backup_script="$HOME/bin/restic_backup.sh"

    log_info "Creating sample backup script..."

    # Create bin directory if it doesn't exist
    mkdir -p "$HOME/bin"

    # Create sample backup script
    cat > "$backup_script" << 'EOF'
#!/usr/bin/env bash
# Sample Restic Backup Script
# Customize this script for your backup needs

set -euo pipefail

# Source restic configuration
CONFIG_DIR="$HOME/.config/restic"
source "$CONFIG_DIR/config" 2>/dev/null || true

# Set repository and password (can also be set in the config file)
# export RESTIC_REPOSITORY="s3:s3.amazonaws.com/bucket_name"
# export RESTIC_PASSWORD="your-strong-password"

# Check if repository is configured
if [[ -z "${RESTIC_REPOSITORY:-}" ]]; then
    echo "Error: RESTIC_REPOSITORY is not set"
    echo "Please configure your repository in $CONFIG_DIR/config"
    exit 1
fi

# Backup directories (customize these)
BACKUP_DIRS=(
    "$HOME/Documents"
    "$HOME/Pictures"
    "$HOME/Development"
)

# Exclude patterns (customize these)
EXCLUDE_PATTERNS=(
    "*.tmp"
    "*.log"
    "*.cache"
    "node_modules"
    ".git"
)

# Convert exclude patterns to restic format
EXCLUDE_ARGS=()
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    EXCLUDE_ARGS+=("--exclude" "$pattern")
done

# Run backup
echo "Starting backup..."
restic backup "${BACKUP_DIRS[@]}" "${EXCLUDE_ARGS[@]}" --verbose

# Optional: Run forget to apply retention policy
# restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune

echo "Backup completed successfully"
EOF

    chmod +x "$backup_script"
    log_success "Created sample backup script at $backup_script"
    log_info "Edit this script to customize your backup directories and retention policy"
}

# Function to display post-installation instructions
show_post_install_instructions() {
    cat << EOF

Restic has been successfully installed!

Next steps:
1. Configure your backup repository:
   - Edit $RESTIC_CONFIG_DIR/config
   - See https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html

2. Initialize your repository:
   \`restic init --repository-version 2\`

3. Test your backup:
   - Run the sample script: $HOME/bin/restic_backup.sh
   - Or manually: \`restic backup /path/to/directory\`

4. Set up automated backups:
   - Add a cron job for regular backups
   - Example: \`0 2 * * * $HOME/bin/restic_backup.sh\`

5. Learn more:
   - Documentation: https://restic.readthedocs.io/
   - Quick start guide: https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html

EOF
}

# Main function
main() {
    local version="$RESTIC_VERSION"
    local non_interactive=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -y|--yes)
                non_interactive=true
                shift
                ;;
            --version)
                version="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Check if running in non-interactive mode
    if [[ "$non_interactive" == false ]]; then
        if ! confirm_action "Install restic backup tool?"; then
            log_info "Installation cancelled by user"
            exit 0
        fi
    fi

    # Install restic
    install_restic "$version"

    # Set up configuration
    setup_restic_config

    # Create sample backup script
    create_sample_backup_script

    # Show post-installation instructions
    show_post_install_instructions

    log_success "Restic installation completed successfully!"
}

main "$@"