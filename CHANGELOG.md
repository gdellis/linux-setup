# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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
