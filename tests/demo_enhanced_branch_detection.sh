#!/usr/bin/env bash
#
# demo_enhanced_branch_detection.sh - Demonstration of enhanced branch detection
# Description: Shows how the enhanced branch detection works in practice
#

echo "Enhanced Branch Detection Demonstration"
echo "======================================="
echo

echo "1. Template Script Branch Detection:"
echo "   The template now includes enhanced branch detection code:"
echo
echo "   # For remote execution, try to detect branch from script URL if possible"
echo "   # This is an enhancement to handle cases where the script is run from a non-default branch"
echo "   local script_url"
echo "   script_url=\$(curl -fsSL -w \"%{url_effective}\\n\" -o /dev/null \"https://raw.githubusercontent.com/\$repo_user/\$repo_name/\$repo_branch/installers/template.tpl\" 2>/dev/null || echo \"\")"
echo
echo "   if [[ -n \"\$script_url\" ]] && [[ \"\$script_url\" == *\"raw.githubusercontent.com\"* ]]; then"
echo "       # Extract branch from URL if possible"
echo "       local url_branch"
echo "       url_branch=\$(echo \"\$script_url\" | sed -E \"s@.*raw.githubusercontent.com/[^/]+/[^/]+/([^/]+)/.*@\\1@\")"
echo "       if [[ -n \"\$url_branch\" ]] && [[ \"\$url_branch\" != \"template.tpl\" ]]; then"
echo "           repo_branch=\"\$url_branch\""
echo "       fi"
echo "   fi"
echo

echo "2. How It Works:"
echo "   When you run a script remotely from a specific branch:"
echo "   bash <(curl -fsSL https://raw.githubusercontent.com/user/repo/feature-branch/installers/setup_script.sh)"
echo
echo "   The script:"
echo "   - Detects it's running remotely (temporary directory)"
echo "   - Attempts to access the template script on the same branch"
echo "   - If successful, extracts the branch name from the returned URL"
echo "   - Uses that branch to source library files"
echo "   - This ensures library files are sourced from the correct branch"
echo

echo "3. Benefits:"
echo "   - No need to manually set REPO_BRANCH for feature branches"
echo "   - Scripts automatically adapt to the branch they're running from"
echo "   - Reduced configuration overhead for users"
echo "   - Improved reliability when working with feature branches"
echo

echo "4. Example Usage:"
echo "   # This will automatically detect and use the 'feature-branch' branch"
echo "   bash <(curl -fsSL https://raw.githubusercontent.com/user/repo/feature-branch/installers/setup_vscode.sh)"
echo
echo "   # Libraries will be sourced from the same branch:"
echo "   https://raw.githubusercontent.com/user/repo/feature-branch/lib/logging.sh"
echo "   https://raw.githubusercontent.com/user/repo/feature-branch/lib/dependencies.sh"
echo

echo "5. Fallback Behavior:"
echo "   If branch detection fails, scripts fall back to environment variables:"
echo "   - REPO_BRANCH environment variable (if set)"
echo "   - Default branch (main)"
echo

echo "This enhancement solves the issue where scripts running from feature branches"
echo "would incorrectly try to source libraries from the main branch, causing errors."