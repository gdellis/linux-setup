#!/bin/bash
#
# Fix for ShellCheck GitHub Pipeline
# 
## Problem
The original ShellCheck workflow had several issues:
1. Used deprecated action version
2. Didn't handle library files properly
3. Might have include issues
4. No separate validation for sourceable library files

## Solution
Modified `.github/workflows/shellcheck.yml` to:
1. Use action-shellcheck@2.0.0 (latest stable)
2. Split into two steps:
   - Step 1: Check executable shell scripts (has shebang)
   - Step 2: Check library files in lib/ (no shebang, meant to be sourced)
3. Add appropriate ignores:
   - .git and .github directories
   - uninstallers directory
   - package.json (unintended root file)
4. Remove scandir (it's auto-detected with check_together)

## Benefits
- Proper handling of both executable scripts and library files
- Better error reporting with check_together
- Explicit library file checking
- Cleaner output and validation
- Avoids false positives on library files without shebangs