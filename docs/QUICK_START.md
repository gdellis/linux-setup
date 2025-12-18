# Quick Start Guide

This guide will help you get started with the Linux Setup project quickly.

## Prerequisites

- A Linux-based operating system (Ubuntu 20.04+, Debian 11+, or compatible)
- Bash shell
- Basic command-line tools (curl, git, etc.)

## Quick Installation

The fastest way to get started is to use the interactive menu system:

```bash
git clone https://github.com/gdellis/linux-setup
cd linux-setup
./menu.sh
```

The menu will:
- ✓ Automatically check system dependencies
- ✓ Offer to install missing tools (curl, wget, nala)
- ✓ Provide a beautiful TUI for running installers
- ✓ Handle everything with minimal user input

## Non-Interactive Installation

For automated deployments, you can use the non-interactive mode:

```bash
# Check and install dependencies
./check_dependencies.sh --install

# Install specific tools non-interactively
./installers/setup_nala.sh --yes
./installers/setup_gum.sh --yes
./installers/setup_ollama.sh --yes
./installers/setup_fabric.sh --yes
```

## Recommended First Steps

1. **Start with the essentials**:
   ```bash
   # Install the package manager and TUI tools for better experience
   ./installers/setup_nala.sh --yes
   ./installers/setup_gum.sh --yes
   
   # Install development tools
   ./installers/setup_vscode.sh --yes
   ./installers/setup_neovim.sh --yes
   ```

2. **Add AI capabilities** (optional):
   ```bash
   # Install AI tools
   ./installers/setup_ollama.sh --yes
   ./installers/setup_fabric.sh --yes
   ```

3. **Enhance your system** (optional):
   ```bash
   # Install security and productivity tools
   ./installers/setup_1password.sh --yes
   ./installers/setup_protonvpn.sh --yes
   ./installers/setup_syncthing.sh --yes
   ```

## Using the Python TUI (Advanced)

For a more feature-rich experience with categories and multi-select:

```bash
./py_menu.py
```

This enhanced menu provides:
- Category-based organization
- Search functionality
- Multi-select and batch installation
- Better visual design

## Post-Installation

After installation, you may need to:

1. **Restart your shell** to reload environment variables:
   ```bash
   exec bash
   ```

2. **Log out and back in** for group permissions to take effect (especially for GPU drivers)

3. **Configure specific tools**:
   - For Fabric: Configure 1Password CLI with API keys
   - For Ollama: Login to your account for cloud models (`ollama signin`)

## Troubleshooting

If you encounter any issues:

1. **Check logs**: Each installer creates logs in `~/logs/<tool>/`
2. **Verify dependencies**: Run `./check_dependencies.sh`
3. **Reinstall tools**: Most installers support reinstallation
4. **Consult documentation**: See [TUI_GUIDE.md](TUI_GUIDE.md) and [DEPENDENCIES.md](DEPENDENCIES.md)

## Next Steps

- Explore all available installers in the `installers/` directory
- Customize your setup by editing configuration files
- Contribute by adding new installers or improving existing ones

For more detailed information, see:
- [README.md](README.md) - Project overview
- [TUI_GUIDE.md](TUI_GUIDE.md) - Interactive menu usage
- [DEPENDENCIES.md](DEPENDENCIES.md) - Dependency management
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture and development guide