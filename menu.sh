#!/usr/bin/env bash
#
# menu.sh - Interactive Console Menu for Linux Setup
# Description: TUI for running installer scripts with multiple backend support
# Usage: ./menu.sh
#

set -euo pipefail

# Get script directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Source logging library
# shellcheck source=lib/logging.sh
source "$SCRIPT_DIR/lib/logging.sh"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

readonly INSTALLERS_DIR="$SCRIPT_DIR/installers"
readonly BANNER="
╔══════════════════════════════════════╗
║   Linux Setup - Installation Menu   ║
╚══════════════════════════════════════╝
"

# ------------------------------------------------------------
# TUI Backend Detection
# ------------------------------------------------------------

detect_tui_backend() {
    if command -v gum &> /dev/null; then
        echo "gum"
    elif command -v dialog &> /dev/null; then
        echo "dialog"
    elif command -v whiptail &> /dev/null; then
        echo "whiptail"
    else
        echo "bash"
    fi
}

# ------------------------------------------------------------
# Installer Discovery
# ------------------------------------------------------------

get_installers() {
    local -a installers=()

    # Find all setup_*.sh scripts (excluding setup_gum.sh as meta)
    while IFS= read -r -d '' script; do
        local name
        name=$(basename "$script" .sh)
        name=${name/setup_/}

        # Skip special scripts
        if [[ "$name" == "gum" || "$name" == "new_installer" ]]; then
            continue
        fi

        # Extract description from file header
        local description
        description=$(grep "^# Description:" "$script" | sed 's/^# Description: //' || echo "No description")

        installers+=("$name|$description|$script")
    done < <(find "$INSTALLERS_DIR" -name "setup_*.sh" -type f -print0 | sort -z)

    printf '%s\n' "${installers[@]}"
}

# ------------------------------------------------------------
# GUM Backend
# ------------------------------------------------------------

show_menu_gum() {
    local -a installers
    mapfile -t installers < <(get_installers)

    while true; do
        # Clear screen and show banner
        clear
        gum style \
            --foreground 212 \
            --border-foreground 212 \
            --border double \
            --align center \
            --width 50 \
            --margin "1 2" \
            --padding "1 4" \
            "Linux Setup" "Installation Menu"

        echo

        # Build menu options
        local -a options=()
        local -a scripts=()

        for installer in "${installers[@]}"; do
            IFS='|' read -r name desc script <<< "$installer"
            options+=("$name")
            options+=("  $desc")
            scripts+=("$script")
        done

        # Add system options
        options+=("install-gum")
        options+=("  Install/Update Gum TUI tool")
        scripts+=("$INSTALLERS_DIR/setup_gum.sh")

        options+=("exit")
        options+=("  Exit menu")
        scripts+=("")

        # Show menu
        local choice
        if ! choice=$(gum choose --height 20 --header "Select an installer:" "${options[@]}"); then
            log_info "User cancelled"
            exit 0
        fi

        # Handle selection
        case "$choice" in
            exit)
                gum style --foreground 212 "Goodbye!"
                exit 0
                ;;
            *)
                # Extract the name (first word)
                local selected_name
                selected_name=$(echo "$choice" | awk '{print $1}')

                # Find the corresponding script
                local idx=0
                local found=false
                for opt in "${options[@]}"; do
                    if [[ "$opt" == "$selected_name" || "$opt" == "  $selected_name" ]]; then
                        local script_idx=$((idx / 2))
                        local script_path="${scripts[$script_idx]}"

                        if [[ -n "$script_path" && -f "$script_path" ]]; then
                            gum style --foreground 212 "Running: $selected_name"
                            echo
                            bash "$script_path"
                            echo
                            gum style --foreground 212 "Press any key to continue..."
                            read -n 1 -s -r
                            found=true
                            break
                        fi
                    fi
                    ((idx++))
                done

                if [[ "$found" == "false" ]]; then
                    gum style --foreground 196 "Error: Script not found"
                    sleep 2
                fi
                ;;
        esac
    done
}

# ------------------------------------------------------------
# Simple Bash Backend
# ------------------------------------------------------------

show_menu_bash() {
    local -a installers
    mapfile -t installers < <(get_installers)

    while true; do
        clear
        echo "$BANNER"
        echo

        # Show installers
        local idx=1
        local -a scripts=()

        for installer in "${installers[@]}"; do
            IFS='|' read -r name desc script <<< "$installer"
            echo "  $idx) $name"
            echo "     $desc"
            echo
            scripts+=("$script")
            ((idx++))
        done

        # System options
        echo "  $idx) Install/Update Gum TUI (Recommended)"
        scripts+=("$INSTALLERS_DIR/setup_gum.sh")
        local gum_idx=$idx
        ((idx++))

        echo "  $idx) Exit"
        echo

        # Get selection
        read -rp "Select an option (1-$idx): " selection

        # Validate input
        if ! [[ "$selection" =~ ^[0-9]+$ ]]; then
            log_error "Invalid input. Please enter a number."
            sleep 2
            continue
        fi

        # Handle selection
        if ((selection == idx)); then
            log_info "Exiting..."
            exit 0
        elif ((selection == gum_idx)); then
            bash "$INSTALLERS_DIR/setup_gum.sh"
            echo
            read -rp "Press Enter to continue..."
        elif ((selection >= 1 && selection < gum_idx)); then
            local script_idx=$((selection - 1))
            local script_path="${scripts[$script_idx]}"

            if [[ -f "$script_path" ]]; then
                bash "$script_path"
                echo
                read -rp "Press Enter to continue..."
            else
                log_error "Script not found"
                sleep 2
            fi
        else
            log_error "Invalid selection"
            sleep 2
        fi
    done
}

# ------------------------------------------------------------
# Dialog Backend
# ------------------------------------------------------------

show_menu_dialog() {
    local -a installers
    mapfile -t installers < <(get_installers)

    local DIALOG_CMD="dialog"
    if command -v whiptail &> /dev/null && ! command -v dialog &> /dev/null; then
        DIALOG_CMD="whiptail"
    fi

    while true; do
        # Build menu options
        local -a menu_options=()
        local -a scripts=()

        local idx=1
        for installer in "${installers[@]}"; do
            IFS='|' read -r name desc script <<< "$installer"
            menu_options+=("$idx" "$name - $desc")
            scripts+=("$script")
            ((idx++))
        done

        # System options
        menu_options+=("$idx" "Install/Update Gum TUI (Recommended)")
        scripts+=("$INSTALLERS_DIR/setup_gum.sh")
        local gum_idx=$idx
        ((idx++))

        menu_options+=("$idx" "Exit")

        # Show menu
        local choice
        if ! choice=$($DIALOG_CMD --clear --title "Linux Setup" \
            --menu "Select an installer:" 20 70 12 \
            "${menu_options[@]}" \
            3>&1 1>&2 2>&3); then
            clear
            log_info "User cancelled"
            exit 0
        fi

        clear

        # Handle selection
        if ((choice == idx)); then
            log_info "Exiting..."
            exit 0
        elif ((choice == gum_idx)); then
            bash "$INSTALLERS_DIR/setup_gum.sh"
            echo
            read -rp "Press Enter to continue..."
        elif ((choice >= 1 && choice < gum_idx)); then
            local script_idx=$((choice - 1))
            local script_path="${scripts[$script_idx]}"

            if [[ -f "$script_path" ]]; then
                bash "$script_path"
                echo
                read -rp "Press Enter to continue..."
            else
                log_error "Script not found"
                sleep 2
            fi
        fi
    done
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

main() {
    log_info "Starting Linux Setup Menu..."

    # Detect TUI backend
    local backend
    backend=$(detect_tui_backend)

    log_info "Using TUI backend: $backend"

    case "$backend" in
        gum)
            show_menu_gum
            ;;
        dialog|whiptail)
            show_menu_dialog
            ;;
        bash)
            log_warning "No TUI tool found. Using simple bash menu."
            echo "Tip: Install 'gum' for a better experience: ./installers/setup_gum.sh"
            sleep 2
            show_menu_bash
            ;;
        *)
            log_error "Unknown TUI backend: $backend"
            exit 1
            ;;
    esac
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
