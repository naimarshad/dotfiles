#!/bin/bash - 
#===============================================================================
#
#          FILE: polkit.sh
# 
#         USAGE: ./polkit.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 01/08/2019 17:26
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

