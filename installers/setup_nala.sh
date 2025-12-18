#!/usr/bin/env bash
#
# setup_nala.sh - Nala Package Manager Installation Script
# Description: Installs nala, a modern front-end for APT with better UX
# Category: System
# Usage: ./setup_nala.sh [OPTIONS]
#        -y, --yes, --non-interactive    Skip confirmation prompts
#        -h, --help                      Show help message
#

set -euo pipefail

# Parse command line arguments
NON_INTERACTIVE=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes|--non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -y, --yes, --non-interactive    Skip confirmation prompts"
            echo "  -h, --help                      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Save and change directories
readonly ORIG_PWD=$(pwd)

# Get script directory and source logging library
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# shellcheck source=../lib/logging.sh
source "$SCRIPT_DIR/../lib/logging.sh"
# shellcheck source=../lib/dependencies.sh
source "$SCRIPT_DIR/../lib/dependencies.sh"

# ------------------------------------------------------------
# Setup Logging
# ------------------------------------------------------------
# region
SCRIPT_NAME=$(basename "$0" .sh)
readonly APP_NAME="${SCRIPT_NAME/setup_/}"
readonly DL_DIR="${HOME}/downloads/$APP_NAME"
readonly LOG_DIR="${HOME}/logs/$APP_NAME"
readonly LOG_FILE="${LOG_DIR}/$(date +%Y%m%d_%H%M%S)_${APP_NAME}.log"

# Ensure directories exist
mkdir -p "$DL_DIR"
mkdir -p "$LOG_DIR"

log_info "=== $APP_NAME Installer Started ==="
log_info "Log file: $LOG_FILE"
if [[ "$NON_INTERACTIVE" == "true" ]]; then
    log_info "Running in non-interactive mode"
fi
# endregion

cleanup()
{
    local exit_code=$?

    log_info "Cleaning up..."

    # Return to original directory
    cd "$ORIG_PWD" 2>/dev/null || true

    log_info "Cleanup complete"
    # shellcheck disable=SC2086
    exit $exit_code
}

# Set trap for various exit signals
trap cleanup EXIT INT TERM ERR

# ------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

detect_version() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "$VERSION_ID"
    else
        echo "unknown"
    fi
}

# ------------------------------------------------------------
# Installation Functions
# ------------------------------------------------------------

install_nala_ubuntu() {
    local version="$1"

    log_info "Installing nala for Ubuntu $version..."

    # Ubuntu 22.04+ has nala in the official repos
    if [[ "${version%%.*}" -ge 22 ]]; then
        log_info "Using official Ubuntu repository..."

        if ! update_package_lists; then
            log_error "Failed to update package lists"
            return 1
        fi

        if ! install_package nala; then
            log_error "Failed to install nala"
            return 1
        fi

        log_success "Nala installed from official repositories"
        return 0
    else
        # For older versions, use PPA
        log_info "Adding PPA for older Ubuntu version..."

        if ! command -v add-apt-repository &> /dev/null; then
            log_info "Installing software-properties-common..."
            sudo apt-get install -y software-properties-common
        fi

        if ! sudo add-apt-repository -y ppa:volian/nala; then
            log_error "Failed to add PPA"
            return 1
        fi

        if ! update_package_lists; then
            log_error "Failed to update package lists"
            return 1
        fi

        if ! install_package nala; then
            log_error "Failed to install nala"
            return 1
        fi

        log_success "Nala installed from PPA"
        return 0
    fi
}

install_nala_debian() {
    local version="$1"

    log_info "Installing nala for Debian $version..."

    # Debian 12+ has nala in official repos
    if [[ "${version%%.*}" -ge 12 ]]; then
        log_info "Using official Debian repository..."

        if ! update_package_lists; then
            log_error "Failed to update package lists"
            return 1
        fi

        if ! install_package nala; then
            log_error "Failed to install nala"
            return 1
        fi

        log_success "Nala installed from official repositories"
        return 0
    else
        # For Debian 11, use backports or direct installation
        log_warning "Debian $version may require backports or manual installation"

        # Try backports first
        log_info "Trying backports repository..."

        if ! grep -q "bullseye-backports" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
            echo "deb http://deb.debian.org/debian bullseye-backports main" | \
                sudo tee /etc/apt/sources.list.d/bullseye-backports.list
        fi

        if ! update_package_lists; then
            log_error "Failed to update package lists"
            return 1
        fi

        if install_package -t bullseye-backports nala; then
            log_success "Nala installed from backports"
            return 0
        else
            log_error "Failed to install nala from backports"
            return 1
        fi
    fi
}

configure_nala() {
    log_info "Configuring nala..."

    # Fetch fastest mirrors
    log_info "Fetching fastest mirrors (this may take a moment)..."

    if sudo nala fetch --auto --fetches 3; then
        log_success "Fastest mirrors configured"
    else
        log_warning "Failed to fetch mirrors, but nala is still functional"
    fi

    # Set nala as default for unattended-upgrades if it exists
    if [[ -f /etc/apt/apt.conf.d/50unattended-upgrades ]]; then
        log_info "Configuring nala for unattended-upgrades..."
        if ! grep -q "Unattended-Upgrade::Package-Manager \"nala\"" /etc/apt/apt.conf.d/50unattended-upgrades; then
            echo 'Unattended-Upgrade::Package-Manager "nala";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null
        fi
    fi
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

main() {
    log_info "Starting nala installation..."

    # Check if already installed
    if command -v nala &> /dev/null; then
        local installed_version
        installed_version=$(nala --version 2>&1 | grep -oP '\\d+\\.\\d+\\.\\d+' || echo "unknown")
        log_warning "Nala is already installed (version: $installed_version)"
        
        if [[ "$NON_INTERACTIVE" == "true" ]]; then
            log_info "Non-interactive mode: Proceeding with reconfiguration/reinstallation"
        else
            read -rp "Do you want to reconfigure/reinstall? [y/N]: " reinstall
            if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
                log_info "Installation cancelled"
                exit 0
            fi
        fi
    fi

    # Detect distribution
    local distro
    distro=$(detect_distro)

    local version
    version=$(detect_version)

    log_info "Detected distribution: $distro $version"

    # Install based on distribution
    case "$distro" in
        ubuntu)
            if ! install_nala_ubuntu "$version"; then
                log_error "Installation failed"
                exit 1
            fi
            ;;
        debian)
            if ! install_nala_debian "$version"; then
                log_error "Installation failed"
                exit 1
            fi
            ;;
        *)
            log_error "Unsupported distribution: $distro"
            log_error "Nala is designed for Debian/Ubuntu systems"
            exit 1
            ;;
    esac

    # Configure nala
    configure_nala

    log_success "===================================="
    log_success "Nala installation completed!"
    log_success "===================================="

    echo
    echo "Nala is now ready to use. Try it out:"
    echo "  sudo nala update"
    echo "  sudo nala upgrade"
    echo "  sudo nala install <package>"
    echo
    echo "Nala features:"
    echo "  - Parallel downloads"
    echo "  - Beautiful progress bars"
    echo "  - Better error messages"
    echo "  - Transaction history"
    echo

    exit 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
