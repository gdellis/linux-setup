#!/usr/bin/env bash
set -e
# set -x
# Source logging functions
source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

BASH_CFG_DEST=~/.config
BASH_FILES=(
    ".bashrc"
    ".bash_aliases"
)

## Functions
cleanup()
{
    _code=$?

    log_info "Cleaning up.."

    # pop stack if needed
    [ $(dirs -p | wc -l) -gt 0 ] && popd -0
    log_info "$0 is finished"
}

# Error handling function
handle_error()
{
    local _msg="$1"
    log_error "$_msg"
    exit 1
}

create_link()
{
    local _file="$1"
    local _dest="${2:-$BASH_CFG_DEST}"
    local _target="$_dest/bash/$_file"
    log_info "Creating Symbolic link..."
    log_info "Target: '$_target'"
    log_info "Link Name: '$HOME/$_file'"
    pushd "$HOME" >/dev/null
    if [ -f "$HOME/$_file" ] ;then
        
        if [ -L "$HOME/$_file" ];then
            log_warn "Removing Link '$HOME/$_file'"
            rm "$HOME/$_file"
        fi    

        ln -s "$_target"
    fi
    popd >/dev/null
}

backup_file()
{   
    
    local _backup_dir="$1"
    local _file="$2"
    local _backup_file="$_backup_dir/${_file##*/}.bak"

    if [ -f "$_file" ];then

        if [ -L "$_file" ] ;then
            log_warn "Removing previous symbolic link '$_file'"
            rm "$_file"
            return 0
        fi

        log_info "Backing up '$_file' to '$_backup_file'"
        mv "$_file" "$_backup_file"
    fi
}

## Get Dependancies
# region
dl_starship()
{
    # Check if already installed
    if which starship;then
        log_warn "Starship Prompt is already installed, Skipping"
        return 0
    fi
    # Download starship prompt
    log_info "Downloading the starship prompt application"
    curl -sS https://starship.rs/install.sh | sh

    # Install Nerd Fonts

}

# endregion



## Backup Current Setup
log_info "Backing up current files..."

TIMESTAMP=$(date '+%Y-%m-%d_%H%M%S')
BACKUP_DIR="$SCRIPT_DIR/backups/$TIMESTAMP"

if [ ! -d "$BACKUP_DIR" ]; then
    log_info "Creating directory: '$BACKUP_DIR'"
    mkdir -p "$BACKUP_DIR"
fi

for i in "${BASH_FILES[@]}";do 
    backup_file "$BACKUP_DIR" "$HOME/$i"
done


# Create and copy files to ~/.config/bash
log_info "Creating directory $BASH_CFG_DEST if it doesn't exist"
test -d "$BASH_CFG_DEST" || mkdir -p "$BASH_CFG_DEST"

test "$SCRIPT_DIR" == "$(pwd)" || pushd "$SCRIPT_DIR"

log_info "Copying bash files to $BASH_CFG_DEST"
cp -r "$SCRIPT_DIR/bash" "$BASH_CFG_DEST" || handle_error "Failed to copy bash files"

# Create Symbolic links
for i in "${BASH_FILES[@]}";do
    _target="$BASH_CFG_DEST/bash/$i"
    log_info "Creating Symbolic link..."
    log_info "Target: '$_target'"
    log_info "Link Name: '$HOME/$i'"
    ln -s "$_target" "$HOME/$i"
done

