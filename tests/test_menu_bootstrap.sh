#!/usr/bin/env bash
#
# test_menu_bootstrap.sh - Test that menus can be run through the bootstrap
# Description: Tests that the bootstrap script can run both TUI menus
#

set -euo pipefail

echo "Testing menu bootstrap functionality..."

# Test that bootstrap script can show help with menu options
echo "Test 1: Testing bootstrap help includes menu options..."
if ./bootstrap.sh --help | grep -q "menu" && ./bootstrap.sh --help | grep -q "python-menu"; then
    echo "✅ PASS: Bootstrap help includes menu options"
else
    echo "❌ FAIL: Bootstrap help missing menu options"
    exit 1
fi

# Test that bootstrap script has menu handling logic
echo "Test 2: Testing bootstrap script has menu handling..."
if grep -q "python-menu" bootstrap.sh && grep -q "MENU_URL" bootstrap.sh; then
    echo "✅ PASS: Bootstrap script has menu handling logic"
else
    echo "❌ FAIL: Bootstrap script missing menu handling logic"
    exit 1
fi

# Test that py_menu.py exists and is executable
echo "Test 3: Checking Python menu exists..."
if [[ -f py_menu.py ]] && [[ -x py_menu.py ]]; then
    echo "✅ PASS: Python menu exists and is executable"
else
    echo "❌ FAIL: Python menu missing or not executable"
    exit 1
fi

echo
echo "✅ Menu bootstrap tests completed successfully!"
echo
echo "To run the menus remotely:"
echo "  bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) menu"
echo "  bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) python-menu"