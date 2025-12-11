#!/usr/bin/env bash
#
# check_dependencies.sh - System Dependency Checker
# Description: Checks and optionally installs all system dependencies
# Usage: ./check_dependencies.sh [--install] [--verbose]
#

set -euo pipefail

# Get script directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Source libraries
# shellcheck source=lib/logging.sh
source "$SCRIPT_DIR/lib/logging.sh"
# shellcheck source=lib/dependencies.sh
source "$SCRIPT_DIR/lib/dependencies.sh"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

# Parse arguments
AUTO_INSTALL=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --install|-i)
            AUTO_INSTALL=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            cat << EOF
Usage: $0 [OPTIONS]

Check system dependencies for linux-setup project.

Options:
    --install, -i    Automatically install missing dependencies
    --verbose, -v    Show detailed information
    --help, -h       Show this help message

Example:
    $0                  # Check only
    $0 --install        # Check and install
    $0 -iv              # Verbose check and install
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# ------------------------------------------------------------
# Dependency Lists
# ------------------------------------------------------------

# Essential system tools
readonly ESSENTIAL_DEPS=(
    "curl"
    "wget"
    "ca-certificates"
    "gnupg"
)

# Package management tools
readonly PKG_MGR_DEPS=(
    "nala"          # Preferred package manager
    "apt-get"       # Fallback
)

# Build tools (optional but recommended)
readonly BUILD_DEPS=(
    "build-essential"
    "git"
)

# TUI tools (optional)
readonly TUI_DEPS=(
    "gum"
    "dialog"
)

# ------------------------------------------------------------
# Checking Functions
# ------------------------------------------------------------

check_dependency_group() {
    local group_name="$1"
    shift
    local deps=("$@")

    echo
    echo "════════════════════════════════════════"
    echo "  $group_name"
    echo "════════════════════════════════════════"

    local missing=()
    local found=()

    for dep in "${deps[@]}"; do
        if command_exists "$dep"; then
            found+=("$dep")
            if [[ "$VERBOSE" == "true" ]]; then
                local version=""
                version=$("$dep" --version 2>&1 | head -1 || echo "installed")
                log_success "✓ $dep - $version"
            else
                log_success "✓ $dep"
            fi
        else
            missing+=("$dep")
            log_error "✗ $dep - not found"
        fi
    done

    # Return counts
    echo "${#found[@]} ${#missing[@]}"
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

main() {
    clear
    echo "╔══════════════════════════════════════╗"
    echo "║  Linux Setup Dependency Checker      ║"
    echo "╚══════════════════════════════════════╝"
    echo

    local total_missing=0
    local total_found=0
    local all_missing=()

    # Check essential dependencies
    local result
    result=$(check_dependency_group "Essential System Tools" "${ESSENTIAL_DEPS[@]}")
    read -r found missing <<< "$result"
    ((total_found += found))
    ((total_missing += missing))

    # Store missing essential deps
    for dep in "${ESSENTIAL_DEPS[@]}"; do
        if ! command_exists "$dep"; then
            all_missing+=("$dep")
        fi
    done

    # Check package manager
    result=$(check_dependency_group "Package Managers" "${PKG_MGR_DEPS[@]}")
    read -r found missing <<< "$result"
    ((total_found += found))
    # Don't count apt-get as missing if we have another

    # Check if we have nala specifically
    local has_nala=false
    if command_exists nala; then
        has_nala=true
    else
        all_missing+=("nala")
    fi

    # Check build tools
    result=$(check_dependency_group "Build Tools (Optional)" "${BUILD_DEPS[@]}")
    read -r found missing <<< "$result"
    ((total_found += found))

    # Check TUI tools
    result=$(check_dependency_group "TUI Tools (Optional)" "${TUI_DEPS[@]}")
    read -r found missing <<< "$result"
    ((total_found += found))

    # Summary
    echo
    echo "════════════════════════════════════════"
    echo "  Summary"
    echo "════════════════════════════════════════"
    echo "  Found: $total_found dependencies"
    echo "  Missing: ${#all_missing[@]} critical dependencies"
    echo

    # Handle missing dependencies
    if [[ ${#all_missing[@]} -gt 0 ]]; then
        echo "Critical missing dependencies:"
        for dep in "${all_missing[@]}"; do
            echo "  - $dep"
        done
        echo

        if [[ "$AUTO_INSTALL" == "true" ]]; then
            log_info "Auto-install enabled. Installing missing dependencies..."
            echo

            # Install essential deps first
            local essential_missing=()
            for dep in "${ESSENTIAL_DEPS[@]}"; do
                if ! command_exists "$dep"; then
                    essential_missing+=("$dep")
                fi
            done

            if [[ ${#essential_missing[@]} -gt 0 ]]; then
                log_info "Installing essential tools..."
                if install_dependencies "${essential_missing[@]}"; then
                    log_success "Essential tools installed"
                else
                    log_error "Failed to install some essential tools"
                fi
                echo
            fi

            # Install nala if missing
            if [[ "$has_nala" == "false" ]]; then
                log_info "Installing nala package manager..."
                if bash "$SCRIPT_DIR/installers/setup_nala.sh"; then
                    log_success "Nala installed"
                else
                    log_error "Failed to install nala"
                fi
                echo
            fi

            log_success "Dependency installation complete!"
        else
            log_warning "Run with --install to automatically install missing dependencies"
            echo
            echo "Or install manually:"
            echo "  sudo apt-get update"
            echo "  sudo apt-get install ${all_missing[*]}"
            echo
            echo "To install nala:"
            echo "  ./installers/setup_nala.sh"
        fi

        exit 1
    else
        log_success "✓ All critical dependencies satisfied!"
        echo
        echo "Your system is ready to run linux-setup installers."
        echo

        # Check optional tools
        local optional_missing=()

        if ! command_exists gum; then
            optional_missing+=("gum (for better TUI)")
        fi

        if ! command_exists git; then
            optional_missing+=("git (for development)")
        fi

        if [[ ${#optional_missing[@]} -gt 0 ]]; then
            echo "Optional enhancements:"
            for item in "${optional_missing[@]}"; do
                echo "  - $item"
            done
            echo
            echo "Install with:"
            echo "  ./installers/setup_gum.sh    # For better TUI"
            echo "  sudo apt-get install git     # For development"
        fi

        exit 0
    fi
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
