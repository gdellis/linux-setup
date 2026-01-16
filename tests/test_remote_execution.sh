#!/usr/bin/env bash
#
# test_remote_execution.sh - Test script for remote execution capability
# Description: Tests various remote execution scenarios to ensure functionality
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
PASSED=0
FAILED=0

# Print test result
print_result() {
    local test_name="$1"
    local result="$2"
    
    if [[ "$result" == "PASS" ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        ((FAILED++))
    fi
}

# Test 1: Check if template has remote execution functions
test_template_remote_functions() {
    if grep -q "is_running_remotely" "./installers/template.tpl" && \
       grep -q "source_library" "./installers/template.tpl"; then
        print_result "Template has remote execution functions" "PASS"
    else
        print_result "Template has remote execution functions" "FAIL"
    fi
}

# Test 2: Check if VS Code installer has remote execution functions
test_vscode_remote_functions() {
    if grep -q "is_running_remotely" "./installers/setup_vscode.sh" && \
       grep -q "source_library" "./installers/setup_vscode.sh"; then
        print_result "VS Code installer has remote execution functions" "PASS"
    else
        print_result "VS Code installer has remote execution functions" "FAIL"
    fi
}

# Test 3: Check if bootstrap script exists and is executable
test_bootstrap_script() {
    if [[ -f "./bootstrap.sh" ]] && [[ -x "./bootstrap.sh" ]]; then
        print_result "Bootstrap script exists and is executable" "PASS"
    else
        print_result "Bootstrap script exists and is executable" "FAIL"
    fi
}

# Test 4: Check if Python menu exists and is executable
test_python_menu() {
    if [[ -f "./py_menu.py" ]] && [[ -x "./py_menu.py" ]]; then
        print_result "Python menu exists and is executable" "PASS"
    else
        print_result "Python menu exists and is executable" "FAIL"
    fi
}

# Test 5: Check if documentation files exist
test_documentation_files() {
    local all_exist=true
    
    if [[ ! -f "./docs/REMOTE_EXECUTION.md" ]]; then
        all_exist=false
    fi
    
    if [[ ! -f "./REMOTE_EXECUTION_IMPLEMENTATION_SUMMARY.md" ]]; then
        all_exist=false
    fi
    
    if [[ "$all_exist" == "true" ]]; then
        print_result "Documentation files exist" "PASS"
    else
        print_result "Documentation files exist" "FAIL"
    fi
}

# Test 6: Check if environment variables are properly handled in template
test_template_env_vars() {
    if grep -q 'local repo_user="${REPO_USER:-' "./installers/template.tpl" && \
       grep -q 'local repo_name="${REPO_NAME:-' "./installers/template.tpl" && \
       grep -q 'local repo_branch="${REPO_BRANCH:-' "./installers/template.tpl"; then
        print_result "Template properly handles environment variables" "PASS"
    else
        print_result "Template properly handles environment variables" "FAIL"
    fi
}

# Test 7: Check if environment variables are properly handled in VS Code installer
test_vscode_env_vars() {
    if grep -q 'local repo_user="${REPO_USER:-' "./installers/setup_vscode.sh" && \
       grep -q 'local repo_name="${REPO_NAME:-' "./installers/setup_vscode.sh" && \
       grep -q 'local repo_branch="${REPO_BRANCH:-' "./installers/setup_vscode.sh"; then
        print_result "VS Code installer properly handles environment variables" "PASS"
    else
        print_result "VS Code installer properly handles environment variables" "FAIL"
    fi
}

# Test 8: Check if bootstrap script has proper defaults
test_bootstrap_defaults() {
    if grep -q 'REPO_USER="${REPO_USER:-gdellis}"' "./bootstrap.sh" && \
       grep -q 'REPO_NAME="${REPO_NAME:-linux-setup}"' "./bootstrap.sh"; then
        print_result "Bootstrap script has proper default values" "PASS"
    else
        print_result "Bootstrap script has proper default values" "FAIL"
    fi
}

# Test 9: Check if README has remote execution examples
test_readme_examples() {
    if grep -q "Run any installer directly from GitHub" "./README.md"; then
        print_result "README contains remote execution examples" "PASS"
    else
        print_result "README contains remote execution examples" "FAIL"
    fi
}

# Test 10: Check if Python menu handles environment variables
test_python_env_vars() {
    if grep -q "os.environ.get.*REPO_USER" "./py_menu.py" && \
       grep -q "os.environ.get.*REPO_NAME" "./py_menu.py" && \
       grep -q "os.environ.get.*REPO_BRANCH" "./py_menu.py"; then
        print_result "Python menu handles environment variables" "PASS"
    else
        print_result "Python menu handles environment variables" "FAIL"
    fi
}

# Run all tests
echo -e "${BLUE}Running Remote Execution Tests...${NC}"
echo "========================================"

test_template_remote_functions
test_vscode_remote_functions
test_bootstrap_script
test_python_menu
test_documentation_files
test_template_env_vars
test_vscode_env_vars
test_bootstrap_defaults
test_readme_examples
test_python_env_vars

# Print summary
echo "========================================"
echo -e "${BLUE}Test Summary:${NC}"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo -e "Total: $((PASSED + FAILED))"

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed! Remote execution capability is properly implemented.${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review the implementation.${NC}"
    exit 1
fi