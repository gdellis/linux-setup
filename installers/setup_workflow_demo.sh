#!/usr/bin/env bash
#
# setup_workflow_demo.sh - Example Installer (Workflow Demo)
# Description: Demonstrates complete GitHub workflow from branch to merge
# Category: Development Tools
# Usage: ./setup_workflow_demo.sh [OPTIONS]
#        -y, --yes, --non-interactive    Skip confirmation prompts
#        -h, --help                      Show help message
#

set -euo pipefail

# Parse command line arguments
NON_INTERACTIVE=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes|--non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -y, --yes, --non-interactive    Skip confirmation prompts"
            echo "  -h, --help                      Show this help message"
            echo ""
            echo "Purpose: Demonstrates complete GitHub workflow"
            echo "Author: $(basename "$0")"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# Source libraries
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Source shared libraries
source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../lib/dependencies.sh"

echo "Workflow Demo Installer"
echo "======================="
echo
echo "This installer demonstrates the complete GitHub workflow:"
echo "1. Create feature branch"
echo "2. Validate and test changes"
echo "3. Commit and push changes"
echo "4. Create pull request"
echo "5. Pass automated checks (ShellCheck)"
echo "6. Code review and merge"
echo
echo "Features:"
echo "- ✓ Proper metadata (Description, Category)"
echo "- ✓ Bash strict mode (set -euo pipefail)"
echo "- ✓ ShellCheck compliance (SC2034 excluded)"
echo "- ✓ Library references (logging.sh, dependencies.sh)"
echo "- ✓ Consistent structure with other installers"
echo
echo "Installation complete! Check the AGENTS.md file for workflow details."