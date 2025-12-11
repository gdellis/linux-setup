#!/usr/bin/env bash
# setup_orcaslicer.sh - Install OrcaSlicer with colored logging and file logging

set -euo pipefail

# Get script directory and source logging library
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# shellcheck source=../lib/logging.sh
source "$SCRIPT_DIR/../lib/logging.sh"

readonly VERSION="2.3.1"
readonly BASE_URL="https://github.com/OrcaSlicer/OrcaSlicer/releases/download/${VERSION}"

# ------------------------------------------------------------
# Setup Logging
# ------------------------------------------------------------
# region

readonly APP_NAME=orcaslicer
readonly DL_DIR="${HOME}/downloads/$APP_NAME"
readonly LOG_DIR="${HOME}/logs/$APP_NAME"
readonly LOG_FILE="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"

# Ensure directories exist
mkdir -p "$DL_DIR"
mkdir -p "$LOG_DIR"

log_info "=== $APP_NAME Installer Started ==="
log_info "Log file: $LOG_FILE"
# endregion

# Download file with error checking
# TODO: Add checksum verification once OrcaSlicer provides official checksums
# OrcaSlicer GitHub releases do not currently provide SHA256 checksums
# For manual verification, compute the checksum after download:
#   sha256sum <downloaded_file>
# Then compare with checksum from OrcaSlicer's official communication channels
dl_file() {
  local url="$1"
  local dest_dir="${2:-$DL_DIR}"
  local filename
  filename="$(basename "$url")"
  local output_path="${dest_dir}/${filename}"

  log_info "Downloading: $filename"

  if wget -q --show-progress "$url" -O "$output_path" 2>&1 | tee -a "$LOG_FILE" >/dev/null; then
    log_warning "Note: Checksum verification not available for OrcaSlicer downloads"
    log_info "For manual verification, run: sha256sum $output_path"
    log_success "Successfully downloaded: $filename"
    echo "$output_path"
  else
    log_error "Failed to download: $filename"
    return 1
  fi
}

# Install Flatpak version
install_flatpak() {
  local flatpak_url="${BASE_URL}/OrcaSlicer-Linux-flatpak_V${VERSION}_x86_64.flatpak"
  local flatpak_file
  
  log_info "Downloading OrcaSlicer Flatpak..."
  flatpak_file=$(dl_file "$flatpak_url") || return 1
  
  log_info "Installing OrcaSlicer Flatpak..."
  flatpak install --user -y "$flatpak_file" 2>&1 | tee -a "$LOG_FILE" || {
    log_error "Flatpak installation failed"
    return 1
  }
  
  log_success "OrcaSlicer Flatpak installed successfully"
}

# Install AppImage version
install_appimage() {
  local appimage_url="${BASE_URL}/OrcaSlicer_Linux_AppImage_Ubuntu2404_V${VERSION}.AppImage"
  local appimage_file
  
  log_info "Downloading OrcaSlicer AppImage..."
  appimage_file=$(dl_file "$appimage_url") || return 1
  
  log_success "AppImage downloaded to: $appimage_file"
  log_warning "Make it executable with: chmod +x $appimage_file"
}

# Build from source with Docker
build_docker() {
  log_info "Building OrcaSlicer from source with Docker..."
  
  local repo_dir="${DL_DIR}/OrcaSlicer"
  
  if [[ ! -d "$repo_dir" ]]; then
    log_info "Cloning repository..."
    git clone https://github.com/OrcaSlicer/OrcaSlicer "$repo_dir" 2>&1 | tee -a "$LOG_FILE" || {
      log_error "Git clone failed"
      return 1
    }
  fi
  
  pushd "$repo_dir" >/dev/null || return 1
  
  log_info "Running DockerBuild.sh..."
  ./scripts/DockerBuild.sh 2>&1 | tee -a "$LOG_FILE" || {
    log_error "DockerBuild.sh failed"
    popd >/dev/null
    return 1
  }
  
  log_info "Running DockerRun.sh..."
  ./scripts/DockerRun.sh 2>&1 | tee -a "$LOG_FILE" || {
    log_error "DockerRun.sh failed"
    popd >/dev/null
    return 1
  }
  
  popd >/dev/null
  log_success "Docker build completed"
}

# Build from source on Linux
build_linux() {
  log_info "Building OrcaSlicer from source on Linux..."
  
  local repo_dir="${DL_DIR}/OrcaSlicer"
  
  if [[ ! -d "$repo_dir" ]]; then
    log_info "Cloning repository..."
    git clone https://github.com/OrcaSlicer/OrcaSlicer "$repo_dir" 2>&1 | tee -a "$LOG_FILE" || {
      log_error "Git clone failed"
      return 1
    }
  fi
  
  pushd "$repo_dir" >/dev/null || return 1
  
  log_info "Running build_linux.sh -dsti..."
  ./build_linux.sh -dsti 2>&1 | tee -a "$LOG_FILE" || {
    log_error "Build failed"
    popd >/dev/null
    return 1
  }
  
  popd >/dev/null
  log_success "Linux build completed"
}

# Main installation menu
main() {
  case "${1:-}" in
    flatpak)
      install_flatpak
      ;;
    appimage)
      install_appimage
      ;;
    docker)
      build_docker
      ;;
    linux)
      build_linux
      ;;
    *)
      cat << EOF
Usage: $0 {flatpak|appimage|docker|linux}

Installation methods:
  flatpak - Install Flatpak version
  appimage - Download AppImage
  docker   - Build from source with Docker
  linux    - Build from source on Linux

Logs are saved to: $LOG_DIR
EOF
      exit 1
      ;;
  esac
  
  log_success "=== Installation completed successfully ==="
}

main "$@"