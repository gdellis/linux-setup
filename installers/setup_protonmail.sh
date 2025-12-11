#!/usr/bin/env bash

set -euo pipefail
# ------------------------------------------------------------
# Setup Logging
# ------------------------------------------------------------
# region
SCRIPT_NAME=$(basename $0)
SCRIPT_NAME=${SCRIPT_NAME%.*} 

readonly APP_NAME=${SCRIPT_NAME/setup_/}
readonly DL_DIR="${HOME}/downloads/$APP_NAME"
readonly LOG_DIR="${HOME}/logs/$APP_NAME"
readonly LOG_FILE="${LOG_DIR}/$(date +%Y%m%d_%H%M%S)_${APP_NAME}.log"

# Ensure directories exist
test -d "$DL_DIR"  || mkdir -p "$DL_DIR"
test -d "$LOG_DIR" || mkdir -p "$LOG_DIR"

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

# ------------------------------------------------------------------------------
#endregion


