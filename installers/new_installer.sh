#!/usr/bin/env bash

set -euo pipefail

readonly ORIG_PWD=$(pwd)
readonly SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# Check argument first
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <new_script_name>"
    exit 1
fi


# ------------------------------------------------------------
# Setup Logging
# ------------------------------------------------------------
# region
APP_NAME=$(basename "$0" .sh)  # Directly strips .sh extension
readonly DL_DIR="${HOME}/downloads/$APP_NAME"
readonly LOG_DIR="${HOME}/logs/$APP_NAME"
readonly LOG_FILE="${LOG_DIR}/$(date +%Y%m%d_%H%M%S)_${APP_NAME}.log"

# Ensure directories exist
mkdir -p "$DL_DIR"
mkdir -p "$LOG_DIR"

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

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

# shellcheck disable=SC2329
log_info() { log "${GREEN}[INFO]${NC} $*";}
# shellcheck disable=SC2329
log_error() { log "${RED}[ERROR]${NC} $*";}
# shellcheck disable=SC2329
log_success() { log "${GREEN}[SUCCESS]${NC} $*";}
# shellcheck disable=SC2329
log_warning() { log "${YELLOW}[WARNING]${NC} $*";}

log_info "=== $APP_NAME Installer Started ==="
log_info "Log file: $LOG_FILE"
# endregion

# shellcheck disable=SC2329
cleanup()
{
    local exit_code=$?
    
    log_info "Cleaning up..."
    
    # Return to original directory
    cd "$ORIG_PWD" 2>/dev/null || true
    
    log_success "Cleanup complete"
    # shellcheck disable=SC2086
    exit $exit_code

}

# Set trap for various exit signals
trap cleanup EXIT INT TERM ERR

# Validate script name
NEW_SCRIPT="$1"
if [[ "$NEW_SCRIPT" != setup_*.sh ]]; then
    log_error "Script name must follow pattern 'setup_*.sh'" >&2
    exit 1
fi

# Change directories to script directory
if ! cd "$SCRIPT_DIR"; then
    log_error "Cannot change to script directory: $SCRIPT_DIR" >&2
    exit 1
fi

# Check if template exists
TEMPLATE="template.tpl"

if [[ ! -f "$TEMPLATE" ]]; then
    log_error "Template file '$TEMPLATE' not found"
    exit 1
fi

# Check if target exists
if [[ -f "$NEW_SCRIPT" ]]; then
    log_error "Script '$NEW_SCRIPT' already exists"
    exit 1
fi

log_info "Creating new installer script '$NEW_SCRIPT'"

# Create script
if cp "$TEMPLATE" "$NEW_SCRIPT"; then
    chmod +x "$NEW_SCRIPT"  # Make it executable
    log_success "Created '$NEW_SCRIPT'"
    exit 0
else
    log_error "Failed to create '$NEW_SCRIPT'"
    exit 1
fi
