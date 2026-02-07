#!/usr/bin/env bash
#
# lib/test_shellcheck.sh - Test ShellCheck on all shell scripts
# Description: Local testing of ShellCheck before committing
# Usage: ./lib/test_shellcheck.sh
#

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
readonly ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"

# List all shell scripts (excluding git directory)
find_shell_scripts() {
    # Shell scripts with shebangs (executable scripts)
    find "$ROOT_DIR" -type f -name "*.sh" \
        ! -path "*/.git/*" \
        ! -path "*/.github/*" \
        -exec grep -l "^#!/" {} \;
}

# Library files meant to be sourced (no shebang, but shell script content)
find_library_files() {
    find "$ROOT_DIR"/lib -type f \
        ! -path "*/.git/*" \
        ! -path "*/.github/*" \
        ! -path "*/uninstallers/*" \
        -exec grep -l "^#.*\.sh\|^#.*Library" {} \;
}

echo "Testing ShellCheck locally..."
echo

# Track results
PASS=0
FAIL=0
WARN=0
TOTAL=0

# Run ShellCheck on executable scripts and library files
ALL_FILES=()

# Add shell scripts
while IFS= read -r file; do
    ALL_FILES+=("$file")
done < <(find_shell_scripts)

# Add library files
while IFS= read -r file; do
    ALL_FILES+=("$file")
done < <(find_library_files)

# Add specific files to check
if [[ -f "$ROOT_DIR/validate_installers.sh" ]]; then
    ALL_FILES+=("$ROOT_DIR/validate_installers.sh")
fi

# Run ShellCheck on all files
for file in "${ALL_FILES[@]}"; do
    TOTAL=$((TOTAL + 1))
    echo "Checking: $file"
    
    if shellcheck --severity=warning --external-sources "$file" 2>&1; then
        PASS=$((PASS + 1))
        echo "  ✓ PASS"
    else
        # Check if it was a warning or error
        if $? -eq 1; then
            WARN=$((WARN + 1))
            echo "  ⚠ WARNING (non-fatal)"
        else
            FAIL=$((FAIL + 1))
            echo "  ✗ ERROR"
        fi
    fi
    echo
done

echo
echo "===================================================================="
echo "ShellCheck Summary"
echo "===================================================================="
echo "Total files checked: $TOTAL"
echo "  ✓ Passed: $PASS"
echo "  ⚠ Warnings: $WARN"
echo "  ✗ Errors: $FAIL"
echo "===================================================================="
echo

if [[ $FAIL -gt 0 ]]; then
    echo "ShellCheck failed with $FAIL error(s)"
    exit 1
else
    echo "ShellCheck completed successfully!"
    if [[ $WARN -gt 0 ]]; then
        echo "Note: There were $WARN warning(s) (non-fatal)"
    fi
    exit 0
fi