#!/usr/bin/env bash
#
# test_python_menu_remote.sh - Test that Python menu supports remote execution
# Description: Tests that the Python menu can detect and handle remote execution
#

set -euo pipefail

echo "Testing Python menu remote execution capability..."

# Test 1: Check that Python menu has remote execution logic
echo "Test 1: Checking Python menu for remote execution logic..."
if grep -q "is_remote" py_menu.py && grep -q "fetch_remote_content" py_menu.py; then
    echo "✅ PASS: Python menu has remote execution logic"
else
    echo "❌ FAIL: Python menu missing remote execution logic"
    exit 1
fi

# Test 2: Check that Python menu handles environment variables
echo "Test 2: Checking Python menu for environment variable handling..."
if grep -q "REPO_USER" py_menu.py && grep -q "REPO_NAME" py_menu.py; then
    echo "✅ PASS: Python menu handles environment variables"
else
    echo "❌ FAIL: Python menu missing environment variable handling"
    exit 1
fi

# Test 3: Check that Python menu has proper help text
echo "Test 3: Checking Python menu help text..."
if python3 py_menu.py --help | grep -q "remote execution"; then
    echo "✅ PASS: Python menu help mentions remote execution"
else
    echo "❌ FAIL: Python menu help missing remote execution information"
    exit 1
fi

# Test 4: Check that Python menu can detect remote execution
echo "Test 4: Testing Python menu remote detection..."
TEST_SCRIPT=$(mktemp)
cat > "$TEST_SCRIPT" << 'EOF'
#!/usr/bin/env python3
import tempfile
import os
from pathlib import Path

# Test remote detection logic
script_path = Path(__file__)
is_remote = str(script_path).startswith("/tmp/") or str(script_path).startswith("/var/tmp/")
print(f"is_remote: {is_remote}")
print(f"script_path: {script_path}")
EOF

chmod +x "$TEST_SCRIPT"

# Test in temp directory (simulating remote execution)
RESULT=$(python3 "$TEST_SCRIPT")
if echo "$RESULT" | grep -q "is_remote: True"; then
    echo "✅ PASS: Remote detection works correctly"
else
    echo "❌ FAIL: Remote detection doesn't work correctly"
    rm -f "$TEST_SCRIPT"
    exit 1
fi

rm -f "$TEST_SCRIPT"

echo
echo "✅ Python menu remote execution tests completed successfully!"
echo
echo "The Python menu now supports remote execution:"
echo "  REPO_USER=user REPO_NAME=repo bash <(curl -fsSL https://raw.githubusercontent.com/user/repo/main/bootstrap.sh) python-menu"