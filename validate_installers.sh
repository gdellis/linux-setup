#!/bin/bash
#
# validate_installers.sh - Installer Metadata Validator
# Description: Validates that all installer scripts have required metadata and consistent structure
# Category: Development Tools
# Usage: ./validate_installers.sh
#

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
readonly INSTALLERS_DIR="$SCRIPT_DIR/installers"
readonly LIB_DIR="$SCRIPT_DIR/lib"

# Source shared libraries
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/dependencies.sh"

log_info "Starting installer validation..."

# Required metadata keys
readonly REQUIRED_HEADERS=("Description:" "Category:")
readonly REQUIRED_SHEBANG="#!/usr/bin/env bash"
readonly REQUIRED_STRICT_MODE="set -euo pipefail"

# Validation results
FAILED=0
PASSED=0
check_installer() {
    local installer="$1"
    local errors=0
    
    log_info "Checking $installer..."
    
    # Check shebang
    if ! head -1 "$installer" | grep -q "^$REQUIRED_SHEBANG$"; then
        log_error "  ✗ Missing or incorrect shebang: $REQUIRED_SHEBANG"
        errors=$((errors + 1))
    fi
    
    # Check for standard bash strict mode
    if ! grep -q "$REQUIRED_STRICT_MODE" "$installer"; then
        log_error "  ✗ Missing required strict mode: $REQUIRED_STRICT_MODE"
        errors=$((errors + 1))
    fi
    
    # Check required headers in first 20 lines
    for header in "${REQUIRED_HEADERS[@]}"; do
        if ! head -20 "$installer" | grep -q "^# $header"; then
            log_error "  ✗ Missing required header: $header"
            errors=$((errors + 1))
        fi
    done
    
    # Check for required libraries
    if ! grep -q "logging.sh" "$installer" || ! grep -q "dependencies.sh" "$installer"; then
        log_warn "  ⚠ Missing library references (logging.sh, dependencies.sh)"
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "  ✓ $installer passed all checks"
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi
}

# Find all installer scripts
mapfile -t INSTALLERS < <(find "$INSTALLERS_DIR" -maxdepth 1 -name "*.sh" -type f)

if [ ${#INSTALLERS[@]} -eq 0 ]; then
    log_warn "No installer scripts found"
    exit 1
fi

log_info "Found ${#INSTALLERS[@]} installer scripts to validate"
echo

# Validate each installer
for installer in "${INSTALLERS[@]}"; do
    check_installer "$installer"
done

# Print summary
echo
echo "================================================================"
echo "Validation Summary"
echo "================================================================"
echo "Total installers: ${#INSTALLERS[@]}"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "================================================================"

if [ $FAILED -gt 0 ]; then
    log_error "Validation failed with $FAILED installer(s)"
    exit 1
else
    log_success "All installers passed validation!"
    exit 0
fi