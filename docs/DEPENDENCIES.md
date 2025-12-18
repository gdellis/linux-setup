# Dependency Management Guide

This guide explains how the linux-setup project handles dependencies and how to ensure your system is properly configured.

## Overview

The project includes automatic dependency checking and installation to ensure a smooth experience. Dependencies are managed through:

1. **Automatic checking** when running `menu.sh`
2. **Manual checking** with `check_dependencies.sh`
3. **Utility library** (`lib/dependencies.sh`) for scripts to use
4. **Automated installation** of missing dependencies (with user consent)

## Quick Dependency Check

### Check All Dependencies

```bash
./check_dependencies.sh
```

This will show you what's installed and what's missing.

### Check and Auto-Install

```bash
./check_dependencies.sh --install
```

This will automatically install any missing dependencies.

### Verbose Output

```bash
./check_dependencies.sh --verbose --install
```

Shows detailed version information for all dependencies.

## Dependency Categories

### 1. Essential System Tools

These are required for most installers to function:

- **curl** - Download files from the internet
- **wget** - Alternative download tool
- **ca-certificates** - SSL/TLS certificate verification
- **gnupg** - GPG key management for repository authentication

**Auto-installed:** Yes, when running `menu.sh` or with `--install` flag

### 2. Package Managers

- **nala** (Preferred) - Modern APT frontend with better UX
  - Parallel downloads
  - Beautiful progress bars
  - Better error messages
  - Transaction history

- **apt-get** (Fallback) - Standard Debian/Ubuntu package manager

**Auto-installed:** nala is automatically offered when running `menu.sh`

### 3. Build Tools (Optional)

- **build-essential** - Compilers and build tools
- **git** - Version control (needed for building from source)

**Auto-installed:** No, but recommended for development

### 4. TUI Tools (Optional)

- **gum** (Recommended) - Beautiful TUI components
- **dialog** - Classic TUI dialogs
- **whiptail** - Simpler dialog alternative

**Auto-installed:** gum can be installed from the menu

## How Automatic Installation Works

### Menu Integration

When you run `./menu.sh`, it automatically:

1. Checks for essential dependencies (curl, wget, etc.)
2. Checks for nala package manager
3. If anything is missing, prompts you to install
4. Installs dependencies with your permission
5. Continues to the main menu

Example interaction:

```
────────────────────────────────────────
  System Dependencies Check
────────────────────────────────────────

Nala package manager is not installed.
  - Nala provides a better experience than apt
  - All installers use nala for package management
  - Recommended for best experience

Would you like to install missing dependencies now? [Y/n]:
```

### Script Integration

Individual scripts can use the dependency library:

```bash
# Source the library
source "$SCRIPT_DIR/../lib/dependencies.sh"

# Check and auto-install dependencies
ensure_dependencies --auto-install curl wget git

# Or check without installing
if ! check_dependencies curl wget git; then
    log_error "Missing dependencies"
    exit 1
fi
```

## Installing Individual Components

### Install Nala

```bash
./installers/setup_nala.sh
```

**Features:**
- Detects Ubuntu/Debian version
- Uses official repos on newer versions
- Falls back to PPA/backports on older versions
- Auto-configures fastest mirrors
- Works with unattended-upgrades

### Install Gum (TUI Tool)

```bash
./installers/setup_gum.sh
```

**Features:**
- Tries APT repository first (cleaner, gets updates)
- Falls back to direct download if needed
- Auto-detects system architecture
- Version checking

### Install Build Tools

```bash
sudo apt-get install build-essential git
```

Or with nala:

```bash
sudo nala install build-essential git
```

## Dependency Library Reference

The `lib/dependencies.sh` library provides these functions:

### Basic Checks

```bash
# Check if command exists
if command_exists "curl"; then
    echo "curl is installed"
fi

# Check if package is installed
if package_installed "nala"; then
    echo "nala is installed"
fi
```

### Installation

```bash
# Install a single package
install_package "curl"

# Install multiple packages
install_dependencies "curl" "wget" "git"

# Ensure command exists, install if needed
ensure_command "curl" "curl" true  # auto-install
```

### Smart Dependency Management

```bash
# Check multiple dependencies
check_dependencies "curl" "wget" "git"
# Returns 0 if all found, 1 if any missing

# Ensure dependencies with auto-install
ensure_dependencies --auto-install curl wget git
# Returns 0 if all satisfied (installed or were there)
```

### Package Manager Functions

```bash
# Ensure nala is installed
ensure_nala --auto-install

# Get best available package manager
pm=$(get_package_manager)
echo "Using: $pm"  # Outputs: nala, apt-get, or apt

# Update package lists
update_package_lists
```

### Utility Functions

```bash
# Install development tools
install_dev_tools

# Install common installer dependencies
install_installer_deps

# List missing dependencies
missing=$(list_missing_dependencies curl wget git)
echo "Missing: $missing"

# Print status of all dependencies
print_dependency_status curl wget git nala gum
```

## Troubleshooting

### Dependency Check Fails

**Issue:** `check_dependencies.sh` reports errors

**Solution:**

```bash
# Try with sudo to ensure proper permissions
sudo ./check_dependencies.sh --install

# Or manually install
sudo apt-get update
sudo apt-get install curl wget ca-certificates gnupg
```

### Nala Installation Fails

**Issue:** `setup_nala.sh` fails on your distribution

**Solution:**

Nala is designed for Debian/Ubuntu. Check your distribution:

```bash
cat /etc/os-release
```

For unsupported distributions, installers will fall back to apt-get automatically.

### Permission Denied

**Issue:** Cannot install packages

**Solution:**

Ensure you have sudo permissions:

```bash
sudo -v  # Verify sudo access
```

Scripts will prompt for sudo when needed.

### Already Installed Warning

**Issue:** Script says dependency is installed but you want to reinstall

**Solution:**

Most installers check if already installed and ask if you want to reinstall:

```bash
./installers/setup_nala.sh
# Will prompt: "Do you want to reconfigure/reinstall? [y/N]:"
```

## Best Practices

### For Users

1. **Run dependency check first:**
   ```bash
   ./check_dependencies.sh --install
   ```

2. **Install nala for better experience:**
   ```bash
   ./installers/setup_nala.sh
   ```

3. **Install gum for beautiful TUI:**
   ```bash
   ./installers/setup_gum.sh
   ```

4. **Then use the menu:**
   ```bash
   ./menu.sh
   ```

### For Script Developers

1. **Always source both libraries:**
   ```bash
   source "$SCRIPT_DIR/../lib/logging.sh"
   source "$SCRIPT_DIR/../lib/dependencies.sh"
   ```

2. **Check dependencies early:**
   ```bash
   ensure_dependencies curl wget || {
       log_error "Missing dependencies"
       exit 1
   }
   ```

3. **Use the best package manager:**
   ```bash
   # Don't hardcode apt-get
   pm=$(get_package_manager)
   sudo $pm install package

   # Or use the install function
   install_package "package"
   ```

4. **Provide helpful error messages:**
   ```bash
   if ! command_exists "curl"; then
       log_error "curl is required"
       log_info "Install with: sudo apt-get install curl"
       log_info "Or run: ./check_dependencies.sh --install"
       exit 1
   fi
   ```

## System Requirements

### Minimum Requirements

- **OS:** Debian 11+ or Ubuntu 20.04+
- **Disk:** 100MB for dependencies
- **Network:** Internet connection for downloads
- **Permissions:** sudo access

### Recommended Requirements

- **OS:** Ubuntu 22.04+ or Debian 12+
- **Nala:** Installed (via `setup_nala.sh`)
- **Gum:** Installed (via `setup_gum.sh`)
- **Build tools:** For compiling software if needed

## Dependency Update Policy

### When to Update

Dependencies are checked and updated:

1. **On first run** - Menu checks on startup
2. **Manually** - Run `check_dependencies.sh`
3. **Before major operations** - Scripts check their specific needs

### Keeping Dependencies Current

```bash
# Update package lists
sudo nala update
# or
sudo apt-get update

# Upgrade all packages
sudo nala upgrade
# or
sudo apt-get upgrade

# Reinstall specific tool
./installers/setup_nala.sh   # Updates nala
./installers/setup_gum.sh    # Updates gum
```

## Integration Examples

### Example 1: Simple Check

```bash
#!/usr/bin/env bash
source "lib/dependencies.sh"

# Check before running
if ! check_dependencies curl wget; then
    echo "Please install: curl wget"
    exit 1
fi

# Continue with script...
```

### Example 2: Auto-Install

```bash
#!/usr/bin/env bash
source "lib/dependencies.sh"

# Ensure dependencies (auto-install)
ensure_dependencies --auto-install curl wget git || {
    echo "Failed to satisfy dependencies"
    exit 1
}

# Continue with script...
```

### Example 3: Optional Dependencies

```bash
#!/usr/bin/env bash
source "lib/dependencies.sh"

# Check optional dependency
if command_exists "jq"; then
    echo "Using jq for JSON parsing"
    use_jq=true
else
    echo "jq not found, using alternative method"
    use_jq=false
fi
```

## FAQ

**Q: Will this install packages without asking?**

A: No. All installations require user confirmation unless you explicitly use the `--install` flag.

**Q: What if I don't want nala?**

A: Scripts will automatically fall back to apt-get if nala is not available.

**Q: Can I use this on other distributions?**

A: The dependency system is designed for Debian/Ubuntu. Other distributions may need manual dependency installation.

**Q: How do I skip dependency checks?**

A: You can't skip entirely, but if dependencies are already installed, checks are instant.

**Q: What happens if installation fails?**

A: Scripts will log the error and either fall back to alternatives or exit gracefully with instructions.

## See Also

- [README.md](README.md) - Project overview
- [TUI_GUIDE.md](TUI_GUIDE.md) - TUI menu documentation
- [CHANGELOG.md](CHANGELOG.md) - Recent changes
- [lib/dependencies.sh](lib/dependencies.sh) - Dependency library source
