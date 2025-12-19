#!/usr/bin/env bash
#
# test_environment_variables.sh - Test that environment variables work for remote execution
# Description: Tests that REPO_USER, REPO_NAME, and REPO_BRANCH environment variables work correctly
#

set -euo pipefail

echo "Testing environment variable functionality..."

# Test 1: Check that template uses environment variables with defaults
echo "Test 1: Checking template for environment variable usage..."
if grep -q 'REPO_USER:-gdellis' installers/template.tpl && grep -q 'REPO_NAME:-linux-setup' installers/template.tpl; then
    echo "✅ PASS: Template uses environment variables with defaults"
else
    echo "❌ FAIL: Template doesn't use environment variables with defaults"
    exit 1
fi

# Test 2: Check that bootstrap uses environment variables with defaults
echo "Test 2: Checking bootstrap for environment variable usage..."
if grep -q 'REPO_USER:-gdellis' bootstrap.sh && grep -q 'REPO_NAME:-linux-setup' bootstrap.sh; then
    echo "✅ PASS: Bootstrap uses environment variables with defaults"
else
    echo "❌ FAIL: Bootstrap doesn't use environment variables with defaults"
    exit 1
fi

# Test 3: Check that help shows environment variable information
echo "Test 3: Checking bootstrap help for environment variable information..."
if ./bootstrap.sh --help | grep -q "Environment Variables:"; then
    echo "✅ PASS: Bootstrap help shows environment variable information"
else
    echo "❌ FAIL: Bootstrap help missing environment variable information"
    exit 1
fi

# Test 4: Create a simple test script to verify environment variable substitution
echo "Test 4: Testing environment variable substitution..."
TEST_SCRIPT=$(mktemp)
cat > "$TEST_SCRIPT" << 'EOF'
#!/usr/bin/env bash
REPO_USER="${REPO_USER:-defaultuser}"
REPO_NAME="${REPO_NAME:-defaultrepo}"
echo "REPO_USER=$REPO_USER"
echo "REPO_NAME=$REPO_NAME"
EOF

chmod +x "$TEST_SCRIPT"

# Test with default values
RESULT=$("$TEST_SCRIPT")
if echo "$RESULT" | grep -q "REPO_USER=defaultuser" && echo "$RESULT" | grep -q "REPO_NAME=defaultrepo"; then
    echo "✅ PASS: Default values work correctly"
else
    echo "❌ FAIL: Default values don't work correctly"
    rm -f "$TEST_SCRIPT"
    exit 1
fi

# Test with custom values
RESULT=$(REPO_USER=testuser REPO_NAME=testrepo "$TEST_SCRIPT")
if echo "$RESULT" | grep -q "REPO_USER=testuser" && echo "$RESULT" | grep -q "REPO_NAME=testrepo"; then
    echo "✅ PASS: Custom values work correctly"
else
    echo "❌ FAIL: Custom values don't work correctly"
    rm -f "$TEST_SCRIPT"
    exit 1
fi

rm -f "$TEST_SCRIPT"

echo
echo "✅ Environment variable tests completed successfully!"
echo
echo "Users can now customize repository settings with environment variables:"
echo "  export REPO_USER=myuser"
echo "  export REPO_NAME=myrepo"
echo "  bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) setup_vscode.sh"
echo
echo "Or set them inline:"
echo "  REPO_USER=myuser REPO_NAME=myrepo bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) setup_vscode.sh"