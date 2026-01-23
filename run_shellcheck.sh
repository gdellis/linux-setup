#!/usr/bin/env bash
#
# run_shellcheck.sh - Run shellcheck on core files
#

echo "Running shellcheck on core files..."

# Check core library files
for file in lib/logging.sh lib/dependencies.sh check_dependencies.sh installers/setup_nala.sh; do
    echo
    echo "Checking $file..."
    if shellcheck "$file"; then
        echo "✓ $file passed shellcheck"
    else
        echo "✗ $file has shellcheck issues"
    fi
done

echo
echo "Shellcheck analysis complete."