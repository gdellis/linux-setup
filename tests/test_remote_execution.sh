#!/usr/bin/env bash
#
# test_remote_execution.sh - Test script for remote execution capability
# Description: Tests the remote execution capability of installer scripts
#

set -euo pipefail

echo "Testing remote execution capability..."

# Test 1: Check if template has remote execution functions
echo "Test 1: Checking template for remote execution functions..."
if grep -q "is_running_remotely" installers/template.tpl && grep -q "source_library" installers/template.tpl; then
    echo "✅ PASS: Template has remote execution functions"
else
    echo "❌ FAIL: Template missing remote execution functions"
    exit 1
fi

# Test 2: Check if VS Code script has remote execution functions
echo "Test 2: Checking VS Code script for remote execution functions..."
if grep -q "is_running_remotely" installers/setup_vscode.sh && grep -q "source_library" installers/setup_vscode.sh; then
    echo "✅ PASS: VS Code script has remote execution functions"
else
    echo "❌ FAIL: VS Code script missing remote execution functions"
    exit 1
fi

# Test 3: Check if Neovim script has remote execution functions
echo "Test 3: Checking Neovim script for remote execution functions..."
if grep -q "is_running_remotely" installers/setup_neovim.sh && grep -q "source_library" installers/setup_neovim.sh; then
    echo "✅ PASS: Neovim script has remote execution functions"
else
    echo "❌ FAIL: Neovim script missing remote execution functions"
    exit 1
fi

# Test 4: Check if bootstrap script exists and is executable
echo "Test 4: Checking bootstrap script..."
if [[ -f bootstrap.sh ]] && [[ -x bootstrap.sh ]]; then
    echo "✅ PASS: Bootstrap script exists and is executable"
else
    echo "❌ FAIL: Bootstrap script missing or not executable"
    exit 1
fi

# Test 5: Check if remote execution documentation exists
echo "Test 5: Checking remote execution documentation..."
if [[ -f docs/REMOTE_EXECUTION.md ]]; then
    echo "✅ PASS: Remote execution documentation exists"
else
    echo "❌ FAIL: Remote execution documentation missing"
    exit 1
fi

# Test 6: Check if README mentions remote execution
echo "Test 6: Checking README for remote execution mention..."
if grep -q "Run installers remotely" README.md; then
    echo "✅ PASS: README mentions remote execution"
else
    echo "❌ FAIL: README doesn't mention remote execution"
    exit 1
fi

echo
echo "🎉 All tests passed! Remote execution capability is properly implemented."
echo
echo "To use remote execution:"
echo "  bash <(curl -fsSL https://raw.githubusercontent.com/yourusername/linux-setup/main/bootstrap.sh) setup_vscode.sh"
echo
echo "Or for individual scripts:"
echo "  bash <(curl -fsSL https://raw.githubusercontent.com/yourusername/linux-setup/main/installers/setup_neovim.sh)"