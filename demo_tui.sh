#!/usr/bin/env bash
#
# demo_tui.sh - Demo script showing TUI capabilities
# Description: Demonstrates what the TUI looks like and feels like
# Usage: ./demo_tui.sh
#

set -euo pipefail

# Check if gum is installed
if ! command -v gum &> /dev/null; then
    echo "This demo requires 'gum' to be installed."
    echo "Would you like to install it now?"
    read -rp "[Y/n]: " answer
    if [[ "$answer" =~ ^[Yy]?$ ]]; then
        ./installers/setup_gum.sh
        echo
        echo "Gum installed! Re-run this demo:"
        echo "  ./demo_tui.sh"
        exit 0
    else
        echo "Demo cancelled. Install gum with: ./installers/setup_gum.sh"
        exit 1
    fi
fi

clear

# Title
gum style \
    --foreground 212 \
    --border-foreground 212 \
    --border double \
    --align center \
    --width 60 \
    --margin "1 2" \
    --padding "1 4" \
    "Linux Setup TUI Demo" \
    "" \
    "This demonstrates the interactive menu capabilities"

echo

# Show some features
gum style --foreground 212 "Feature Demonstrations:"
echo

# 1. Choice menu
echo "1. Choice Menu (what you see in menu.sh):"
choice=$(gum choose "Installer 1" "Installer 2" "Installer 3" "Exit")
gum style --foreground 46 "✓ You selected: $choice"
echo

# 2. Confirmation
echo "2. Confirmation Prompts:"
if gum confirm "Would you like to continue?"; then
    gum style --foreground 46 "✓ User confirmed"
else
    gum style --foreground 196 "✗ User declined"
fi
echo

# 3. Input
echo "3. Text Input:"
name=$(gum input --placeholder "Enter your name...")
gum style --foreground 46 "✓ Hello, $name!"
echo

# 4. Styled output
echo "4. Styled Messages:"
gum style --foreground 212 --bold "Important message"
gum style --foreground 46 "Success message"
gum style --foreground 196 "Error message"
gum style --foreground 226 "Warning message"
echo

# 5. Spinner (simulated task)
echo "5. Progress Indicators:"
gum spin --spinner dot --title "Installing package..." -- sleep 2
gum style --foreground 46 "✓ Installation complete!"
echo

# 6. Multi-select
echo "6. Multi-Select (choose multiple):"
selected=$(gum choose --no-limit "Option A" "Option B" "Option C" "Option D")
if [[ -n "$selected" ]]; then
    gum style --foreground 46 "✓ You selected:"
    echo "$selected" | while read -r item; do
        echo "  - $item"
    done
else
    gum style --foreground 226 "⚠ No selections made"
fi
echo

# Final message
gum style \
    --foreground 212 \
    --border-foreground 212 \
    --border rounded \
    --align center \
    --width 60 \
    --padding "1 4" \
    "Demo Complete!" \
    "" \
    "Run './menu.sh' to use the actual installer menu" \
    "See TUI_GUIDE.md for more information"

echo
gum style --foreground 212 "Press Enter to exit..."
read -r
