#!/usr/bin/env bash
set -euo pipefail

# Save and change directories
readonly ORIG_PWD=$(pwd)

# shellcheck disable=SC2034
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )



# ------------------------------------------------------------
# Setup Logging
# ------------------------------------------------------------
# region
SCRIPT_NAME=$(basename "$0" .sh)
APP_NAME="${SCRIPT_NAME/setup_/}"
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

    # Return to original directory
    cd "$ORIG_PWD" 2>/dev/null || true
    
    echo "Cleanup complete"
    # shellcheck disable=SC2086
    exit $exit_code

}

# Set trap for various exit signals
trap cleanup EXIT INT TERM ERR

# ------------------------------------------------------------

log_info "📥 Downloading Proton VPN"

readonly URL="https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.8_all.deb"
readonly FILE="$DL_DIR/protonvpn.deb"

if curl --output "$FILE" "$URL";then
    sudo nala install -y $FILE
    sudo nala update 
    
    log_info "Checking the repos integrity"

    echo "0b14e71586b22e498eb20926c48c7b434b751149b1f2af9902ef1cfe6b03e180 protonvpn-stable-release_1.0.8_all.deb" \
    | sha256sum --check -

    sudo nala -y install proton-vpn-gnome-desktop

    log_success "Proton VPN installed successfully"
    exit 0
else log_error "Error downloading package"
    exit 1
fi

exit 0
