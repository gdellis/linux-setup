#!/usr/bin/env bash

echo "Remote Execution Usage Examples"
echo "==============================="

echo "1. Run an installer directly from GitHub:"
echo "   bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/installers/setup_vscode.sh)"
echo ""

echo "2. Run an installer with custom repository details:"
echo "   REPO_USER=myuser REPO_NAME=myrepo bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/installers/setup_vscode.sh)"
echo ""

echo "3. Run an installer from a specific branch:"
echo "   REPO_USER=gdellis REPO_NAME=linux-setup REPO_BRANCH=develop bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/installers/setup_vscode.sh)"
echo ""

echo "4. Use the bootstrap script to run any installer:"
echo "   bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) setup_vscode.sh"
echo ""

echo "5. Run the bash TUI menu directly:"
echo "   bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) menu"
echo ""

echo "6. Run the Python TUI menu directly:"
echo "   bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) python-menu"
echo ""

echo "7. Run the Python TUI menu with custom repository:"
echo "   REPO_USER=myuser REPO_NAME=myrepo bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) python-menu"
echo ""

echo "Environment Variables:"
echo "  REPO_USER  - GitHub username (default: gdellis)"
echo "  REPO_NAME  - Repository name (default: linux-setup)"
echo "  REPO_BRANCH - Repository branch (default: main)"
echo ""

echo "To test with your own repository, replace the values above with your GitHub username and repository name."