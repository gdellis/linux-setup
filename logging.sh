#!/usr/bin/env bash

# Logging configuration
LOG_LEVEL=${LOG_LEVEL:-INFO}
DEBUG_ENABLED=${DEBUG_ENABLED:-false}
COLOR_ENABLED=${COLOR_ENABLED:-true}

# Color codes
if [[ "$COLOR_ENABLED" == "true" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    PURPLE=''
    CYAN=''
    WHITE=''
    NC=''
fi

# Basic logging function with timestamp
log()
{
    local _msg="$1"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $_msg"
}

# Enhanced logging functions with levels and colors
log_info()
{
    local _msg="$1"
    if [[ "$LOG_LEVEL" == "INFO" || "$LOG_LEVEL" == "DEBUG" ]]; then
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${GREEN}[INFO]${NC} $_msg"
    fi
}

log_warn()
{
    local _msg="$1"
    if [[ "$LOG_LEVEL" == "INFO" || "$LOG_LEVEL" == "DEBUG" || "$LOG_LEVEL" == "WARN" ]]; then
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${YELLOW}[WARN]${NC} $_msg" >&2
    fi
}

log_error()
{
    local _msg="$1"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${RED}[ERROR]${NC} $_msg" >&2
}

log_debug()
{
    local _msg="$1"
    if [[ "$DEBUG_ENABLED" == "true" && ("$LOG_LEVEL" == "DEBUG" || -z "$LOG_LEVEL") ]]; then
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${CYAN}[DEBUG]${NC} $_msg"
    fi
}

# Error handling function
handle_error()
{
    local _msg="$1"
    log_error "$_msg"
    exit 1
}
