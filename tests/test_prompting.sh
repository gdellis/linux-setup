#!/usr/bin/env bash
#
# test_prompting.sh - Test that prompting functionality works for remote execution
# Description: Tests that scripts prompt the user for repository information when not set
#

set -euo pipefail

echo "Testing prompting functionality..."

# Test 1: Check that template prompts user when variables are not set
echo "Test 1: Checking template for prompting functionality..."
if grep -q "Repository user not set" installers/template.tpl && grep -q "read -r repo_user" installers/template.tpl; then
    echo "✅ PASS: Template prompts user for repository information"
else
    echo "❌ FAIL: Template doesn't prompt user for repository information"
    exit 1
fi

# Test 2: Check that bootstrap prompts user when variables are not set
echo "Test 2: Checking bootstrap for prompting functionality..."
if grep -q "Repository user not set" bootstrap.sh && grep -q "read -r REPO_USER" bootstrap.sh; then
    echo "✅ PASS: Bootstrap prompts user for repository information"
else
    echo "❌ FAIL: Bootstrap doesn't prompt user for repository information"
    exit 1
fi

# Test 3: Create a simple test script to verify prompting works
echo "Test 3: Testing prompting functionality..."
TEST_SCRIPT=$(mktemp)
cat > "$TEST_SCRIPT" << 'EOF'
#!/usr/bin/env bash
REPO_USER="${REPO_USER:-}"
if [[ -z "$REPO_USER" ]]; then
    echo "TEST_PROMPT: Please enter username:"
    read -r REPO_USER
    echo "TEST_RESULT: Username is $REPO_USER"
else
    echo "TEST_RESULT: Username is $REPO_USER (from env)"
fi
EOF

chmod +x "$TEST_SCRIPT"

# Test with no environment variable (should prompt)
RESULT=$(echo "testuser" | "$TEST_SCRIPT" 2>&1)
if echo "$RESULT" | grep -q "TEST_PROMPT:" && echo "$RESULT" | grep -q "TEST_RESULT: Username is testuser"; then
    echo "✅ PASS: Prompting works correctly"
else
    echo "❌ FAIL: Prompting doesn't work correctly"
    echo "Result: $RESULT"
    rm -f "$TEST_SCRIPT"
    exit 1
fi

# Test with environment variable (should not prompt)
RESULT=$(REPO_USER=envuser "$TEST_SCRIPT" 2>&1)
if echo "$RESULT" | grep -q "TEST_RESULT: Username is envuser (from env)" && ! echo "$RESULT" | grep -q "TEST_PROMPT:"; then
    echo "✅ PASS: Environment variable bypasses prompting"
else
    echo "❌ FAIL: Environment variable doesn't bypass prompting"
    echo "Result: $RESULT"
    rm -f "$TEST_SCRIPT"
    exit 1
fi

rm -f "$TEST_SCRIPT"

# Test 4: Check that help shows prompting information
echo "Test 4: Checking bootstrap help for prompting information..."
if ./bootstrap.sh --help | grep -q "If not set, you will be prompted"; then
    echo "✅ PASS: Bootstrap help shows prompting information"
else
    echo "❌ FAIL: Bootstrap help missing prompting information"
    exit 1
fi

echo
echo "✅ Prompting functionality tests completed successfully!"
echo
echo "Users will now be prompted for repository information if not set:"
echo "  bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) setup_vscode.sh"
echo
echo "Or they can set environment variables to avoid prompting:"
echo "  REPO_USER=myuser REPO_NAME=myrepo bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) setup_vscode.sh"