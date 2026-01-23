#!/usr/bin/env bash
#
# dependencies.sh - Dependency Management Library
# Description: Provides functions for checking and installing system dependencies
# Usage: Source this file in your scripts: source "$SCRIPT_DIR/../lib/dependencies.sh"
#

# Ensure logging library is loaded
# shellcheck disable=SC2317  # This check is reachable when sourced
if ! declare -f log_info &> /dev/null; then
    echo "ERROR: dependencies.sh requires logging.sh to be sourced first" >&2
    return 1 2>/dev/null || exit 1
fi

# ------------------------------------------------------------
# Core Dependency Functions
# ------------------------------------------------------------

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if a package is installed (dpkg-based systems)
package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

# Install a single package using best available package manager
install_package() {
    local package="$1"
    local package_manager

    # Determine best package manager
    if command_exists nala; then
        package_manager="nala"
    elif command_exists apt-get; then
        package_manager="apt-get"
    elif command_exists apt; then
        package_manager="apt"
    else
        log_error "No supported package manager found"
        return 1
    fi

    log_info "Installing $package using $package_manager..."

    case "$package_manager" in
        nala)
            if sudo nala install -y "$package"; then
                log_success "Installed $package"
                return 0
            fi
            ;;
        apt-get)
            # Update first if we haven't recently
            if [[ ! -f /var/cache/apt/pkgcache.bin ]] || \
               [[ $(find /var/cache/apt/pkgcache.bin -mmin +60 2>/dev/null) ]]; then
                sudo apt-get update -qq
            fi

            if sudo apt-get install -y "$package"; then
                log_success "Installed $package"
                return 0
            fi
            ;;
        apt)
            if sudo apt install -y "$package"; then
                log_success "Installed $package"
                return 0
            fi
            ;;
    esac

    log_error "Failed to install $package"
    return 1
}

# Check and optionally install a command
# Usage: ensure_command "curl" ["curl"]
ensure_command() {
    local command_name="$1"
    local package_name="${2:-$1}"  # Default to command name if not specified
    local auto_install="${3:-false}"

    if command_exists "$command_name"; then
        return 0
    fi

    local msg="Command '$command_name' not found"
    log_warning "$msg"

    if [[ "$auto_install" == "true" ]]; then
        log_info "Attempting to install $package_name..."
        if install_package "$package_name"; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Check multiple dependencies at once
# Returns 0 if all found, 1 if any missing
# Usage: check_dependencies "curl" "wget" "git"
check_dependencies() {
    local missing=()
    local dep

    for dep in "$@"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        return 0
    fi

    log_error "Missing dependencies: ${missing[*]}"
    return 1
}

# Install multiple dependencies
# Usage: install_dependencies "curl" "wget" "git"
install_dependencies() {
    local failed=()
    local dep

    for dep in "$@"; do
        if ! command_exists "$dep"; then
            if ! install_package "$dep"; then
                failed+=("$dep")
            fi
        fi
    done

    if [[ ${#failed[@]} -eq 0 ]]; then
        return 0
    fi

    log_error "Failed to install: ${failed[*]}"
    return 1
}

# Ensure dependencies with auto-install option
# Usage: ensure_dependencies [--auto-install] dep1 dep2 dep3
ensure_dependencies() {
    local auto_install=false
    local deps=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --auto-install|-a)
                auto_install=true
                shift
                ;;
            *)
                deps+=("$1")
                shift
                ;;
        esac
    done

    # Check dependencies
    local missing=()
    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_info "All dependencies satisfied"
        return 0
    fi

    log_warning "Missing dependencies: ${missing[*]}"

    if [[ "$auto_install" == "true" ]]; then
        log_info "Auto-installing missing dependencies..."
        if install_dependencies "${missing[@]}"; then
            log_success "All dependencies installed"
            return 0
        else
            log_error "Some dependencies failed to install"
            return 1
        fi
    else
        log_error "Please install missing dependencies manually"
        return 1
    fi
}

# ------------------------------------------------------------
# System Package Manager Functions
# ------------------------------------------------------------

# Ensure nala is installed (preferred package manager)
ensure_nala() {
    if command_exists nala; then
        return 0
    fi

    log_warning "Nala (improved apt frontend) is not installed"

    local auto_install="${1:-false}"

    if [[ "$auto_install" == "true" ]] || [[ "$auto_install" == "--auto-install" ]]; then
        log_info "Installing nala..."

        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

        if [[ -f "$script_dir/installers/setup_nala.sh" ]]; then
            if bash "$script_dir/installers/setup_nala.sh"; then
                log_success "Nala installed successfully"
                return 0
            else
                log_error "Failed to install nala"
                return 1
            fi
        else
            log_error "Nala installer not found"
            return 1
        fi
    else
        log_info "Nala can be installed with: ./installers/setup_nala.sh"
        return 1
    fi
}

# Get the best available package manager
get_package_manager() {
    if command_exists nala; then
        echo "nala"
    elif command_exists apt-get; then
        echo "apt-get"
    elif command_exists apt; then
        echo "apt"
    else
        echo "none"
    fi
}

# Update package lists
update_package_lists() {
    local pm
    pm=$(get_package_manager)

    case "$pm" in
        nala)
            sudo nala update
            ;;
        apt-get)
            sudo apt-get update
            ;;
        apt)
            sudo apt update
            ;;
        none)
            log_error "No package manager found"
            return 1
            ;;
    esac
}

# ------------------------------------------------------------
# Common Dependency Profiles
# ------------------------------------------------------------

# Install basic development tools
install_dev_tools() {
    log_info "Installing development tools..."

    local tools=(
        "build-essential"
        "git"
        "curl"
        "wget"
        "ca-certificates"
        "gnupg"
        "lsb-release"
    )

    install_dependencies "${tools[@]}"
}

# Install common dependencies for installer scripts
install_installer_deps() {
    log_info "Installing common installer dependencies..."

    local deps=(
        "curl"
        "wget"
        "ca-certificates"
        "gnupg"
        "software-properties-common"
    )

    install_dependencies "${deps[@]}"
}

# ------------------------------------------------------------
# Dependency Reporting
# ------------------------------------------------------------

# List all missing dependencies from a list
list_missing_dependencies() {
    local missing=()

    for dep in "$@"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "${missing[@]}"
        return 1
    fi

    return 0
}

# Print dependency status
print_dependency_status() {
    log_info "Dependency Status:"

    for dep in "$@"; do
        if command_exists "$dep"; then
            local version
            version=$("$dep" --version 2>&1 | head -1 || echo "installed")
            log_info "  ✓ $dep: $version"
        else
            log_warning "  ✗ $dep: not found"
        fi
    done
}
