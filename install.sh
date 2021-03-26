#!/bin/bash

. distro.sh
. packages.sh
. helpers.sh

_update system

# Install packages in the official repositories
echo_info "Installing core packages..."
_install core

# Install packages in the AUR
echo_info "Installing aur packages..."
_install aur

#TODO: xdg-mime default XXX XXX

