#!/usr/bin/env bash
#
# logging.sh - Shared Logging Library
# Description: Provides colored logging functions with dual output (terminal + file) and backup functionality
# Usage: Source this file in your scripts: source "$SCRIPT_DIR/../lib/logging.sh"
#

# Logging configuration
LOG_LEVEL=${LOG_LEVEL:-INFO}
DEBUG_ENABLED=${DEBUG_ENABLED:-false}
COLOR_ENABLED=${COLOR_ENABLED:-true}

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Base logging function with dual output (terminal + file)
# Outputs colored text to terminal and ANSI-stripped text to log file (if $LOG_FILE is set)
log()
{
    local colored_msg plain_msg
    colored_msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"

    # Strip ANSI color codes for log file
    plain_msg=$(echo -e "$colored_msg" | sed -E 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mK]//g')

    # Output to terminal (with colors)
    echo -e "$colored_msg"

    # Output to log file (without colors) if LOG_FILE is set
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "$plain_msg" >> "$LOG_FILE"
    fi
}

# Enhanced logging functions with levels and colors
log_info()
{
    if [[ "$LOG_LEVEL" == "INFO" || "$LOG_LEVEL" == "DEBUG" ]]; then
        log "${GREEN}[INFO]${NC} $*"
    fi
}

log_success()
{
    log "${GREEN}[SUCCESS]${NC} $*"
}

log_warn()
{
    if [[ "$LOG_LEVEL" == "INFO" || "$LOG_LEVEL" == "DEBUG" || "$LOG_LEVEL" == "WARN" ]]; then
        log "${YELLOW}[WARN]${NC} $*"
    fi
}

# Alias for compatibility with installer scripts
log_warning()
{
    log_warn "$*"
}

log_error()
{
    log "${RED}[ERROR]${NC} $*"
}

log_debug()
{
    if [[ "$DEBUG_ENABLED" == "true" && ("$LOG_LEVEL" == "DEBUG" || -z "$LOG_LEVEL") ]]; then
        log "${CYAN}[DEBUG]${NC} $*"
    fi
}

# Error handling function
handle_error()
{
    local _msg="$1"
    log_error "$_msg"
    exit 1
}

# Backup file function - creates timestamped backup before overwriting
backup_file()
{
    local file="$1"

    if [[ ! -f "$file" ]]; then
        # File doesn't exist, no backup needed
        return 0
    fi

    local backup_file="${file}.backup.$(date +%Y%m%d_%H%M%S)"

    if cp "$file" "$backup_file"; then
        log_info "Backed up existing file to: $backup_file"
        return 0
    else
        log_error "Failed to create backup of $file"
        return 1
    fi
}
