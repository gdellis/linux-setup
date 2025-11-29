#!/usr/bin/env bash
# set -x

# -----------------------------------
# Setup Directory Variables
# -----------------------------------
# region
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -f "$SCRIPT_DIR/.topdir" ];then
    TOP=$($SCRIPT_DIR)
else
    TOP="$(realpath "$SCRIPT_DIR/..")"
fi

LIB_DIR="$TOP/lib"

# Source Logger
source "$LIB_DIR/logging.sh" || exit 1
# endregion
# -----------------------------------

# Error handling function
handle_error()
{
    local _msg="$1"
    echo -e "[ERROR] $_msg"
    exit 1
}
# Configuration Variables
VERSION="2.3.1"
BASE_URL="https://github.com/OrcaSlicer/OrcaSlicer/releases/download/$VERSION"
FLATPACK_URL="$BASE_URL/OrcaSlicer-Linux-flatpak_V2.3.1_x86_64.flatpak"
APPIMAGE_URL="$BASE_URL/OrcaSlicer_Linux_AppImage_Ubuntu2404_V2.3.1.AppImage"

dl_file()
{
    local _default_dst="$SCRIPT_DIR/downloads"
    local _url="$1"
    local _dst="${2:-$PWD}"
}


# Install Flatpak
install_flatpak()
{
    # Check if flatpak is installed
    if ! command -v flatpak &>/dev/null;then
       echo "Installing Flatpak..."
       sudo apt update && sudo apt install flatpak -
       echo "Flatpak installed successfully."
       echo "Adding Flathub repository..."
       flatpak remote-add --if-not-exists fl
       echo "Flathub added successfully."
       echo "Updating Flatpak cache..."
       flatpak update -y
       echo "Flatpak updated successfully."
       echo "Installing OrcaSlicer..."
       flatpak install fl org.orcaslicer.Orca
       echo "OrcaSlicer installed successfully."
    fi
}


