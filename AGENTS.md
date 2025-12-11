# Repository Overview

## Project Description
- **What this project does**: A comprehensive, professional Linux setup automation system with interactive TUI menu, automatic dependency management, and modular installer scripts for development tools and applications
- **Main purpose and goals**:
  - Provide zero-friction setup experience with automatic dependency resolution
  - Offer beautiful interactive TUI for easy installer selection and execution
  - Automate installation of development tools, AI frameworks, and desktop applications
  - Maintain consistent, professional code quality with shared libraries and automated testing
  - Enable both interactive and automated (CI/CD) deployment scenarios
- **Key technologies used**:
  - Bash scripting with strict mode (`set -euo pipefail`)
  - Gum TUI framework for beautiful console interfaces
  - Nala package manager for improved APT experience
  - Bats testing framework for automated tests
  - GitHub Actions for CI/CD
  - Multiple TUI backends (Gum, Dialog, Whiptail, Bash)

## Architecture Overview
- **High-level architecture**: Modular, library-based architecture with automatic dependency resolution, interactive menu system, and pluggable installer scripts
- **Main components and their relationships**:
  - **Interactive Menu** (`menu.sh`): Multi-backend TUI that auto-discovers installers and handles dependency checking
  - **Shared Libraries**:
    - `lib/logging.sh`: Centralized logging with dual output (terminal + file), color support, and backup functionality
    - `lib/dependencies.sh`: Dependency management with auto-installation capabilities
  - **Installer Scripts** (`installers/`):
    - Core tools: `setup_nala.sh` (package manager), `setup_gum.sh` (TUI tool)
    - AI/ML: `setup_ollama.sh`, `setup_fabric.sh`
    - Desktop apps: `setup_orcaslicer.sh`, `setup_protonmail.sh`, `setup_protonvpn.sh`, `setup_syncthing.sh`
  - **System Tools**:
    - `check_dependencies.sh`: Standalone dependency checker/installer
    - `new_installer.sh`: Template-based installer generator
    - `demo_tui.sh`: Interactive TUI demonstration
  - **Testing & CI/CD**:
    - `tests/`: Bats test suite for core libraries
    - `.github/workflows/shellcheck.yml`: Automated code quality checks
- **Data flow and system interactions**:
  1. User runs `menu.sh` → Checks dependencies → Offers to install missing deps → Shows TUI menu
  2. User selects installer → Script sources shared libraries → Executes installation → Returns to menu
  3. All operations logged with colored terminal output and plain text file logging
  4. Configs backed up before modification with timestamped backups
  5. Package downloads verified with SHA256 checksums where available

## Directory Structure
- **Important directories and their purposes**:
  - `installers/`: All setup scripts for various applications and tools
  - `lib/`: Shared libraries (logging, dependency management)
  - `bash/`: Bash configuration files (`.bashrc`, `.bash_aliases`)
  - `tests/`: Automated test suite using Bats framework
  - `.github/workflows/`: CI/CD configuration for automated testing
  - `downloads/`: Created at runtime by installers for package downloads (gitignored)
  - `logs/`: Created at runtime for installer logs (gitignored)
  - `backups/`: Stores timestamped backups of modified files (gitignored)
- **Key files and configuration**:
  - **Entry Points**:
    - `menu.sh`: Interactive TUI menu (primary entry point for users)
    - `check_dependencies.sh`: System dependency checker
    - `setup_bash.sh`: Bash environment configuration
  - **Shared Libraries**:
    - `lib/logging.sh`: Logging functions, backup functionality, error handling
    - `lib/dependencies.sh`: 15+ dependency management functions
  - **Installer Template**:
    - `installers/template.tpl`: Template for creating new installers
    - `installers/new_installer.sh`: Generator script for new installers
  - **Documentation**:
    - `README.md`: Project overview and quick start
    - `TUI_GUIDE.md`: Complete TUI menu documentation
    - `DEPENDENCIES.md`: Dependency management guide
    - `CHANGELOG.md`: Version history and changes
    - `AGENTS.md`: This file - architecture and development guide
  - **Configuration**:
    - `.shellcheckrc`: ShellCheck linter configuration
    - `.gitignore`: Comprehensive exclusions for logs, backups, temp files
- **Entry points and main modules**:
  - **Primary**: `menu.sh` - Interactive menu with automatic dependency management
  - **Alternative**: Direct execution of installers (e.g., `./installers/setup_ollama.sh`)
  - **Utility**: `check_dependencies.sh --install` - Automated dependency installation
  - **Testing**: `bats tests/` - Run automated test suite

## Development Workflow
- **How to build/run the project**:
  ```bash
  # Interactive mode (recommended for first-time users)
  ./menu.sh

  # Check/install dependencies manually
  ./check_dependencies.sh --install

  # Run specific installer directly
  ./installers/setup_ollama.sh

  # Non-interactive mode for CI/CD
  ./installers/setup_fabric.sh --yes

  # Run tests
  bats tests/

  # Check code quality
  shellcheck installers/*.sh lib/*.sh menu.sh
  ```
- **Testing approach**:
  - **Unit tests**: Bats framework tests for `lib/logging.sh` covering all logging functions, backup functionality, and error handling
  - **Integration tests**: Manual testing of installer scripts in isolated environments
  - **CI/CD**: GitHub Actions runs ShellCheck on all scripts for every push/PR
  - **Dependency testing**: `check_dependencies.sh` verifies system state
  - **TUI testing**: `demo_tui.sh` provides interactive testing of TUI components
- **Development environment setup**:
  - **Minimum requirements**:
    - Bash 4.0+
    - sudo access
    - curl or wget
    - Ubuntu 20.04+ or Debian 11+
  - **Recommended setup**:
    ```bash
    # Install development dependencies
    ./check_dependencies.sh --install

    # Install testing framework
    sudo apt-get install bats

    # Install TUI tools
    ./installers/setup_gum.sh

    # Install code quality tools
    sudo apt-get install shellcheck
    ```
  - **IDE configuration**: `.vscode/` included with recommended extensions
- **Lint and format commands**:
  - **ShellCheck** (enforced via CI/CD):
    ```bash
    # Check all scripts
    shellcheck installers/*.sh lib/*.sh menu.sh check_dependencies.sh

    # Check specific script
    shellcheck installers/setup_ollama.sh
    ```
  - **Bash strict mode**: All scripts use `set -euo pipefail`
  - **Code style**:
    - Consistent 4-space indentation
    - Readonly for constants
    - Local for function variables
    - Functions use `return` not `exit` (except main)
    - Comprehensive error handling with traps
    - Descriptive function and variable names

## Key Design Patterns

### 1. Shared Library Pattern
All scripts source common libraries:
```bash
source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../lib/dependencies.sh"
```
**Benefits**: DRY principle, consistent behavior, ~438 lines of code eliminated

### 2. Template-Based Generation
New installers created from `template.tpl`:
```bash
./installers/new_installer.sh setup_newapp.sh
```
**Benefits**: Consistency, best practices baked in, faster development

### 3. Multi-Backend TUI
Menu auto-detects best available TUI backend:
- Gum (best) → Dialog → Whiptail → Bash (fallback)

**Benefits**: Always works, graceful degradation, best UX when available

### 4. Automatic Dependency Resolution
Menu checks dependencies on startup and offers installation:
```bash
check_system_dependencies() {
    # Check for curl, wget, nala
    # Offer to install if missing
    # Install with user consent
}
```
**Benefits**: Zero-friction setup, consistent environment

### 5. Dual Output Logging
All logs go to both terminal (colored) and file (plain):
```bash
log() {
    # Terminal with colors
    echo -e "$colored_msg"
    # File without colors
    echo "$plain_msg" >> "$LOG_FILE"
}
```
**Benefits**: Interactive feedback + persistent troubleshooting logs

### 6. Backup Before Modify
Config files backed up with timestamps before changes:
```bash
backup_file "$config_file"  # Creates .backup.YYYYMMDD_HHMMSS
```
**Benefits**: Safety, reversibility, compliance

## Code Quality Standards

### Enforced via CI/CD
- ✅ ShellCheck on all shell scripts
- ✅ Automatic checks on push/PR
- ✅ Blocks merge if checks fail

### Best Practices Applied
- ✅ Strict mode (`set -euo pipefail`) in all scripts
- ✅ Readonly for all constants
- ✅ Local for function variables
- ✅ Error handling with traps
- ✅ Comprehensive logging
- ✅ Input validation
- ✅ Checksum verification for downloads
- ✅ Graceful error messages
- ✅ Return codes over exit in functions
- ✅ Documented functions with headers

### Documentation Requirements
- ✅ File headers with description and usage
- ✅ Inline comments for complex logic
- ✅ User-facing guides (README, TUI_GUIDE, DEPENDENCIES)
- ✅ Developer documentation (AGENTS.md, CHANGELOG)
- ✅ API documentation in library files

## Recent Major Improvements (2024)

### Automatic Dependency Management
- Created `lib/dependencies.sh` with 15+ reusable functions
- Integrated automatic checking into `menu.sh`
- Added `check_dependencies.sh` standalone tool
- Auto-installation of curl, wget, nala with user consent

### Interactive TUI Menu
- Multi-backend support (Gum, Dialog, Whiptail, Bash)
- Auto-discovers all installer scripts
- Integrated dependency checking
- Beautiful styled interface with Gum

### Code Quality & Testing
- Refactored all installers to use shared libraries (~438 lines removed)
- Added Bats test framework with comprehensive tests
- Implemented GitHub Actions CI/CD with ShellCheck
- Enforced readonly for constants across all scripts

### User Experience
- Non-interactive mode for automation (`--yes` flag)
- Backup functionality before config changes
- Checksum verification for secure downloads
- Comprehensive error handling and logging

### Documentation
- Created TUI_GUIDE.md (70+ lines)
- Created DEPENDENCIES.md (650+ lines)
- Updated CHANGELOG.md with all changes
- Added inline documentation to all functions

## Extension Points

### Adding New Installers
1. Use the generator:
   ```bash
   ./installers/new_installer.sh setup_newapp.sh
   ```
2. Edit the generated script:
   - Set download URLs and checksums
   - Implement installation logic
   - Test thoroughly
3. Script auto-appears in menu

### Adding Dependencies
1. Update `lib/dependencies.sh` if needed
2. Add to appropriate category in `check_dependencies.sh`
3. Document in `DEPENDENCIES.md`

### Adding TUI Backend
1. Add detection in `detect_tui_backend()`
2. Implement `show_menu_BACKEND()` function
3. Update TUI_GUIDE.md

### Adding Tests
1. Create test file in `tests/`
2. Follow Bats syntax
3. Run with `bats tests/`

## Troubleshooting Guide

### For Users
- **Dependencies missing**: Run `./check_dependencies.sh --install`
- **TUI not working**: Install gum with `./installers/setup_gum.sh`
- **Installer fails**: Check `~/logs/<app>/` for detailed logs
- **Need rollback**: Restore from `backups/` with timestamp

### For Developers
- **ShellCheck errors**: Run `shellcheck <script>` for details
- **Tests failing**: Run `bats tests/ -t` for tap output
- **Library changes**: Update tests and all scripts using the library
- **Menu not finding script**: Ensure script follows `setup_*.sh` naming

## Contributing Guidelines

### Code Standards
1. Use the installer template for new scripts
2. Source shared libraries (logging, dependencies)
3. Follow bash strict mode (`set -euo pipefail`)
4. Add file headers with description and usage
5. Use readonly for constants, local for variables
6. Implement comprehensive error handling
7. Add tests for new functionality
8. Update CHANGELOG.md
9. Run shellcheck before committing

### Pull Request Process
1. Create feature branch
2. Make changes following standards
3. Run tests: `bats tests/`
4. Run shellcheck: `shellcheck <changed files>`
5. Update documentation if needed
6. Update CHANGELOG.md
7. Submit PR with clear description
8. CI checks must pass

## Performance Characteristics

### Menu Startup
- Dependency check: < 1 second
- Script discovery: < 1 second (even with 20+ installers)
- TUI render: Instant with Gum, < 1 second with Dialog

### Installer Execution
- Varies by installer (30 seconds - 10 minutes)
- Parallel downloads where supported (nala)
- Progress feedback throughout

### Resource Usage
- Minimal: Shell scripts use negligible CPU/RAM
- Storage: ~10MB for project + variable for downloads/logs
- Network: As needed for package downloads

## Security Considerations

### Download Verification
- SHA256 checksums verified where available
- Warnings when checksums not provided
- Downloads from official sources only

### Permission Model
- Scripts never run as root directly
- Use sudo only when necessary
- Prompt before privilege escalation
- Clear logging of all sudo operations

### Secrets Management
- No hardcoded secrets in scripts
- `.env` files in `.gitignore`
- Fabric uses 1Password CLI for API keys
- Config backups preserve permissions

## Future Roadmap

### Planned Features
- Additional installers for popular tools
- More comprehensive test coverage
- Optional Docker container for testing
- Configuration profiles (minimal, full, custom)
- Rollback functionality from backups
- Parallel installer execution
- Web-based status dashboard

### Community Requests
- Track in GitHub Issues
- Prioritize based on votes
- Welcome contributions

## Contact & Support

### Getting Help
- Read documentation: README.md, TUI_GUIDE.md, DEPENDENCIES.md
- Check logs: `~/logs/<app>/`
- Run dependency check: `./check_dependencies.sh`
- Open GitHub issue with logs and system info

### Reporting Issues
Include:
- OS version (`cat /etc/os-release`)
- Script being run
- Full log output
- Steps to reproduce
- Expected vs actual behavior
