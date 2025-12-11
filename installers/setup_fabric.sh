#!/usr/bin/env bash

set -euo pipefail
# ------------------------------------------------------------
# Setup Logging
# ------------------------------------------------------------
# region
readonly APP_NAME=fabric
readonly DL_DIR="${HOME}/downloads/$APP_NAME"
readonly LOG_DIR="${HOME}/logs/$APP_NAME"
readonly LOG_FILE="${LOG_DIR}/$(date +%Y%m%d_%H%M%S)_${APP_NAME}.log"

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Ensure directories exist
mkdir -p "$DL_DIR"
mkdir -p "$LOG_DIR"

# Logging functions with color and file output
log() 
{
    local colored_msg plain_msg
    colored_msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    
    # Strip ANSI color codes for log file
    plain_msg=$(echo -e "$colored_msg" | sed -E 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mK]//g')
    
    # Output to terminal (with colors)
    echo -e "$colored_msg"
    
    # Output to log file (without colors)
    echo "$plain_msg" >> "$LOG_FILE"
}

log_info() { log "${GREEN}[INFO]${NC} $*";}
log_error() { log "${RED}[ERROR]${NC} $*";}
log_success() { log "${GREEN}[SUCCESS]${NC} $*";}
log_warning() { log "${YELLOW}[WARNING]${NC} $*";}

log_info "=== $APP_NAME Installer Started ==="
log_info "Log file: $LOG_FILE"
# endregion

# ------------------------------------------------------------
# Fabric AI Setup Script
# ------------------------------------------------------------

# Enable strict mode for better error handling
set -o errexit   # Exit on most errors
set -o nounset   # Disallow expansion of unset variables

# ------------------------------------------------------------
# region Script Setup
# ------------------------------------------------------------

# ------------------------------------------------------------
# Main Functions
# ------------------------------------------------------------

check_dependencies() {
    log_info "Checking dependencies"
    local dependencies=(
        op
        ffmpeg
        yt-dlp
        curl
    )

    local status=0

    for cmd in "${dependencies[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            log_info "✅ Dependency '$cmd' exists"
        else
            status=1
            log_warning "⛔ Dependency '$cmd' not found"
        fi
    done
    return $status
}

install_fabric() {
    log_info "Installing Fabric"

    # Create a temporary file for the installer
    local temp_installer
    temp_installer=$(mktemp) || {
        log_error "Failed to create temporary file for installer"
        return 1
    }

    # Download the installer with error handling
    if ! curl -fsSL https://raw.githubusercontent.com/danielmiessler/fabric/main/scripts/installer/install.sh -o "$temp_installer"; then
        log_error "Failed to download Fabric installer"
        rm -f "$temp_installer"
        return 1
    fi

    # Verify the installer (basic check)
    if ! grep -q "fabric" "$temp_installer"; then
        log_error "Downloaded file doesn't appear to be the Fabric installer"
        rm -f "$temp_installer"
        return 1
    fi

    # Run the installer with error handling
    if ! bash "$temp_installer"; then
        log_error "Fabric installation failed"
        rm -f "$temp_installer"
        return 1
    fi

    # Clean up
    rm -f "$temp_installer"
    log_info "Fabric installation completed successfully"
}

create_config() {
    log_info "Setting up Fabric Config"

    # Get API key with error handling
    local yt_key
    if ! yt_key="$(op read "op://Private/Google API Keys/yt fabric" 2>/dev/null)"; then
        log_error "Failed to read API key from 1Password"
        return 1
    fi

    local env_file="$HOME/.config/fabric/.env"

    # Check if config file already exists
    if [ -f "$env_file" ]; then
        log_warn "Fabric config file '$env_file' already exists"
        read -rp "Do you want to overwrite it? [Y/n]: " result
        if [[ "$result" =~ ^[Nn]$ ]] || [[ -n "$result" && ! "$result" =~ ^[Yy]$ ]]; then
            log_info "Skipping config creation"
            return 0
        fi
    fi

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$env_file")" || {
        log_error "Failed to create config directory"
        return 1
    }

    # Create config file
    cat > "$env_file" << EOF
DEFAULT_VENDOR=Ollama
DEFAULT_MODEL=kimi-k2-thinking:cloud
DEFAULT_MODEL_CONTEXT_LENGTH=256000
PATTERNS_LOADER_GIT_REPO_URL=https://github.com/danielmiessler/fabric.git
PATTERNS_LOADER_GIT_REPO_PATTERNS_FOLDER=data/patterns
CUSTOM_PATTERNS_DIRECTORY=$HOME/.config/fabric/custom_patterns
PROMPT_STRATEGIES_GIT_REPO_URL=https://github.com/danielmiessler/fabric.git
PROMPT_STRATEGIES_GIT_REPO_STRATEGIES_FOLDER=data/strategies
OLLAMA_API_URL=http://localhost:11434
OLLAMA_HTTP_TIMEOUT=20m
YOUTUBE_API_KEY=${yt_key}
EOF

    # Verify the file was created
    if [ ! -f "$env_file" ]; then
        log_error "Failed to create config file at $env_file"
        return 1
    fi

    log_info "Fabric config created successfully at $env_file"
}

setup_env() {
    log_info "Setting up Fabric Environment"
    local env_file="$HOME/.fabric.env"

    # Check if environment file already exists
    if [ -f "$env_file" ]; then
        log_warn "Fabric environment file '$env_file' already exists"
        read -rp "Do you want to overwrite it [Y|n]: " result
        if [[ "$result" != "y" ]] && [[ "$result" != "Y" ]] && [[ -n "$result" ]]; then
            return 0
        fi
    fi

    # Create environment file
    cat > "$env_file" << 'EOF'
# Loop through all files in the ~/.config/fabric/patterns directory
for pattern_file in $HOME/.config/fabric/patterns/*; do
    # Skip if no files found (glob expands to literal)
    [ -e "$pattern_file" ] || continue
    
    # Get the base name of the file
    pattern_name="$(basename "$pattern_file")"
    alias_name="${FABRIC_ALIAS_PREFIX:-}${pattern_name}"

    # Create an alias in the form: alias pattern_name="fabric --pattern pattern_name"
    alias_command="alias $alias_name='fabric --pattern $pattern_name'"

    # Evaluate the alias command to add it to the current shell
    eval "$alias_command"
done

yt() {
    if [ "$#" -eq 0 ] || [ "$#" -gt 2 ]; then
        echo "Usage: yt [-t | --timestamps] youtube-link"
        echo "Use the '-t' flag to get the transcript with timestamps."
        return 1
    fi

    transcript_flag="--transcript"
    if [ "$1" = "-t" ] || [ "$1" = "--timestamps" ]; then
        transcript_flag="--transcript-with-timestamps"
        shift
    fi
    local video_link="$1"
    fabric -y "$video_link" $transcript_flag
}
EOF

    # Verify the file was created
    if [ ! -f "$env_file" ]; then
        log_error "Failed to create environment file at $env_file"
        return 1
    fi

    # Add sourcing to .bashrc if not already present
    local bashrc_file="$HOME/.bashrc"
    # shellcheck disable=SC2016
    local sourcing_line='test -f "$HOME/.fabric.env" && source "$HOME/.fabric.env"'
    
    if ! grep -qF "$sourcing_line" "$bashrc_file"; then
        echo -e "\n# Setup Fabric AI\n$sourcing_line" >> "$bashrc_file"
        log_info "Added Fabric environment sourcing to $bashrc_file"
    else
        log_info "Fabric environment sourcing already exists in $bashrc_file"
    fi
}

main() {
    log_info "Starting Fabric AI setup"

    # Check dependencies first
    if ! check_dependencies; then
        log_error "Missing required dependencies. Please install them and try again."
        exit 1
    fi

    # Install Fabric
    if ! install_fabric; then
        log_error "Fabric installation failed"
        exit 1
    fi

    # Create config
    if ! create_config; then
        log_error "Failed to create Fabric config"
        exit 1
    fi

    # Setup environment
    if ! setup_env; then
        log_error "Failed to setup Fabric environment"
        exit 1
    fi

    log_info "✅ Fabric setup completed successfully!"
}

# Execute main function
main
