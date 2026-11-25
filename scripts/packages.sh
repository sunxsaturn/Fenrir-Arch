#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"

# Full Fenrir workstation: Arch packages only. Flatpak applications are installed
# separately from Flathub; Firefox Nightly is installed from Mozilla's own archive.
BASE_PACKAGES=(
    dex wf-recorder
  hyprland hyprpaper hyprlock xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  waybar fuzzel kitty mako grim slurp wl-clipboard cliphist
  networkmanager network-manager-applet bluez bluez-utils blueman
  pipewire pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack wireplumber pavucontrol
  easyeffects qpwgraph guitarix calf
  reaper realtime-privileges
  polkit hyprpolkitagent sddm qt6-wayland qt5-wayland qt6-svg
  xdg-utils xdg-user-dirs gvfs thunar tumbler file-roller
  brightnessctl playerctl libnotify
  mesa vulkan-radeon libva-mesa-driver mesa-utils vulkan-tools vulkan-icd-loader xorg-xwayland
  papirus-icon-theme adwaita-cursors adw-gtk-theme gtk-update-icon-cache
  ttf-jetbrains-mono-nerd inter-font noto-fonts noto-fonts-emoji
  python python-pillow python-gobject gtk4 rsync git curl flatpak ethtool
  discord prismlauncher jre21-openjdk
)
AI_PACKAGES=(ollama-vulkan)
GAMING_PACKAGES=(
  steam gamemode lib32-gamemode mangohud lib32-mangohud gamescope
  lib32-mesa lib32-vulkan-radeon lib32-vulkan-icd-loader
)
FLATPAK_APPS=(
  com.spotify.Client
  com.heroicgameslauncher.hgl
  net.rpcs3.RPCS3
  com.ktechpit.whatsie
)

print_plan() {
  local ai="$1" reapack="${2:-1}"
  log "Target: Arch Linux x86_64 / Hyprland 0.57+ / AMD Mesa-RADV"
  log "Desktop, network, Bluetooth, portals and file manager: full base profile"
  log "Gaming: ${GAMING_PACKAGES[*]}"
  log "Audio/production: easyeffects qpwgraph guitarix calf reaper realtime-privileges"
  if (( reapack )); then log "REAPER extension: official Arch Extra reapack package (no AUR)."; fi
  log "Applications: Firefox Nightly (Mozilla archive), Discord, Prism Launcher, Spotify, Heroic, RPCS3 and Whatsie"
  log "Flathub application IDs: ${FLATPAK_APPS[*]}"
  (( ai == 0 )) || log "AI: ollama-vulkan + Sun AI; model downloads remain manual"
  log "System setup: multilib, US International dead-key layout, persistent Ethernet WoL, UUID-based fixed data-disk mounts"
  log "Wallpaper engine: 15-minute rotation, 2560x1440 landscape minimum, 3840x2160 preferred, wallpaper-derived colors"
  log "Wallpaper pack: installer accepts only a validated, rights-cleared manifest with at least 5000 items; no pack is currently bundled"
  log "No AUR helper, no partitioning, no formatting, no game/firmware downloads, no automatic reboot"
}

install_packages() {
  local ai="$1" reapack="${2:-1}"
  local -a packages=("${BASE_PACKAGES[@]}" "${GAMING_PACKAGES[@]}")
  (( ai == 0 )) || packages+=("${AI_PACKAGES[@]}")
  (( reapack == 0 )) || packages+=(reapack)
  log "Installing with pacman -Syu --needed. Review pacman's transaction and REAPER's EULA prompt."
  sudo pacman -Syu --needed "${packages[@]}"
}

install_flatpak_apps() {
  sudo flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  log "Installing requested Flathub applications: ${FLATPAK_APPS[*]}"
  sudo flatpak install --system --assumeyes flathub "${FLATPAK_APPS[@]}"
}
