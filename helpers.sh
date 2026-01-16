#!/bin/bash

function echo_error() {
  printf '\n\033[31mERROR:\033[0m %s\n' "$1"
}

function echo_warning() {
  printf '\n\033[33mWARNING:\033[0m %s\n' "$1"
}

function echo_done() {
  printf '\n\033[32mDONE:\033[0m %s\n' "$1"
}

function echo_info() {
  printf '\n\033[36m%s\033[0m\n' "$1"
}

function _update() {
  if [[ $1 == "system" ]]; then
    echo_info "Updating system packages..."
    sudo "$PKGMN" "$PKGU" "${PKGOPT[@]}"
  else
    echo_info "Updating ${1}..."
    sudo "$PKGMN" "$PKGI" "$1"
  fi
}

# Install package from the offical repoistories
# -----------------------------------------------------------------------------
function _install() {
  [ -f /var/lib/pacman/db.lck ] && rm /var/lib/pacman/db.lck
  if [[ $1 == "core" ]]; then
    for pkg in "${PKG[@]}"; do
      echo_info "Installing ${pkg}..."
      if ! [ -x "$(command -v rainbow)" ]; then
        sudo "$PKGMN" "$PKGI" "$pkg" "${PKGOPT[@]}"
      else
        rainbow --red=error --yellow=warning sudo "$PKGMN" "$PKGI" "$pkg" "${PKGOPT[@]}"
      fi
      echo_done "${pkg} installed!"
    done
  elif [[ $1 == "aur" ]]; then
    for aur in "${AUR[@]}"; do
      echo_info "Installing ${aur}..."
      yay -S "$aur" --needed --noconfirm
      echo_done "${aur} installed!"
    done
  else
    echo_info "Intalling ${1}..."
    sudo "$PKGMN" "$PKGI" "$1"
  fi
}

# Remove package
# -----------------------------------------------------------------------------
function _uninstall() {
  [ -f /var/lib/pacman/db.lck ] && rm /var/lib/pacman/db.lck
  # pacman -Rnsc --noconfirm $@
  if [[ $1 == "core" ]]; then
    for pkg in "${PKG[@]}"; do
      echo_info "Uninstalling ${pkg}..."
      sudo "$PKGMN" "$PKGR" "$pkg" --noconfirm
      echo_done "${pkg} uninstalled!"
    done
  elif [[ $1 == "aur" ]]; then
    for aur in "${AUR[@]}"; do
      echo_info "Uninstalling ${aur}..."
      yay "$PKGR" "$aur" --noconfirm
      echo_done "${aur} uninstalled!"
    done
  else
    echo_info "Uninstalling ${1}..."
    sudo "$PKGMN" "$PKGR" "$1"
  fi
}
