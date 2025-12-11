# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Automatic Dependency Management**:
  - Created `lib/dependencies.sh` utility library for dependency checking and installation
  - Added `check_dependencies.sh` script for system-wide dependency verification
  - Automatic dependency checking in `menu.sh` on startup
  - Auto-installation of missing dependencies (curl, wget, nala) with user consent
  - Comprehensive DEPENDENCIES.md documentation
- **Nala Package Manager Support**:
  - Added `setup_nala.sh` installer for the modern APT frontend
  - Supports Ubuntu (20.04+) and Debian (11+) with automatic version detection
  - Falls back to PPA/backports on older versions
  - Auto-configures fastest mirrors
- **Interactive TUI Menu**:
  - Created `menu.sh` with support for multiple TUI backends (Gum, Dialog, Whiptail, Bash)
  - Automatic installer discovery and organization
  - Beautiful console interface with Gum (when installed)
  - Graceful fallback to simpler backends when advanced tools unavailable
  - Integrated dependency checking on startup
  - Comprehensive TUI_GUIDE.md documentation
- **Gum Installer**: Added `setup_gum.sh` for installing the modern TUI tool
  - Supports both APT repository and direct download methods
  - Auto-detects system architecture
- **Backup functionality**: Added `backup_file()` function to `lib/logging.sh` that creates timestamped backups before overwriting files
- **Non-interactive mode**: Added `-y/--yes/--non-interactive` flag to `setup_fabric.sh` for automated deployments
- **Checksum verification**:
  - Improved ProtonVPN installer with proper SHA256 checksum verification
  - Added checksum verification warnings and manual verification instructions for ProtonMail and OrcaSlicer
- **CI/CD**: Added GitHub Actions workflow for automated ShellCheck analysis
- **Documentation**: Created this CHANGELOG.md to track project changes
- **Logging improvements**:
  - Added `log_success()` function to shared logging library
  - Added `log_warning()` alias for compatibility
  - Enhanced `log()` function with dual output (terminal + file) and ANSI color stripping

### Changed
- **Code deduplication**: Refactored all 6 installer scripts to use shared `lib/logging.sh`, eliminating ~438 lines of duplicated code:
  - `setup_fabric.sh`
  - `setup_ollama.sh`
  - `setup_orcaslicer.sh`
  - `setup_protonmail.sh`
  - `setup_protonvpn.sh`
  - `setup_syncthing.sh`
- **Error handling**: Standardized error handling across all installers:
  - Functions now use `return` instead of `exit` for better composability
  - Only `main()` functions use `exit` for final status
  - Improved error checking and recovery in `setup_syncthing.sh`
- **Code quality**: Enforced `readonly` for all constant variables across all installers
- **Directory naming**: Standardized download directory to lowercase `downloads/` (was inconsistent with `Downloads/` in setup_orcaslicer.sh)
- **Backup before overwrite**: `setup_fabric.sh` now backs up existing configuration files before overwriting
- **Platform restriction**: `new_installer.sh` now includes platform check to ensure it only runs on Linux systems

### Fixed
- **Typo**: Fixed `lot_warning` → `log_warning` in `setup_ollama.sh:173`
- **Package manager**: Updated installers to use `nala` instead of `apt-get` for better UX
- **Checksum verification**: Fixed broken checksum verification in `setup_protonvpn.sh` (was checking wrong file path)

### Security
- Added checksum verification for ProtonVPN downloads
- Added warnings about missing checksum verification for ProtonMail and OrcaSlicer
- Provided manual verification instructions for packages without official checksums

## [Previous Releases]

No previous changelog entries. This is the first CHANGELOG for the project.

---

## Guidelines for Updating

When making changes, add them under the `[Unreleased]` section in the appropriate category:
- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** for vulnerability fixes

When releasing a new version, move the Unreleased changes to a new version heading with the release date.
