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