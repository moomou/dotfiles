#!/bin/sh

# allow key repeats
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# turn off animation
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
# adjust menu item spacing
defaults -currentHost write -globalDomain NSStatusItemSpacing -int 8
