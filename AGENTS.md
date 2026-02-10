# Repository Overview

## Project Description
- **What this project does**: A comprehensive Linux development environment automation system that streamlines the setup of a productive development environment on Linux systems
- **Main purpose and goals**: 
  - Provide zero-friction setup experience with automatic dependency resolution
  - Offer beautiful interactive TUI for easy installer selection and execution
  - Automate installation of development tools, AI frameworks, and desktop applications
  - Maintain consistent, professional code quality with shared libraries and automated testing
- **Key technologies used**:
  - Bash scripting with strict mode (`set -euo pipefail`)
  - Python and Gum TUI framework for beautiful console interfaces
  - Nala package manager for improved APT experience
  - Bats testing framework for automated tests
  - GitHub Actions for CI/CD
  - Multiple TUI backends (Gum, Dialog, Whiptail, Bash)

## Architecture Overview
- **High-level architecture**: Modular, library-based architecture with automatic dependency resolution, interactive menu system, and pluggable installer scripts
- **Main components and their relationships**:
  - **Interactive Menu**: Multi-backend TUI (`menu.sh`) that auto-discovers installers and handles dependency checking
  - **Python TUI**: Enhanced TUI (`py_menu.py`) with categories and multi-select capabilities
  - **Shared Libraries**:
    - `lib/logging.sh`: Centralized logging with dual output (terminal + file), color support, and backup functionality
    - `lib/dependencies.sh`: Dependency management with auto-installation capabilities
  - **Installer Scripts**: Modular scripts in `installers/` directory for specific tools (AI/ML, Development, Security, System, Desktop apps)
  - **System Tools**: Dependency checker (`check_dependencies.sh`), installer generator (`new_installer.sh`)
  - **Testing & CI/CD**: Bats test suite and GitHub Actions for automated code quality checks
- **Data flow and system interactions**:
  1. User runs menu → Checks dependencies → Offers to install missing deps → Shows TUI menu
  2. User selects installer → Script sources shared libraries → Executes installation → Returns to menu
  3. All operations logged with colored terminal output and plain text file logging
  4. Configs backed up before modification with timestamped backups

## Directory Structure
```
linux-setup/
├── docs/              # Documentation files (ARCHITECTURE, CHANGELOG, DEPENDENCIES, TUI_GUIDE)
├── installers/        # Modular installer scripts for specific tools
├── lib/               # Shared libraries (logging, dependencies)
├── tests/             # Automated tests (Bats framework)
├── utilities/         # Utility scripts and configurations
├── bash/              # Bash configuration files (.bashrc, .bash_aliases)
├── menu.sh            # Main TUI menu system (Bash-based)
├── py_menu.py         # Enhanced Python TUI with categories
├── setup_bash.sh      # Bash environment setup
└── check_dependencies.sh # Dependency checking script
```

### Important directories and their purposes:
- `installers/`: Contains all tool-specific installation scripts with consistent structure
- `lib/`: Shared functionality (logging, dependency management) used across all scripts
- `docs/`: Comprehensive documentation including architecture, dependencies, and usage guides
- `tests/`: Automated test suite for verifying core library functionality
- `bash/`: Configuration files for enhanced bash environment

### Key files and configuration:
- **Entry Points**: `menu.sh` (primary), `py_menu.py` (enhanced), `check_dependencies.sh` (dependency management)
- **Shared Libraries**: `lib/logging.sh`, `lib/dependencies.sh` for consistent functionality
- **Installer Template**: `installers/template.tpl` and `installers/new_installer.sh` for creating new installers
- **Configuration**: `.shellcheckrc` (linting), `.gitignore` (exclusions), `.vscode/` (IDE configuration)

## Development Workflow
- **How to build/run the project**:
  ```bash
  # Interactive mode (recommended for first-time users)
  ./menu.sh

  # Enhanced Python TUI with categories
  ./py_menu.py

  # Check/install dependencies manually
  ./check_dependencies.sh --install

  # Run specific installer directly
  ./installers/setup_vscode.sh

  # Non-interactive mode for CI/CD
  ./installers/setup_fabric.sh --yes

  # Run tests
  bats tests/

  # Check code quality
  shellcheck installers/*.sh lib/*.sh menu.sh
  ```

- **Testing approach**:
  - Unit tests: Bats framework tests for core libraries (logging, dependencies)
  - Integration tests: Manual testing of installer scripts in isolated environments
  - CI/CD: GitHub Actions runs ShellCheck on all scripts for every push/PR

- **Development environment setup**:
  ```bash
  # Install development dependencies
  ./check_dependencies.sh --install

  # Install testing framework
  sudo apt-get install bats

  # Install code quality tools
  sudo apt-get install shellcheck
  ```

- **Lint and format commands**:
  - ShellCheck (enforced via CI/CD): `shellcheck installers/*.sh lib/*.sh menu.sh check_dependencies.sh`
  - Bash strict mode: All scripts use `set -euo pipefail`
  - Code style: 4-space indentation, readonly for constants, local for variables, comprehensive error handling

## GitHub Pull Request Workflow

### Feature Development Process

1. **Create feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes and commit**:
   ```bash
   git add .
   git commit -m "Descriptive commit message"
   git push origin feature/your-feature-name
   ```

3. **Create pull request**:
   ```bash
   gh pr create --title "Your feature description" --body "Detailed description of changes"
   ```

### Pre-PR Requirements

Before submitting a PR, ensure:
- ✓ All installer scripts pass validation: `./validate_installers.sh`
- ✓ ShellCheck passes locally: `shellcheck --severity=error installers/*.sh lib/*.sh`
- ✓ Commit messages follow conventional format
- ✓ Branch is up-to-date with main: `git fetch origin main && git rebase origin/main`

### PR Structure

**Title**: Clear, concise description (max 50 chars)
**Body**: Detailed description including:
- What problem does this solve?
- What changes were made?
- What testing was performed?
- Any breaking changes or migration notes?

**Template for PR descriptions**:
```
## Summary of Changes

Brief description of what this PR accomplishes.

## Problem Statement

Explanation of the issue or enhancement being addressed.

## Solution Details

Detailed explanation of the implementation:
- Which files were modified
- What functions or logic were added/changed
- Why this approach was chosen

## Testing Performed

Description of how the changes were tested:
- Manual testing steps
- Automated tests run
- Validation script results
- ShellCheck compliance

## Affected Components

List of project components that are affected by these changes:
- Specific installer scripts
- Shared libraries
- Configuration files
- Documentation files

## Validation Results

Results from validation checks:
- All installer scripts pass validation: `./validate_installers.sh`
- ShellCheck passes locally: `shellcheck --severity=error installers/*.sh lib/*.sh`
- Any other relevant test results

## Migration Notes (if applicable)

Instructions for users/contributors about any breaking changes or steps needed to upgrade.
```

**Example**:
```
Enhanced dependency installation in Fabric AI setup

## Summary of Changes

Updated setup_fabric.sh to automatically install missing dependencies instead of just checking for them.

## Problem Statement

The Fabric AI installer was checking for dependencies but not installing them automatically, requiring users to manually install missing packages before running the script.

## Solution Details

Modified the check_dependencies function in setup_fabric.sh to use ensure_command for each dependency:
- op (1password-cli)
- ffmpeg
- yt-dlp
- curl

This leverages the shared dependencies library to automatically install missing packages.

## Testing Performed

- Verified the script installs dependencies correctly when missing
- Confirmed existing installations are detected properly
- Validated installer still functions correctly after dependency installation
- Ran full validation suite: `./validate_installers.sh`
- Passed ShellCheck: `shellcheck installers/setup_fabric.sh`

## Affected Components

- installers/setup_fabric.sh

## Validation Results

All 20 installer scripts pass validation:
- setup_fabric.sh: ✓ Pass
- ShellCheck: ✓ Pass

## Migration Notes

No breaking changes. Existing installations will continue to work as before.
```

### Code Review Process

1. **Automated checks must pass**:
   - GitHub Actions ShellCheck workflow
   - Validation script (all 16 installers)
   - Bats tests (if applicable)

2. **Manual review checklist**:
   - ✓ Follows project coding standards (4-space indentation, strict mode)
   - ✓ Includes proper metadata (Description, Category, Usage)
   - ✓ Uses shared libraries where appropriate (logging, dependencies)
   - ✓ Backward compatibility maintained
   - ✓ Documentation updated (if applicable)
   - ✓ No secrets or credentials committed

3. **Review guidelines**:
   - Check for security vulnerabilities
   - Verify error handling and edge cases
   - Ensure consistent style with existing code
   - Test locally if possible
   - Review commits (not just files changed)

### Reviewer Guidelines

**For reviewers:**
- Be constructive and specific in feedback
- Suggest alternatives rather than just pointing out issues
- Approve once all concerns are addressed
- Use GitHub's "Request changes" for blocking issues

**For authors:**
- Respond to all feedback
- Make requested changes or explain why not
- Don't take feedback personally
- Squash commits if requested

### Merging Process

1. **All checks must pass**:
   - GitHub Actions workflows (ShellCheck, etc.)
   - Required status checks (if configured)
   - Code review approval

2. **Merge strategy**:
   ```bash
   # Squash and merge (preferred for clean history)
   gh pr merge <PR_NUMBER> --squash --delete-branch
   
   # Or merge commit
   gh pr merge <PR_NUMBER> --merge --delete-branch
   ```

3. **After merge**:
   - Delete feature branch locally: `git branch -d feature/your-feature`
   - Update main: `git checkout main && git pull origin main`

### Best Practices

**For authors:**
- Keep PRs focused (one feature/fix per PR)
- Make commits atomic and descriptive
- Test thoroughly before requesting review
- Respond promptly to feedback
- Don't force push after review starts

**For reviewers:**
- Review within 24-48 hours if possible
- Be clear about what needs fixing vs suggestions
- Approve when ready, don't just comment
- Use GitHub's review features (Approve/Request changes)

### Continuous Integration

The project uses GitHub Actions for CI/CD:
- **ShellCheck Analysis**: Runs on all pushes to main/develop and all PRs
- **Branch protection**: Main branch requires passing checks
- **Automated testing**: Validation and ShellCheck must pass

### Template Files

When creating new features, use templates:
- Installer template: `installers/template.tpl`
- Use `installers/new_installer.sh` to generate new installers
- Follow existing patterns in similar installers