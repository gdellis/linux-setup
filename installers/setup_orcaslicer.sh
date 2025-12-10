#!/usr/bin/env bash
# setup_orcaslicer.sh - Install OrcaSlicer with colored logging and file logging

set -euo pipefail


VERSION="2.3.1"
BASE_URL="https://github.com/OrcaSlicer/OrcaSlicer/releases/download/${VERSION}"


# ------------------------------------------------------------
# Setup Logging
# ------------------------------------------------------------
# region

APP_NAME=orcaslicer
DL_DIR="${HOME}/Downloads/$APP_NAME"
LOG_DIR="${HOME}/logs/$APP_NAME"
LOG_FILE="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure directories exist
mkdir -p "$DL_DIR"
mkdir -p "$LOG_DIR"

# Logging functions with color and file output
log()
{
    local msg
    msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo -e "$msg" | tee -a "$LOG_FILE"
}

log_info() { log "${GREEN}[INFO]${NC} $*";}
log_error() { log "${RED}[ERROR]${NC} $*";}
log_success() { log "${GREEN}[SUCCESS]${NC} $*";}
log_warning() { log "${YELLOW}[WARNING]${NC} $*";}

log_info "=== $APP_NAME Installer Started ==="
log_info "Log file: $LOG_FILE"
# endregion

# Download file with error checking
dl_file() {
  local url="$1"
  local dest_dir="${2:-$DL_DIR}"
  local filename
  filename="$(basename "$url")"
  local output_path="${dest_dir}/${filename}"
  
  log_info "Downloading: $filename"
  
  if wget -q --show-progress "$url" -O "$output_path" 2>&1 | tee -a "$LOG_FILE" >/dev/null; then
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