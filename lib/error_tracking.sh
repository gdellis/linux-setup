# error_tracking.sh - Centralized Error Tracking Library
# Description: Provides centralized error tracking and reporting across all installer scripts
# Usage: Source this file in your scripts: source "$SCRIPT_DIR/../lib/error_tracking.sh"
# Note: This is a library file meant to be sourced, not executed directly
#

# Ensure logging library is loaded
if ! declare -f log_info &> /dev/null; then
    echo "ERROR: error_tracking.sh requires logging.sh to be sourced first" >&2
    return 1 2>/dev/null || exit 1
fi

# Error tracking configuration
readonly ERROR_LOG_DIR="${HOME}/logs/linux-setup"
readonly ERROR_LOG_FILE="${ERROR_LOG_DIR}/errors.$(date +%Y%m%d).log"
readonly ERROR_METRICS_FILE="${ERROR_LOG_DIR}/metrics.json"

# Initialize error tracking directory
_init_error_tracking() {
    if [[ ! -d "$ERROR_LOG_DIR" ]]; then
        mkdir -p "$ERROR_LOG_DIR" 2>/dev/null || true
    fi
    
    # Initialize metrics file if it doesn't exist
    if [[ ! -f "$ERROR_METRICS_FILE" ]]; then
        echo '{"installers": {}, "errors": [], "successes": 0}' > "$ERROR_METRICS_FILE"
    fi
}

# Track an error occurrence
track_error() {
    local installer_name="${1:-unknown}"
    local error_code="${2:-1}"
    local error_message="${3:-Unknown error}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    _init_error_tracking
    
    # Log to error file
    {
        echo "[${timestamp}] [${installer_name}] Error ${error_code}: ${error_message}"
    } >> "$ERROR_LOG_FILE"
    
    # Update metrics
    if command -v jq &> /dev/null; then
        local temp_file
        temp_file=$(mktemp)
        
        jq --arg name "$installer_name" --arg code "$error_code" --arg msg "$error_message" --arg ts "$timestamp" \
           '.errors += [{installer: $name, code: $code, message: $msg, timestamp: $ts}]' \
           "$ERROR_METRICS_FILE" > "$temp_file" 2>/dev/null
        
        if [[ -f "$temp_file" ]]; then
            mv "$temp_file" "$ERROR_METRICS_FILE" 2>/dev/null || true
        fi
    fi
    
    # Log to stdout
    log_error "[${installer_name}] Error ${error_code}: ${error_message}"
}

# Track a successful installation
track_success() {
    local installer_name="${1:-unknown}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    _init_error_tracking
    
    # Log success
    log_info "[${installer_name}] Installation completed successfully"
    
    # Update metrics
    if command -v jq &> /dev/null; then
        local temp_file
        temp_file=$(mktemp)
        
        jq --arg name "$installer_name" --arg ts "$timestamp" \
           '.successes += 1 | .installers[$name] = (.installers[$name] // 0) + 1' \
           "$ERROR_METRICS_FILE" > "$temp_file" 2>/dev/null
        
        if [[ -f "$temp_file" ]]; then
            mv "$temp_file" "$ERROR_METRICS_FILE" 2>/dev/null || true
        fi
    fi
}

# Get error tracking directory
get_error_log_dir() {
    echo "$ERROR_LOG_DIR"
}

# Get error statistics
get_error_stats() {
    _init_error_tracking
    
    if [[ ! -f "$ERROR_METRICS_FILE" ]]; then
        echo "No error metrics available"
        return 1
    fi
    
    if command -v jq &> /dev/null; then
        echo "Error Tracking Statistics:"
        echo "========================="
        
        local total_successes
        total_successes=$(jq -r '.successes' "$ERROR_METRICS_FILE" 2>/dev/null || echo "0")
        
        local total_errors
        total_errors=$(jq -r '.errors | length' "$ERROR_METRICS_FILE" 2>/dev/null || echo "0")
        
        echo "Total successful installations: $total_successes"
        echo "Total errors: $total_errors"
        echo
        
        # Show installer-specific stats
        local installer_stats
        installer_stats=$(jq -r '.installers | to_entries | sort_by(-.value)[] | "  \(.key): \(.value) successful installations"' "$ERROR_METRICS_FILE" 2>/dev/null || true)
        
        if [[ -n "$installer_stats" ]]; then
            echo "Successful installations by installer:"
            echo "$installer_stats"
            echo
        fi
        
        # Show recent errors
        local recent_errors
        recent_errors=$(jq -r '.errors[-5:][] | "  [\(.timestamp)] \(.installer) (code: \(.code)): \(.message)"' "$ERROR_METRICS_FILE" 2>/dev/null || true)
        
        if [[ -n "$recent_errors" ]]; then
            echo "Recent errors (last 5):"
            echo "$recent_errors"
        fi
    else
        log_warn "jq not available, showing raw log files:"
        ls -lh "$ERROR_LOG_DIR"/*.log 2>/dev/null || echo "  No error logs found"
    fi
}

# Clean old error logs (keep last 30 days)
cleanup_old_errors() {
    _init_error_tracking
    
    local days_to_keep="${1:-30}"
    
    if [[ -d "$ERROR_LOG_DIR" ]]; then
        find "$ERROR_LOG_DIR" -name "*.log" -mtime +"$days_to_keep" -delete 2>/dev/null || true
        log_info "Cleaned up old error logs (older than $days_to_keep days)"
    fi
}

# Generate error report
generate_error_report() {
    _init_error_tracking
    
    local report_file
    report_file="${ERROR_LOG_DIR}/error_report.$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "Linux Setup Installer Error Report"
        echo "==================================="
        echo "Generated: $(date)"
        echo
        
        # Summary
        local total_errors
        total_errors=$(grep -c "^\[" "$ERROR_LOG_FILE" 2>/dev/null || echo "0")
        
        echo "Summary:"
        echo "  Total errors recorded: $total_errors"
        echo
        
        # Error breakdown by installer
        if [[ -f "$ERROR_LOG_FILE" ]]; then
            echo "Errors by installer:"
            grep "^\[" "$ERROR_LOG_FILE" 2>/dev/null | \
                sed -E 's/.*\[([^]]+)\].*/\1/' | \
                sort | uniq -c | sort -nr | \
                while read -r count installer; do
                    echo "  $installer: $count errors"
                done
            echo
            
            # Recent errors
            echo "Recent errors:"
            tail -20 "$ERROR_LOG_FILE" 2>/dev/null | sed 's/^/  /'
        fi
        
    } > "$report_file"
    
    log_info "Error report generated: $report_file"
    echo "$report_file"
}

# Initialize on load
_init_error_tracking