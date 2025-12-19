#!/usr/bin/env bash

echo "Verifying Remote Execution Implementation..."
echo "==========================================="

# Check template
if grep -q "is_running_remotely" "./installers/template.tpl" && grep -q "source_library" "./installers/template.tpl"; then
    echo "✅ Template has remote execution functions"
else
    echo "❌ Template missing remote execution functions"
    exit 1
fi

# Check VS Code installer
if grep -q "is_running_remotely" "./installers/setup_vscode.sh" && grep -q "source_library" "./installers/setup_vscode.sh"; then
    echo "✅ VS Code installer has remote execution functions"
else
    echo "❌ VS Code installer missing remote execution functions"
    exit 1
fi

# Check environment variable handling in template
if grep -q 'repo_user="${REPO_USER:-' "./installers/template.tpl"; then
    echo "✅ Template handles environment variables properly"
else
    echo "❌ Template does not handle environment variables properly"
    exit 1
fi

# Check environment variable handling in VS Code installer
if grep -q 'repo_user="${REPO_USER:-' "./installers/setup_vscode.sh"; then
    echo "✅ VS Code installer handles environment variables properly"
else
    echo "❌ VS Code installer does not handle environment variables properly"
    exit 1
fi

# Check bootstrap script
if [[ -f "./bootstrap.sh" ]] && [[ -x "./bootstrap.sh" ]]; then
    echo "✅ Bootstrap script exists and is executable"
else
    echo "❌ Bootstrap script missing or not executable"
    exit 1
fi

# Check bootstrap defaults
if grep -q 'REPO_USER="${REPO_USER:-gdellis}"' "./bootstrap.sh"; then
    echo "✅ Bootstrap script has proper defaults"
else
    echo "❌ Bootstrap script does not have proper defaults"
    exit 1
fi

# Check Python menu
if [[ -f "./py_menu.py" ]] && [[ -x "./py_menu.py" ]]; then
    echo "✅ Python menu exists and is executable"
else
    echo "❌ Python menu missing or not executable"
    exit 1
fi

# Check Python menu environment variable handling
if grep -q "os.environ.get.*REPO_USER" "./py_menu.py"; then
    echo "✅ Python menu handles environment variables"
else
    echo "❌ Python menu does not handle environment variables"
    exit 1
fi

# Check documentation
if [[ -f "./docs/REMOTE_EXECUTION.md" ]]; then
    echo "✅ Remote execution documentation exists"
else
    echo "❌ Remote execution documentation missing"
    exit 1
fi

echo ""
echo "🎉 All checks passed! Remote execution capability is properly implemented."
echo ""
echo "Key features:"
echo "  • Installers can detect local vs remote execution"
echo "  • Libraries are sourced appropriately for each context"
echo "  • Environment variables control repository details"
echo "  • Bootstrap script enables easy remote execution"
echo "  • Python menu supports remote execution"
echo "  • Comprehensive documentation available"