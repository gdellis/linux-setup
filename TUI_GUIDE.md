# TUI (Terminal User Interface) Guide

This guide explains how to use the interactive console menu for the linux-setup project.

## Quick Start

```bash
# Run the interactive menu
./menu.sh
```

The menu will automatically detect the best available TUI backend and provide an interactive interface for running installer scripts.

## TUI Backends

The menu supports multiple TUI backends, auto-detecting the best available option:

### 1. Gum (Recommended) ⭐

**Best experience** - Modern, beautiful, and intuitive.

**Install:**
```bash
./installers/setup_gum.sh
```

Or install via the menu itself (option will be available).

**Features:**
- Beautiful styled output with colors
- Smooth scrolling lists
- Keyboard and mouse support
- Modern terminal UI components

**Screenshot simulation:**
```
╔══════════════════════════════════════╗
║   Linux Setup - Installation Menu   ║
╚══════════════════════════════════════╝

Select an installer:
> fabric
    Installs and configures Fabric AI
  ollama
    Installs Ollama and downloads AI models
  orcaslicer
    Installs OrcaSlicer 3D printing software
  ...
```

### 2. Dialog

Classic terminal dialog boxes. Available on most systems.

**Install (if needed):**
```bash
sudo apt-get install dialog
```

**Features:**
- Traditional TUI with box borders
- Widely compatible
- Reliable fallback option

### 3. Whiptail

Similar to dialog, often pre-installed on Debian/Ubuntu systems.

### 4. Simple Bash Menu

Plain text menu. Always available as fallback.

## Menu Features

### Main Menu

- **Automatic script discovery** - All `setup_*.sh` scripts are automatically listed
- **Descriptions** - Shows the description from each script's header
- **System options** - Install/update Gum, exit
- **Error handling** - Graceful handling of script failures

### Navigation

**With Gum:**
- `↑`/`↓` or `j`/`k` - Navigate options
- `Enter` - Select
- `Ctrl+C` or `Esc` - Exit

**With Dialog:**
- `↑`/`↓` - Navigate options
- `Enter` - Select
- `Tab` - Move between buttons
- `Esc` - Cancel

**Simple Bash:**
- Type the number and press `Enter`

### Running Installers

1. Select an installer from the menu
2. The script runs in the foreground
3. You can see all output and interact if needed
4. Press Enter when done to return to menu

## Customization

### Adding Custom Options

Edit `menu.sh` to add custom menu entries:

```bash
# In show_menu_gum() or show_menu_bash()
options+=("custom-task")
options+=("  My custom installation task")
scripts+=("/path/to/custom/script.sh")
```

### Changing Colors (Gum)

Modify the `gum style` commands in `menu.sh`:

```bash
gum style \
    --foreground 212 \      # Purple (change to: 196=red, 46=green, etc.)
    --border-foreground 212 \
    --border double \
    "Your Text"
```

### Menu Banner

Edit the `BANNER` variable in `menu.sh`:

```bash
readonly BANNER="
╔═══════════════════════╗
║   Your Custom Title   ║
╚═══════════════════════╝
"
```

## Tips & Tricks

### 1. Quick Launch

Create an alias in your `~/.bashrc`:

```bash
alias setup-menu='cd ~/linux-setup && ./menu.sh'
```

Then just type `setup-menu` from anywhere.

### 2. Run Specific Installer Directly

You can still run installers directly without the menu:

```bash
./installers/setup_ollama.sh
```

### 3. Non-Interactive Mode

For automation, skip the menu and run scripts directly:

```bash
# Example with Fabric's non-interactive flag
./installers/setup_fabric.sh --yes
```

### 4. Check Available TUI Tools

```bash
# Check what TUI backends are available
for tool in gum dialog whiptail; do
    command -v $tool &>/dev/null && echo "$tool: installed" || echo "$tool: not found"
done
```

## Troubleshooting

### Menu doesn't display correctly

**Issue:** Characters look wrong or colors don't show

**Solution:** Ensure your terminal supports UTF-8 and 256 colors:

```bash
# Check terminal type
echo $TERM

# Should be something like: xterm-256color, screen-256color, etc.

# If not, set it:
export TERM=xterm-256color
```

### Gum not found after installation

**Issue:** Menu doesn't detect gum after installing

**Solution:** Restart your shell or source your profile:

```bash
# Restart shell
exec bash

# Or source profile
source ~/.bashrc
```

### Permission errors

**Issue:** "Permission denied" when running menu

**Solution:** Make it executable:

```bash
chmod +x menu.sh
```

### Scripts fail to run

**Issue:** Installer scripts fail when run from menu

**Solution:** Ensure all scripts are executable:

```bash
chmod +x installers/setup_*.sh
```

## Advanced Usage

### Integrate with System Menu

Add to your desktop environment's application menu:

**Create:** `~/.local/share/applications/linux-setup.desktop`

```ini
[Desktop Entry]
Name=Linux Setup Menu
Comment=Interactive installer menu
Exec=/home/YOUR_USERNAME/linux-setup/menu.sh
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=System;Settings;
```

### SSH Remote Access

The TUI works great over SSH:

```bash
ssh user@remote-host
cd ~/linux-setup
./menu.sh
```

### Tmux/Screen Integration

Run in a persistent session:

```bash
tmux new -s setup
./menu.sh
# Detach with Ctrl+B, D
# Reattach later with: tmux attach -t setup
```

## Comparison of TUI Backends

| Feature | Gum | Dialog | Whiptail | Bash |
|---------|-----|--------|----------|------|
| **Visual Quality** | ★★★★★ | ★★★★ | ★★★ | ★★ |
| **Ease of Use** | ★★★★★ | ★★★★ | ★★★★ | ★★★ |
| **Availability** | Manual install | Common | Very common | Always |
| **Colors** | Full 256 color | Limited | Limited | None |
| **Mouse Support** | Yes | Yes | Yes | No |
| **Modern Look** | Yes | No | No | No |
| **Keyboard Nav** | Excellent | Good | Good | Numbers only |

## Examples

### Example 1: First Time Setup

```bash
# 1. Clone the repo
git clone https://github.com/yourusername/linux-setup.git
cd linux-setup

# 2. Run menu (will use simple bash menu)
./menu.sh

# 3. Select "Install/Update Gum TUI"
# 4. Exit and restart menu
./menu.sh

# 5. Enjoy the beautiful Gum interface!
```

### Example 2: Batch Installation

While the menu is interactive, you can still script installations:

```bash
#!/bin/bash
# batch-install.sh

installers=(
    "setup_ollama.sh"
    "setup_fabric.sh"
    "setup_syncthing.sh"
)

cd ~/linux-setup/installers

for installer in "${installers[@]}"; do
    echo "Running $installer..."
    ./"$installer"
done
```

### Example 3: Custom Menu

Create your own menu variant:

```bash
cp menu.sh my-custom-menu.sh
# Edit my-custom-menu.sh to:
# - Filter which installers appear
# - Add custom pre/post actions
# - Change styling
# - Add logging
```

## Related Documentation

- [Main README](README.md) - Project overview
- [CHANGELOG](CHANGELOG.md) - Recent changes
- [Tests](tests/README.md) - Testing information

## Contributing

To add TUI features:

1. Test with all backends (gum, dialog, bash)
2. Ensure graceful fallback
3. Document new features here
4. Update CHANGELOG.md

## Credits

- **Gum** by [Charm](https://github.com/charmbracelet/gum)
- **Dialog** - Classic TUI utility
- Inspired by various Linux installation wizards
