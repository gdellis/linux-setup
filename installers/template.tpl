#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------------
# Setup Logging
# ------------------------------------------------------------
# region

APP_NAME=your_app_name
DL_DIR="${HOME}/downloads/$AMM_NAME"
LOG_DIR="${HOME}/logs/$APP_NAME"
LOG_FILE="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure directories exist
mkdir -p "$DL_DIR"
mkdir -p "$LOG_DIR"

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