#!/usr/bin/env bash
#
# bootstrap.sh - Run any installer script remotely
# Description: Bootstrap script to run linux-setup installers directly from GitHub
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) [installer_name] [options]
#
# Examples:
#   bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) setup_vscode.sh
#   bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) setup_neovim.sh --yes
#   bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) menu

set -euo pipefail

# Configuration - Use environment variables or prompt user
REPO_USER="${REPO_USER:-gdellis}"
REPO_NAME="${REPO_NAME:-linux-setup}"
REPO_BRANCH="${REPO_BRANCH:-main}"

# Prompt user if variables are not set
if [[ -z "$REPO_USER" ]]; then
    echo "Repository user not set. Please enter the GitHub username:"
    read -r REPO_USER
    if [[ -z "$REPO_USER" ]]; then
        echo "ERROR: Repository user is required"
        exit 1
    fi
    export REPO_USER
fi

if [[ -z "$REPO_NAME" ]]; then
    echo "Repository name not set. Please enter the repository name:"
    read -r REPO_NAME
    if [[ -z "$REPO_NAME" ]]; then
        echo "ERROR: Repository name is required"
        exit 1
    fi
    export REPO_NAME
fi

# Show help if no arguments
if [[ $# -eq 0 ]] || [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Linux Setup Bootstrap"
    echo "Run installer scripts directly from GitHub"
    echo ""
    echo "Usage:"
    echo "  bash <(curl -fsSL $0) [installer_name] [options]"
    echo "  REPO_USER=username REPO_NAME=repo-name bash <(curl -fsSL $0) [installer_name] [options]"
    echo ""
    echo "Environment Variables:"
    echo "  REPO_USER  - GitHub username"
    echo "  REPO_NAME  - Repository name"
    echo "  REPO_BRANCH - Repository branch (default: main)"
    echo ""
    echo "If not set, you will be prompted to enter these values."
    echo ""
    echo "Examples:"
    echo "  bash <(curl -fsSL $0) setup_vscode.sh"
    echo "  bash <(curl -fsSL $0) setup_neovim.sh --yes"
    echo "  bash <(curl -fsSL $0) setup_fabric.sh -y"
    echo "  bash <(curl -fsSL $0) menu"
    echo "  bash <(curl -fsSL $0) python-menu"
    echo "  REPO_USER=myuser REPO_NAME=myrepo bash <(curl -fsSL $0) setup_vscode.sh"
    echo ""
    echo "Special commands:"
    echo "  menu        - Run the bash TUI menu"
    echo "  python-menu - Run the Python TUI menu"
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

# Handle special commands
if [[ "$INSTALLER_NAME" == "menu" ]]; then
    echo "Downloading and running bash menu from GitHub..."
    MENU_URL="https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$REPO_BRANCH/menu.sh"
    
    # Download menu to temporary file
    TEMP_SCRIPT=$(mktemp)
    if ! curl -fsSL "$MENU_URL" -o "$TEMP_SCRIPT"; then
        echo "ERROR: Failed to download menu.sh"
        echo "Please check that the menu exists and the repository details are correct."
        rm -f "$TEMP_SCRIPT"
        exit 1
    fi
    
    # Run the menu
    echo "Running menu..."
    if [[ -n "${OPTIONS:-}" ]]; then
        bash "$TEMP_SCRIPT" $OPTIONS
    else
        bash "$TEMP_SCRIPT"
    fi
    
    # Clean up
    rm -f "$TEMP_SCRIPT"
    exit 0
elif [[ "$INSTALLER_NAME" == "python-menu" ]]; then
    echo "Downloading and running Python menu from GitHub..."
    PY_MENU_URL="https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$REPO_BRANCH/py_menu.py"
    
    # Download Python menu to temporary file
    TEMP_SCRIPT=$(mktemp)
    if ! curl -fsSL "$PY_MENU_URL" -o "$TEMP_SCRIPT"; then
        echo "ERROR: Failed to download py_menu.py"
        echo "Please check that the Python menu exists and the repository details are correct."
        rm -f "$TEMP_SCRIPT"
        exit 1
    fi
    
    # Make executable
    chmod +x "$TEMP_SCRIPT"
    
    # Run the Python menu
    echo "Running Python menu..."
    if [[ -n "${OPTIONS:-}" ]]; then
        python3 "$TEMP_SCRIPT" $OPTIONS
    else
        python3 "$TEMP_SCRIPT"
    fi
    
    # Clean up
    rm -f "$TEMP_SCRIPT"
    exit 0
fi

# Validate installer name format
if [[ "$INSTALLER_NAME" != setup_*.sh ]]; then
    echo "ERROR: Installer name must start with 'setup_' and end with '.sh'"
    echo "Example: setup_vscode.sh"
    echo ""
    echo "For menus, use: menu (for bash) or python-menu (for Python)"
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