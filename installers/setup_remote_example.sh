#!/usr/bin/env bash
#
# setup_remote_example.sh - Example of remote-capable installer
# Description: Demonstrates how to make installers runnable directly from curl
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/user/repo/main/installers/setup_remote_example.sh)
#

set -euo pipefail

# Detect if we're running locally or remotely
is_running_remotely() {
    local script_path="${BASH_SOURCE[0]}"
    # If script is in a temporary directory, it's likely running remotely
    if [[ "$script_path" == /tmp/* ]] || [[ "$script_path" == /var/tmp/* ]]; then
        return 0  # true
    else
        return 1  # false
    fi
}

# Function to source library remotely or locally
source_library() {
    local library_name="$1"
    
    if is_running_remotely; then
        # Source library from GitHub
        local repo_user="yourusername"  # Replace with actual username
        local repo_name="linux-setup"   # Replace with actual repo name
        
        echo "Sourcing $library_name from remote repository..."
        if ! source <(curl -fsSL "https://raw.githubusercontent.com/$repo_user/$repo_name/main/lib/$library_name"); then
            echo "ERROR: Failed to source $library_name from remote repository"
            exit 1
        fi
    else
        # Source library locally
        local script_dir
        script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
        
        if [[ -f "$script_dir/../lib/$library_name" ]]; then
            # shellcheck source=/dev/null
            source "$script_dir/../lib/$library_name"
        else
            echo "ERROR: Local library $library_name not found"
            exit 1
        fi
    fi
}

# Source required libraries
source_library "logging.sh"
source_library "dependencies.sh"

# Rest of your installer logic here...
# This would be the same as your existing installer scripts

# Example usage of the libraries
main() {
    log_info "Starting remote-capable installer..."
    
    # Check dependencies
    if ! check_dependencies curl; then
        log_error "Missing required dependencies"
        exit 1
    fi
    
    log_success "Installer running successfully!"
    echo "This installer can be run remotely with:"
    echo "bash <(curl -fsSL https://raw.githubusercontent.com/user/repo/main/installers/$(basename "${BASH_SOURCE[0]}"))"
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi