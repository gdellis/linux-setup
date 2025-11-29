#!/usr/bin/env bash
# ------------------------------------------------------------
# region Script Setup
# ------------------------------------------------------------
# Uncomment for verbose debugging
# set -x 

# ------------------------------------------------------------
# Setup Directory Variables
# ------------------------------------------------------------
# region
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# ------------------------------------------------------------
# region Determine top‑level directory
# ------------------------------------------------------------
# 1️⃣ Prefer Git if we are inside a repo
TOP="$(git rev-parse --show-toplevel 2>/dev/null)"

# 2️⃣ If not a Git repo, look for a known marker (e.g., .topdir)
if [[ -z "$TOP" ]]; then
  # Resolve the directory where this script resides
  SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

  # Walk upward until we find .topdir or stop at /
  DIR="$SCRIPT_DIR"
  while [[ "$DIR" != "/" ]]; do
    if [[ -f "$DIR/.topdir" ]]; then
      TOP="$DIR"
      break
    fi
    DIR="$(dirname "$DIR")"
  done
fi

# 3️⃣ Give up with a clear error if we still have no root
if [[ -z "$TOP" ]]; then
  echo -e "❌  Unable to locate project root. Ensure you are inside a Git repo or that a .topdir file exists."
  exit 1
fi

export TOP
echo -e "(setup_bash.sh) Project root resolved to: $TOP"
# ------------------------------------------------------------
# endregion
# ------------------------------------------------------------

# ------------------------------------------------------------
# region Setup Logger
# ------------------------------------------------------------
LIB_DIR="$TOP/lib"

# Source Logger
source "$LIB_DIR/logging.sh" || exit 1
# ------------------------------------------------------------
# endregion
# ------------------------------------------------------------

# ------------------------------------------------------------
# endregion
# ------------------------------------------------------------

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

DL_DIR="$TOP/downloads"

test -d "$DL_DIR" || mkdir -p "$DL_DIR"

pushdir()
{
  log_info "Push Dir to $1"
  pushd $1 >/dev/null || ( log_error "Failure to pushd to '$1'"; return 1 )
  return 0
}

popdir()
{
  popd $@ >/dev/null || ( log_error "Failure to popd"; return 1 )
}

dl_file()
{
    local _url="$1"
    local _dst="${2:-$DL_DIR}"
    local _filename="$(basename "$_url")"
    pushdir "$_dst"
    log_info "Downloading File: '$_filename'"
    if wget "$_url" -o "$_filename"; then
      log_info "Successfully downloaded file '$_filename'"
    else
      log_error "Failed to download file '$_filename'"
      popdir
      return 1
    fi
    popdir
    return $?
}


# Install Flatpak
install_flatpak()
{
  # Download the Flatpak file
  dl_file "$FLATPACK_URL" "$DL_DIR"

  log_info "Installing Orca Slicer Flatpak"
  local _flatpak_file
  _filename="$DL_DIR/$(basename "$FLATPACK_URL")"

  if [[ ! -f "$_flatpak_file" ]]; then
    handle_error "Flatpak file not found: $_flatpak_file"
  fi

  if ! flatpak install --user "$_flatpak_file" -y; then
    handle_error "Failed to install OrcaSlicer Flatpak"
  fi

  log_info "OrcaSlicer Flatpak installed successfully"
}


Appimage()
{
  log_info "Installing Orca Slicer Appimage"
  dl_file "$APPIMAGE_URL"
  
  cd_origin
}

build_docker()
{
  log_info "Building Orca Slicer with docker"
  pushdir "$DL_DIR"

  #  using Docker
  log_info "Cloning Source"
  git clone https://github.com/OrcaSlicer/OrcaSlicer \
  && pushdir "OrcaSlicer" || ( log_error "pushd Failure"; popdir ; return 1 )
  ./scripts/DockerBuild.sh || ( log_error "Failed 'DockerBuild.sh' failed"; popdir -N 2; exit 1 )
  ./scripts/DockerRun.sh || ( log_error "Failed 'DockerRun.sh' failed"; popdir -N 2; exit 1 )

  log_info "Build Success"
  popdir -N 2
}

build_linux()
{
  log_info "Building Orca Slicer"
  pushdir "$DL_DIR"

  #  using Docker
  log_info "Cloning Source"
  
  git clone https://github.com/OrcaSlicer/OrcaSlicer \
  && pushdir "OrcaSlicer" || ( log_error "pushd Failure"; popdir ; return 1 )
  
  log_info "Running 'build_linux.sh -dsti'"
  
  ./build_linux.sh -dsti || ( log_error "Build Error"; popdir -N 2 ; exit 1 )

  popdir -N 2
}