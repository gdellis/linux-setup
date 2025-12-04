#!/usr/bin/env bash

set -euo pipefail

# Configuration
APP_NAME=the_app_name
VERSION="2.3.1"
BASE_URL="https://github.com/OrcaSlicer/OrcaSlicer/releases/download/${VERSION}"
DL_DIR="${HOME}/downloads/AMM_NAME"
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
log_info() {
  local msg
  msg="[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*"
  echo -e "${GREEN}${msg}${NC}" | tee -a "$LOG_FILE" >/dev/null
  echo -e "${GREEN}${msg}${NC}"
}

log_error() {
  local msg
  msg="[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*"
  echo -e "${RED}${msg}${NC}" | tee -a "$LOG_FILE" >/dev/null
  echo -e "${RED}${msg}${NC}" >&2
}

log_success() {
  local msg
  msg="[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $*"
  echo -e "${BLUE}${msg}${NC}" | tee -a "$LOG_FILE" >/dev/null
  echo -e "${BLUE}${msg}${NC}"
}

log_warning() {
  local msg
  msg="[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING] $*"
  echo -e "${YELLOW}${msg}${NC}" | tee -a "$LOG_FILE" >/dev/null
  echo -e "${YELLOW}${msg}${NC}"
}

log_info "=== $APP_NAME Installer Started ==="
log_info "Log file: $LOG_FILE"