#!/usr/bin/env bash
#
# test_enhanced_branch_detection.sh - Test script for enhanced branch detection
# Description: Tests the automatic branch detection functionality in installer scripts
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

# Test 1: Check if template has enhanced branch detection
test_template_enhanced_detection() {
    if grep -q "script_url=" "./installers/template.tpl" && \
       grep -q "url_branch=" "./installers/template.tpl" && \
       grep -q "Extract branch from URL" "./installers/template.tpl"; then
        print_result "Template has enhanced branch detection" "PASS"
    else
        print_result "Template has enhanced branch detection" "FAIL"
    fi
}

# Test 2: Check if VS Code installer has enhanced branch detection
test_vscode_enhanced_detection() {
    if grep -q "script_url=" "./installers/setup_vscode.sh" && \
       grep -q "url_branch=" "./installers/setup_vscode.sh" && \
       grep -q "Extract branch from URL" "./installers/setup_vscode.sh"; then
        print_result "VS Code installer has enhanced branch detection" "PASS"
    else
        print_result "VS Code installer has enhanced branch detection" "FAIL"
    fi
}

# Test 3: Check if Neovim installer has enhanced branch detection
test_neovim_enhanced_detection() {
    if grep -q "script_url=" "./installers/setup_neovim.sh" && \
       grep -q "url_branch=" "./installers/setup_neovim.sh" && \
       grep -q "Extract branch from URL" "./installers/setup_neovim.sh"; then
        print_result "Neovim installer has enhanced branch detection" "PASS"
    else
        print_result "Neovim installer has enhanced branch detection" "FAIL"
    fi
}

# Test 4: Check if Gum installer has enhanced branch detection
test_gum_enhanced_detection() {
    if grep -q "script_url=" "./installers/setup_gum.sh" && \
       grep -q "url_branch=" "./installers/setup_gum.sh" && \
       grep -q "Extract branch from URL" "./installers/setup_gum.sh"; then
        print_result "Gum installer has enhanced branch detection" "PASS"
    else
        print_result "Gum installer has enhanced branch detection" "FAIL"
    fi
}

# Test 5: Check if Fabric installer has enhanced branch detection
test_fabric_enhanced_detection() {
    if grep -q "script_url=" "./installers/setup_fabric.sh" && \
       grep -q "url_branch=" "./installers/setup_fabric.sh" && \
       grep -q "Extract branch from URL" "./installers/setup_fabric.sh"; then
        print_result "Fabric installer has enhanced branch detection" "PASS"
    else
        print_result "Fabric installer has enhanced branch detection" "FAIL"
    fi
}

# Test 6: Check if documentation mentions automatic branch detection
test_documentation_mentions_branch_detection() {
    if grep -q "Automatically detects branch" "./installers/template.tpl" && \
       grep -q "Automatically detects branch" "./installers/setup_vscode.sh" && \
       grep -q "Automatically detects branch" "./installers/setup_neovim.sh" && \
       grep -q "Automatically detects branch" "./installers/setup_gum.sh" && \
       grep -q "Automatically detects branch" "./installers/setup_fabric.sh"; then
        print_result "All installers documentation mention automatic branch detection" "PASS"
    else
        print_result "All installers documentation mention automatic branch detection" "FAIL"
    fi
}

# Test 7: Check if branch detection code references correct script names
test_correct_script_name_references() {
    if grep -q "template.tpl" "./installers/template.tpl" && \
       grep -q "url_branch != \"template.tpl\"" "./installers/template.tpl" && \
       grep -q "setup_vscode.sh" "./installers/setup_vscode.sh" && \
       grep -q "url_branch != \"setup_vscode.sh\"" "./installers/setup_vscode.sh" && \
       grep -q "setup_neovim.sh" "./installers/setup_neovim.sh" && \
       grep -q "url_branch != \"setup_neovim.sh\"" "./installers/setup_neovim.sh" && \
       grep -q "setup_gum.sh" "./installers/setup_gum.sh" && \
       grep -q "url_branch != \"setup_gum.sh\"" "./installers/setup_gum.sh" && \
       grep -q "setup_fabric.sh" "./installers/setup_fabric.sh" && \
       grep -q "url_branch != \"setup_fabric.sh\"" "./installers/setup_fabric.sh"; then
        print_result "All installers have correct script name references" "PASS"
    else
        print_result "All installers have correct script name references" "FAIL"
    fi
}

# Test 8: Check if all installers have proper error handling
test_proper_error_handling() {
    if grep -q "Tried URL:" "./installers/template.tpl" && \
       grep -q "Tried URL:" "./installers/setup_vscode.sh" && \
       grep -q "Tried URL:" "./installers/setup_neovim.sh" && \
       grep -q "Tried URL:" "./installers/setup_gum.sh" && \
       grep -q "Tried URL:" "./installers/setup_fabric.sh"; then
        print_result "All installers have proper error handling with URL information" "PASS"
    else
        print_result "All installers have proper error handling with URL information" "FAIL"
    fi
}

# Run all tests
echo -e "${BLUE}Running Enhanced Branch Detection Tests...${NC}"
echo "========================================"

test_template_enhanced_detection
test_vscode_enhanced_detection
test_neovim_enhanced_detection
test_gum_enhanced_detection
test_fabric_enhanced_detection
test_documentation_mentions_branch_detection
test_correct_script_name_references
test_proper_error_handling

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