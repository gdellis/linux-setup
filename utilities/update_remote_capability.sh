#!/usr/bin/env bash
#
# update_remote_capability.sh - Update all installer scripts with remote execution capability
# Description: Adds remote execution capability to all existing installer scripts
#

set -euo pipefail

readonly SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Get list of all setup_*.sh scripts except the template and this script
mapfile -t installer_scripts < <(find "$SCRIPT_DIR" -name "setup_*.sh" -type f | sort)

echo "Updating ${#installer_scripts[@]} installer scripts with remote execution capability..."

for script in "${installer_scripts[@]}"; do
    echo "Updating $(basename "$script")..."
    
    # Skip if already updated (check for is_running_remotely function)
    if grep -q "is_running_remotely" "$script"; then
        echo "  Already updated, skipping..."
        continue
    fi
    
    # Create backup
    cp "$script" "${script}.backup"
    
    # Read the entire script
    script_content=$(cat "$script")
    
    # Extract the header (everything before the first function or main code)
    header_end=$(grep -n -m 1 "^set -euo pipefail" "$script" | cut -d: -f1)
    if [[ -z "$header_end" ]]; then
        echo "  Warning: Could not find set -euo pipefail, skipping..."
        continue
    fi
    
    header=$(head -n "$header_end" "$script")
    rest_of_script=$(tail -n +"$((header_end + 1))" "$script")
    
    # Add remote execution capability
    remote_code='
# Detect if we'"'"'re running locally or remotely
is_running_remotely() {
    local script_path="${BASH_SOURCE[0]}"
    # If script is in a temporary directory, it'"'"'s likely running remotely
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
'
    
    # Update the sourcing section to remove old library sourcing
    # Remove lines that source logging.sh and dependencies.sh
    updated_rest=$(echo "$rest_of_script" | sed '/source.*lib\/logging.sh/d' | sed '/source.*lib\/dependencies.sh/d' | sed '/SCRIPT_DIR.*dirname/d' | sed '/Get script directory/d')
    
    # Remove empty lines at the beginning of updated_rest
    updated_rest=$(echo "$updated_rest" | sed '1{/^$/d}')
    
    # Combine everything
    {
        echo "$header"
        echo "$remote_code"
        echo
        echo "$updated_rest"
    } > "$script"
    
    # Make sure the script is still executable
    chmod +x "$script"
    
    echo "  Updated successfully"
done

echo
echo "All installer scripts have been updated with remote execution capability."
echo "Backup files have been created with .backup extension."
echo
echo "IMPORTANT: You need to update the repo_user and repo_name variables"
echo "in each script with your actual GitHub username and repository name."