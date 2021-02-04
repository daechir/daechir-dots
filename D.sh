#!/bin/bash


##########################################
#
# ___  ____ ____ ____ _  _ _ ____ ____ .
# |  \ |__| |___ |    |__| | |__/ [__  '
# |__/ |  | |___ |___ |  | | |  \ ___]
#
#         ___  ____ ___ ____
#         |  \ |  |  |  [__
#         |__/ |__|  |  ___]
#
#
# This file is a part of Daechir Dots.
# It adheres to the GNU GPL license.
#
# https://github.com/daechir/daechir-dots
#
# © 2020-2021
#
#
##########################################


# Print commands before executing and exit when any command fails
set -xe


prepare_config(){
  local bleachbit_hash=$(cat /dev/urandom | tr -dc "a-zA-Z0-9" | fold -w 128 | head -n 1)
  local username=$(whoami)
  local is_intel_cpu=$(lscpu | grep -i "intel(r)" 2> /dev/null || echo "")

  # Configure config files
  sed -i "s/^hashsalt =/hashsalt = ${bleachbit_hash}/g" config/bleachbit/bleachbit.ini
  sed -i "s/USERNAME/${username}/g" config/bleachbit/bleachbit.ini
  sed -i "s/USERNAME/${username}/g" config/deluge/core.conf

  # Configure xinitrc
  if [[ -n "${is_intel_cpu}" ]]; then
    local xinput="/usr/bin/xinput disable \"SynPS/2 Synaptics TouchPad\""
  else
    local xinput="/usr/bin/xinput disable \"ELAN0708:00 04F3:30A0 Touchpad\""
  fi

  sed -i "s/^#xinput/${xinput}/g" tilde/xinitrc

  # Make files hidden
  for file in tilde/*
  do
    mv "${file}" "tilde/.${file##*/}"
  done

  for file in bashsource/*
  do
    mv "${file}" "bashsource/.${file##*/}"
  done
}


install_config(){
  local wallfile="Nier-automata-minified.zip"
  local walldir="${wallfile%.*}"
  local userjsfile="user.js"
  local mozpath="$HOME/.mozilla/firefox"
  local mozfolder=$(ls "${mozpath}" | grep -i "default-release")
  mozpath="${mozpath}/${mozfolder}"

  # Setup files
  cp tilde/.bashrc ~
  cp tilde/.gtkrc-2.0 ~
  cp tilde/.xbindkeysrc ~
  cp tilde/.xinitrc ~
  cp -R bashsource ~/.bashsource
  mkdir ~/Pictures
  cd wallpapers
  unzip "${wallfile}"
  cp -R "${walldir}" ~/Pictures/Wallpapers
  cd ..
  doas rm -rf ~/.config
  cp -R config ~/.config
  doas rm -rf ~/.icons
  cp -R icons ~/.icons
  mkdir ~/.howl
  mkdir ~/.howl/system
  cp howl/system/config.lua ~/.howl/system/

  # Setup null pointers
  # This patches potential data leaks for applications which have poor implementations of stdout & stderr redirection
  rm -f ~/.howl/system/command_line_history.lua
  ln -s /dev/null ~/.howl/system/command_line_history.lua
  rm -f ~/.howl/system/session.lua
  ln -s /dev/null ~/.howl/system/session.lua
  rm -f ~/.local/share/xorg/Xorg.0.log
  ln -s /dev/null ~/.local/share/xorg/Xorg.0.log
  rm -f ~/.local/share/xorg/Xorg-stdout-stderr.log
  ln -s /dev/null ~/.local/share/xorg/Xorg-stdout-stderr.log

  # Setup immutable recently-used.xbel
  # This patches a potential file permission bypass which grants access to the home directory
  rm -f ~/.local/share/recently-used.xbel
  touch ~/.local/share/recently-used.xbel
  doas chattr +i ~/.local/share/recently-used.xbel

  # Start firefox for profile generation then kill it
  firefox
  # Add firefox user.js to the new profile
  cp "firefox/userjs/${userjsfile}" "${mozpath}"
}


install_extra_config(){
  # Setup other gtk settings (dconf)
  gsettings set org.gnome.desktop.wm.preferences theme "Arc"
  gsettings set org.gnome.desktop.wm.preferences titlebar-font "Roboto 11"
  gsettings set org.gnome.desktop.media-handling automount-open false
  gsettings set org.gnome.desktop.media-handling automount false
  gsettings set org.gnome.desktop.privacy recent-files-max-age 0
  gsettings set org.gnome.desktop.privacy remember-app-usage false
  gsettings set org.gnome.desktop.privacy remember-recent-files false
  gsettings set org.gnome.system.location enabled false
  gsettings set org.gnome.system.location max-accuracy-level country
}


prepare_config
install_config
#install_extra_config

