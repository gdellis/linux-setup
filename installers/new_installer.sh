#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# ------------------------------------------------------------
# Setup Logging
# ------------------------------------------------------------
# region
readonly APP_NAME=fabric
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
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions with color and file output
log()
{
    local msg
    msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo -e "$msg" | tee -a "$LOG_FILE"
}

log_info() { log "${GREEN}[INFO]${NC} $*";}
log_error() { log "${RED}[ERROR]${NC} $*";}
log_success() { log "${GREEN}[SUCCESS]${NC} $*";}
log_warning() { log "${YELLOW}[WARNING]${NC} $*";}

log_info "=== $APP_NAME Installer Started ==="
log_info "Log file: $LOG_FILE"
# endregion

cleanup()
{
    local exit_code=$?
    
    log_info "Cleaning up..."
    
    # Remove temporary files/directories
    # if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
    #     rm -rf "$TEMP_DIR"
    # fi
    
    # # Kill background processes spawned by this script
    # if [[ -n "${BG_PIDS:-}" ]]; then
    #     for pid in $BG_PIDS; do
    #         kill "$pid" 2>/dev/null || true
    #     done
    # fi
    
    # Close file descriptors if opened
    # exec 3>&- 4>&- 2>/dev/null || true
    
    # Restore terminal settings if modified
    # stty sane 2>/dev/null || true

    # Return to original directory if pushd was used
    while popd &>/dev/null; do :; done
    
    echo "Cleanup complete"
    exit $exit_code

}

# Set trap for various exit signals
trap cleanup EXIT INT TERM ERR

pushd "$SCRIPT_DIR" || ( log_error "Could not change directories to '$SCRIPT_DIR'"; exit 1 )
NEW_SCRIPT="$1"

log_info "Creating new installer script '$NEW_SCRIPT'"

if cp template.tpl "$NEW_SCRIPT";then
    log_success "The new script '$NEW_SCRIPT' is now ready"
    exit 1
else
    log_error "The new script '$NEW_SCRIPT' could not be created"
    exit 0
fi