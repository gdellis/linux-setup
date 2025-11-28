#!/usr/bin/env bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

BASH_CFG_DEST=~/.config/bash

BASH_FILES=(
    bashrc
    bash_aliases
)

## Functions
create_link()
{
    local _file="$1"
    local _dest="${2:-$BASH_CFG_DEST}"
    local _target="$_dest/bash/$$_file"
    echo -e "Creating Symbolic link..."
    echo -e "Target: '$_target'"
    echo -e "Link Name: '~/$_file'"
    ln -s "$_target" "~/$_file"
}

## Get Dependancies

## Backup Current Setup
mv ~/.bashrc .bahrc_bak

# Create and copy files to ~/.config/bash
test -d "$BASH_CFG_DEST" || mkdir -p "$BASH_CFG_DEST"
cp $SCRIPT_DIR/bash/* "$BASH_CFG_DEST"

# Create Symbolic links
for i in "${BASH_FILES[@]}";do
    _target="$BASH_CFG_DEST/bash/${i}"
    echo -e "Creating Symbolic link..."
    echo -e "Target: '$_target'"
    echo -e "Link Name: '~/$i'"
    ln -s "$_target" "~/$i"
done



