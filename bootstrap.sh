#!/usr/bin/env bash
#
# bootstrap.sh - Run any installer script remotely
# Description: Bootstrap script to run linux-setup installers directly from GitHub
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/yourusername/linux-setup/main/bootstrap.sh) [installer_name] [options]
#
# Examples:
#   bash <(curl -fsSL https://raw.githubusercontent.com/yourusername/linux-setup/main/bootstrap.sh) setup_vscode.sh
#   bash <(curl -fsSL https://raw.githubusercontent.com/yourusername/linux-setup/main/bootstrap.sh) setup_neovim.sh --yes

set -euo pipefail

# Configuration - Update these with your actual GitHub details
readonly REPO_USER="yourusername"  # Replace with your GitHub username
readonly REPO_NAME="linux-setup"   # Replace with your repository name
readonly REPO_BRANCH="main"        # Replace with your default branch

# Show help if no arguments
if [[ $# -eq 0 ]] || [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Linux Setup Bootstrap"
    echo "Run installer scripts directly from GitHub"
    echo ""
    echo "Usage:"
    echo "  bash <(curl -fsSL $0) [installer_name] [options]"
    echo ""
    echo "Examples:"
    echo "  bash <(curl -fsSL $0) setup_vscode.sh"
    echo "  bash <(curl -fsSL $0) setup_neovim.sh --yes"
    echo "  bash <(curl -fsSL $0) setup_fabric.sh -y"
    echo ""
    echo "Available installers:"
    echo "  setup_vscode.sh    - Visual Studio Code"
    echo "  setup_neovim.sh    - Neovim"
    echo "  setup_gum.sh       - Gum TUI tool"
    echo "  setup_nala.sh      - Nala package manager"
    echo "  setup_fabric.sh    - Fabric AI"
    echo "  setup_ollama.sh    - Ollama AI"
    echo "  setup_1password.sh - 1Password"
    echo "  setup_protonvpn.sh - ProtonVPN"
    echo ""
    echo "Note: Not all installers may be available. Check the repository for the full list."
    exit 0
fi

# Get installer name and options
INSTALLER_NAME="$1"
shift
OPTIONS="$*" || true

# Validate installer name format
if [[ "$INSTALLER_NAME" != setup_*.sh ]]; then
    echo "ERROR: Installer name must start with 'setup_' and end with '.sh'"
    echo "Example: setup_vscode.sh"
    exit 1
fi

# Download and run the installer
echo "Downloading and running $INSTALLER_NAME from GitHub..."
INSTALLER_URL="https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$REPO_BRANCH/installers/$INSTALLER_NAME"

# Download installer to temporary file
TEMP_SCRIPT=$(mktemp)
if ! curl -fsSL "$INSTALLER_URL" -o "$TEMP_SCRIPT"; then
    echo "ERROR: Failed to download $INSTALLER_NAME"
    echo "Please check that the installer exists and the repository details are correct."
    rm -f "$TEMP_SCRIPT"
    exit 1
fi

# Run the installer with provided options
echo "Running $INSTALLER_NAME..."
if [[ -n "${OPTIONS:-}" ]]; then
    bash "$TEMP_SCRIPT" $OPTIONS
else
    bash "$TEMP_SCRIPT"
fi

# Clean up
rm -f "$TEMP_SCRIPT"