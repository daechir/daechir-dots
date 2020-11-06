#!/bin/bash
# Print commands before executing and exit when any command fails
set -xe


prepare_config(){
  local bleachbit_hash=$(cat /dev/urandom | tr -dc "a-zA-Z0-9" | fold -w 128 | head -n 1)
  local username=$(whoami)

  # Make files hidden
  for file in tilde/*
  do
    mv "${file}" "tilde/.${file##*/}"
  done

  for file in bashsource/*
  do
    mv "${file}" "bashsource/.${file##*/}"
  done

  # Configure config variables
  sed -i "s/^hashsalt =/hashsalt = ${bleachbit_hash}/g" config/bleachbit/bleachbit.ini
  sed -i "s/USERNAME/${username}/g" config/bleachbit/bleachbit.ini
  sed -i "s/USERNAME/${username}/g" config/deluge/core.conf
}


install_config(){
  local wallfile="Nier-automata-minified.zip"
  local walldir="Nier-automata-minified"

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
  cp firefox/userjs/user.js ~/.mozilla/firefox/"$(ls ~/.mozilla/firefox | grep default-release)"
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
install_extra_config

