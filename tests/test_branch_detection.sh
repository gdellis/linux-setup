#!/usr/bin/env bash
#
# test_branch_detection.sh - Test script for enhanced branch detection
# Description: Tests the automatic branch detection functionality
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

# Test 1: Check if template has branch detection code
test_template_branch_detection() {
    if grep -q "script_url=" "./installers/template.tpl" && \
       grep -q "url_branch=" "./installers/template.tpl" && \
       grep -q "Extract branch from URL" "./installers/template.tpl"; then
        print_result "Template has branch detection code" "PASS"
    else
        print_result "Template has branch detection code" "FAIL"
    fi
}

# Test 2: Check if VS Code installer has branch detection code
test_vscode_branch_detection() {
    if grep -q "script_url=" "./installers/setup_vscode.sh" && \
       grep -q "url_branch=" "./installers/setup_vscode.sh" && \
       grep -q "Extract branch from URL" "./installers/setup_vscode.sh"; then
        print_result "VS Code installer has branch detection code" "PASS"
    else
        print_result "VS Code installer has branch detection code" "FAIL"
    fi
}

# Test 3: Check if template documentation mentions automatic branch detection
test_template_doc_branch_detection() {
    if grep -q "Automatically detects branch" "./installers/template.tpl"; then
        print_result "Template documentation mentions automatic branch detection" "PASS"
    else
        print_result "Template documentation mentions automatic branch detection" "FAIL"
    fi
}

# Test 4: Check if VS Code installer documentation mentions automatic branch detection
test_vscode_doc_branch_detection() {
    if grep -q "Automatically detects branch" "./installers/setup_vscode.sh"; then
        print_result "VS Code installer documentation mentions automatic branch detection" "PASS"
    else
        print_result "VS Code installer documentation mentions automatic branch detection" "FAIL"
    fi
}

# Test 5: Check if branch detection code is correct in template
test_template_branch_detection_correctness() {
    # Check that the branch detection code references the correct script name
    if grep -q "template.tpl" "./installers/template.tpl" && \
       grep -q "url_branch != \"template.tpl\"" "./installers/template.tpl"; then
        print_result "Template branch detection code is correct" "PASS"
    else
        print_result "Template branch detection code is correct" "FAIL"
    fi
}

# Test 6: Check if branch detection code is correct in VS Code installer
test_vscode_branch_detection_correctness() {
    # Check that the branch detection code references the correct script name
    if grep -q "setup_vscode.sh" "./installers/setup_vscode.sh" && \
       grep -q "url_branch != \"setup_vscode.sh\"" "./installers/setup_vscode.sh"; then
        print_result "VS Code installer branch detection code is correct" "PASS"
    else
        print_result "VS Code installer branch detection code is correct" "FAIL"
    fi
}

# Run all tests
echo -e "${BLUE}Running Branch Detection Tests...${NC}"
echo "========================================"

test_template_branch_detection
test_vscode_branch_detection
test_template_doc_branch_detection
test_vscode_doc_branch_detection
test_template_branch_detection_correctness
test_vscode_branch_detection_correctness

# Print summary
echo "========================================"
echo -e "${BLUE}Test Summary:${NC}"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo -e "Total: $((PASSED + FAILED))"

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed! Enhanced branch detection is properly implemented.${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review the implementation.${NC}"
    exit 1
fi