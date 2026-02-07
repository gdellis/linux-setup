#!/bin/bash
#
# uninstaller_generator.sh - Uninstall Script Generator
# Description: Generates companion uninstall scripts for installer scripts
# Category: Utilities
# Usage: ./uninstaller_generator.sh [installer_script]
#

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
readonly INSTALLERS_DIR="$SCRIPT_DIR/installers"
readonly UNINSTALLERS_DIR="$SCRIPT_DIR/uninstallers"

# Ensure uninstalled directory exists
mkdir -p "$UNINSTALLERS_DIR"

generate_uninstaller() {
    local installer="$1"
    local installer_name="$(basename "$installer")"
    local uninstaller_name="uninstall_${installer_name#setup_}"
    local uninstaller="$UNINSTALLERS_DIR/$uninstaller_name"
    
    # Extract metadata from installer
    local description category
    description=$(grep "^# Description:" "$installer" | sed 's/^# Description: //' | head -1)
    category=$(grep "^# Category:" "$installer" | sed 's/^# Category: //' | head -1)
    
    cat > "$uninstaller" <<'EOF'
#!/usr/bin/env bash
#
# Description: Auto-generated uninstall script (template - customize as needed)
# Category: Auto-generated
#

set -euo pipefail

# Source libraries
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../lib/dependencies.sh"

log_info "Uninstaller template generated"
log_warn "Please customize this uninstaller for the specific software"
EOF

    chmod +x "$uninstaller"
    echo "$uninstaller"
}

main() {
    if [ $# -eq 0 ]; then
        echo "Usage: $0 [installer_script]"
        exit 1
    fi
    
    generate_uninstaller "$1"
}

main "$@"