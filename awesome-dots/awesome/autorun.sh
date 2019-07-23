#!/usr/bin/env bash

function run {
  if ! pgrep $1 ;
  then
    $@&
  fi
}
run google-chrome
run termite
run compton
run nm-applet
run pamac-tray
run /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
