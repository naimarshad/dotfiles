#!/bin/bash
# ============================================================
#  ~/.config/hypr/start-hyprland.sh
#  Launch Hyprland from a bare TTY — NO display manager needed
#
#  HOW TO USE:
#  1. Boot your machine → you land on a text login prompt (TTY)
#  2. Log in with your username + password
#  3. This script auto-runs if you add the sourcing block
#     below to your ~/.bash_profile or ~/.zprofile
#
#  Add to ~/.bash_profile:
#  ─────────────────────────────────────────────
#  if [[ -z $WAYLAND_DISPLAY ]] && [[ $(tty) == /dev/tty1 ]]; then
#      exec ~/.config/hypr/start-hyprland.sh
#  fi
#  ─────────────────────────────────────────────
#
#  WHY NO DISPLAY MANAGER:
#  - One less process (SDDM/GDM use 30-60MB RAM doing nothing)
#  - Faster boot (skip DM → greeter → compositor chain)
#  - Simpler to debug (everything in ~/.local/share/hyprland/logs)
#  - Still fully secure (TTY login IS authentication)
#  - Easy to add one later if you change your mind
# ============================================================

# --- Safety: don't launch inside an existing graphical session ---
if [[ -n "$WAYLAND_DISPLAY" || -n "$DISPLAY" ]]; then
    echo "Already in a graphical session. Refusing to start Hyprland."
    exit 1
fi

# --- Session type for portals and apps ---
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland

# --- Set a log directory ---
mkdir -p ~/.local/share/hyprland

# --- Launch ---
# Logs go to ~/.local/share/hyprland/hyprland.log
# If Hyprland crashes, you can read what happened there
exec start-hyprland &>> ~/.local/share/hyprland/hyprland.log

