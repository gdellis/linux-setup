# Linux Development Environment Setup

## Description

This project automates the setup of a comprehensive Linux development environment with customized bash configuration, CLI tools, and AI model management. It streamlines the process of configuring a productive development environment on Linux systems.

The setup includes:
- Customized bash environment with aliases and prompt customization
- Automated installation and configuration of development tools
- AI model management for local and cloud inference with Ollama
- 3D printing software setup (OrcaSlicer)

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [Setup Steps](#setup-steps)
- [Usage](#usage)
- [Configuration](#configuration)
- [Technologies Used](#technologies-used)
- [Contributing](#contributing)
- [License](#license)

## Quick Start

**New!** Interactive console menu with automatic dependency management:

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

**Check dependencies manually:**

```bash
./check_dependencies.sh           # Check only
./check_dependencies.sh --install # Check and auto-install
```

**Run individual installers directly:**

```bash
./installers/setup_ollama.sh
./installers/setup_fabric.sh
# etc.
```

**New!** Run installers remotely without cloning the repository:

```bash
# Run any installer directly from GitHub
bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) setup_vscode.sh

# Or run specific installers directly
bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/installers/setup_neovim.sh)

# Run the bash TUI menu directly
bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) menu

# Run the Python TUI menu directly
bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) python-menu
```

See [docs/TUI_GUIDE.md](docs/TUI_GUIDE.md), [docs/DEPENDENCIES.md](docs/DEPENDENCIES.md), and [docs/REMOTE_EXECUTION.md](docs/REMOTE_EXECUTION.md) for details.

## Features

- **Automatic Dependency Management** ⭐ NEW!
  - Automatic checking of system dependencies on startup
  - Smart installation of missing tools (curl, wget, nala, etc.)
  - Nala package manager for better APT experience
  - Comprehensive dependency library for scripts
  - See [docs/DEPENDENCIES.md](docs/DEPENDENCIES.md) for full documentation

- **Interactive TUI Menu** ⭐ NEW!
  - Beautiful console interface with multiple backend support (Gum, Dialog, Bash)
  - Automatic script discovery and organization
  - Integrated dependency checking
  - Easy navigation and installer execution
  - See [docs/TUI_GUIDE.md](docs/TUI_GUIDE.md) for full documentation

- **Remote Execution Capability** ⭐ NEW!
  - Run any installer script directly from GitHub without cloning
  - Bootstrap script for easy access to all installers
  - Automatic library sourcing from remote repository
  - Both bash and Python TUI menus support remote execution
  - See [docs/REMOTE_EXECUTION.md](docs/REMOTE_EXECUTION.md) for full documentation

- **Enhanced Bash Environment**:
  - Custom `.bashrc` configuration with Starship prompt
  - Useful aliases for common commands (ls, grep, etc.)
  - Colorized output for better readability
  - History management improvements

- **AI Model Management**:
  - Automated Ollama installation
  - Download and management of local and cloud AI models
  - Support for various AI models including coding assistants and embedding models

- **Development Tools Setup**:
  - Fabric AI framework installation and configuration
  - YouTube transcription capabilities with yt-dlp
  - Integrated API key management with 1Password CLI

- **3D Printing Software**:
  - OrcaSlicer installation with multiple options (Flatpak, AppImage, Docker, source build)

- **Logging and Error Handling**:
  - Comprehensive logging for all setup processes
  - Colorized output for better visibility
  - Robust error handling and reporting

## Installation

### Prerequisites

Before running the setup scripts, ensure you have:

- A Linux-based operating system
- Bash shell
- Basic command-line tools (curl, git, etc.)
- For Fabric setup: 1Password CLI configured with appropriate API keys
- For OrcaSlicer Docker builds: Docker installed

### Setup Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/gdellis/linux-setup
   cd linuxsetup
   ```

2. Run the bash environment setup:
   ```bash
   ./setup_bash.sh
   ```

3. Install and configure AI tools (optional):
   ```bash
   # Install and configure Ollama with predefined models
   ./installers/setup_ollama.sh
   
   # Install and configure Fabric AI framework
   ./installers/setup_fabric.sh
   ```

4. Install 3D printing software (optional):
   ```bash
   # Choose one of the following installation methods:
   ./installers/setup_orcaslicer.sh flatpak
   ./installers/setup_orcaslicer.sh appimage
   ./installers/setup_orcaslicer.sh docker
   ./installers/setup_orcaslicer.sh linux
   ```

## Usage

After installation, your bash environment will be enhanced with:

- Custom aliases for common commands:
  - `ll`: Detailed list view (`ls -alF`)
  - `la`: List all files (`ls -A`)
  - `l`: Compact list view (`ls -CF`)
  - Colorized `ls`, `grep`, and other commands

- Starship prompt for enhanced terminal appearance

- For AI tools:
  - Ollama with preconfigured local and cloud models
  - Fabric framework with pattern aliases
  - YouTube transcription capabilities with the `yt` command

## Configuration

The project creates backups of your existing configuration files in the `backups/` directory with timestamps.

Main configuration files:
- `bash/.bashrc`: Enhanced bash configuration with Starship prompt
- `bash/.bash_aliases`: Custom command aliases
- Custom configurations for Fabric, Ollama, and other tools are placed in their respective config directories

## Technologies Used

- **Bash scripting** - Core automation framework
- **Starship** - Customizable prompt for any shell
- **Ollama** - Local AI model management
- **Fabric** - AI framework for pattern-based processing
- **OrcaSlicer** - 3D printing software
- **1Password CLI** - Secure API key management

## Contributing

1. Fork the repository
2. Create a new branch (`git checkout -b feature/YourFeature`)
3. Commit your changes (`git commit -m 'Add some feature'`)
4. Push to the branch (`git push origin feature/YourFeature`)
5. Open a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.