#!/usr/bin/env bash
#
# setup_vibe.sh - Mistral Vibe Installation Script
# Description: Installs Mistral Vibe, a command-line AI assistant powered by Mistral's Devstral 2 model
# Category: AI/ML
# Usage: ./setup_vibe.sh [OPTIONS]
#        -y, --yes, --non-interactive    Skip confirmation prompts
#        -h, --help                      Show help message
#        Can also be run remotely with: bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/installers/setup_vibe.sh)
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
# Configuration
# ------------------------------------------------------------

readonly VIBE_INSTALL_URL="https://mistral.ai/vibe/install.sh"
readonly INSTALL_SCRIPT_PATH="$DL_DIR/install.sh"

# ------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------

# Download file with error checking and progress
download_file() {
    local url="$1"
    local dest="$2"

    log_info "📥 Downloading installer script from: $url"
    echo

    if ! curl -L --progress-bar --output "$dest" "$url"; then
        log_error "❌ Failed to download installer script"
        return 1
    fi

    echo
    log_success "✓ Download completed: $dest"
    return 0
}

check_python() {
    log_info "🔍 Checking for Python installation..."
    
    if ! command -v python3 &> /dev/null; then
        log_error "❌ Python 3 is not installed"
        log_info "Please install Python 3 and try again"
        return 1
    fi
    
    local python_version
    python_version=$(python3 --version 2>&1)
    log_success "✓ Found Python: $python_version"
    return 0
}

check_pip() {
    log_info "🔍 Checking for pip installation..."
    
    if ! command -v pip3 &> /dev/null && ! command -v pip &> /dev/null; then
        log_warning "⚠️ Pip is not installed or not in PATH"
        log_info "Attempting to install pip..."
        
        # Try to install pip
        if command -v apt-get &> /dev/null; then
            if ! sudo apt-get update; then
                log_error "❌ Failed to update package lists"
                return 1
            fi
            
            if ! sudo apt-get install -y python3-pip; then
                log_error "❌ Failed to install python3-pip"
                return 1
            fi
            log_success "✓ Installed python3-pip"
        else
            log_error "❌ Cannot install pip automatically (apt-get not available)"
            log_info "Please install pip manually and try again"
            return 1
        fi
    fi
    
    # Verify pip is working
    if command -v pip3 &> /dev/null; then
        local pip_version
        pip_version=$(pip3 --version 2>&1)
        log_success "✓ Found pip: $pip_version"
    elif command -v pip &> /dev/null; then
        local pip_version
        pip_version=$(pip --version 2>&1)
        log_success "✓ Found pip: $pip_version"
    fi
    
    return 0
}

# ------------------------------------------------------------
# Installation Functions
# ------------------------------------------------------------

check_existing_installation() {
    if command -v vibe &> /dev/null; then
        local installed_version
        installed_version=$(vibe --version 2>/dev/null | head -n1 || echo "unknown")

        echo
        log_warning "⚠️  Mistral Vibe is already installed (version: $installed_version)"
        echo

        if [[ "$NON_INTERACTIVE" == "true" ]]; then
            log_info "Non-interactive mode: Proceeding with reinstallation"
        else
            read -rp "Do you want to reinstall? [y/N]: " reinstall
            if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
                log_info "Installation cancelled"
                exit 0
            fi
        fi
        return 1
    fi
    return 0
}

install_vibe() {
    log_info "🚀 Installing Mistral Vibe..."
    echo

    # Download the installer script
    if ! download_file "$VIBE_INSTALL_URL" "$INSTALL_SCRIPT_PATH"; then
        log_error "❌ Failed to download installer script"
        return 1
    fi

    # Make the script executable
    if ! chmod +x "$INSTALL_SCRIPT_PATH"; then
        log_error "❌ Failed to make installer script executable"
        return 1
    fi

    # Run the installer script
    log_info "🔧 Running Mistral Vibe installer..."
    
    if ! bash "$INSTALL_SCRIPT_PATH"; then
        log_error "❌ Mistral Vibe installation failed"
        return 1
    fi

    log_success "✓ Mistral Vibe installer completed"

    # Verify installation
    if ! command -v vibe &> /dev/null; then
        log_error "❌ Mistral Vibe installation verification failed"
        return 1
    fi

    local installed_version
    installed_version=$(vibe --version 2>/dev/null | head -n1 || echo "unknown")
    log_success "✓ Mistral Vibe installed successfully: $installed_version"

    return 0
}

# ------------------------------------------------------------
# Main Installation Logic
# ------------------------------------------------------------

main() {
    echo
    log_info "🎯 Starting Mistral Vibe installation..."
    echo

    # Check prerequisites
    if ! check_python; then
        log_error "❌ Python check failed"
        exit 1
    fi
    
    if ! check_pip; then
        log_error "❌ Pip check failed"
        exit 1
    fi

    # Check if already installed
    if ! check_existing_installation; then
        log_info "Proceeding with reinstallation"
    fi

    # Install Mistral Vibe
    if ! install_vibe; then
        log_error "❌ Mistral Vibe installation failed"
        exit 1
    fi

    echo
    log_success "===================================="
    log_success "✓ Mistral Vibe installation completed!"
    log_success "===================================="
    echo

    # Installation summary
    cat << EOF
📍 Installation Details:
   • Mistral Vibe CLI tool
   • Installed via official installer script
   • Requires Python 3 and pip

🚀 Quick Start:
   vibe --help           # Show help
   vibe                  # Start interactive mode
   vibe "hello world"    # Send a prompt directly

🔐 Configuration:
   On first launch, Vibe will prompt for your API key.
   Get your API key at: https://console.mistral.ai/codestral/vibe

💡 Tips:
   • Run vibe from your project root for context-aware assistance
   • Use --auto-approve for autonomous execution (with caution!)
   • Review all proposed changes before confirming execution

📚 Documentation:
   https://help.mistral.ai/en/articles/496007-get-started-with-mistral-vibe

EOF

    exit 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi