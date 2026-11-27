#!/usr/bin/env bash
set -Eeuo pipefail

BASE_PACKAGES=(
  hyprland hyprpaper hyprlock xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  waybar fuzzel kitty mako grim slurp wl-clipboard cliphist
  networkmanager network-manager-applet bluez bluez-utils blueman
  pipewire pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack wireplumber
  pavucontrol easyeffects qpwgraph guitarix calf
  reaper reapack realtime-privileges
  polkit hyprpolkitagent sddm qt6-wayland qt5-wayland qt6-svg
  xdg-utils xdg-user-dirs gvfs udisks2 thunar tumbler file-roller
  brightnessctl playerctl libnotify
  mesa vulkan-radeon libva-mesa-driver mesa-utils vulkan-tools vulkan-icd-loader
  xorg-xwayland
  papirus-icon-theme adwaita-cursors adw-gtk-theme gtk-update-icon-cache
  ttf-jetbrains-mono-nerd inter-font noto-fonts noto-fonts-emoji
  python python-pillow python-gobject gtk4 git github-cli curl rsync flatpak ethtool
  firefox
)
GAMING_PACKAGES=(
  steam gamemode lib32-gamemode mangohud lib32-mangohud gamescope
  lib32-mesa lib32-vulkan-radeon lib32-vulkan-icd-loader
)
OLLAMA_PACKAGES=(ollama ollama-vulkan)
FLATPAK_APPS=(
  com.spotify.Client
  com.heroicgameslauncher.hgl
  net.rpcs3.RPCS3
  com.discordapp.Discord
  com.rtosta.zapzap
  org.prismlauncher.PrismLauncher
)

