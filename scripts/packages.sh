#!/usr/bin/env bash
set -Eeuo pipefail

BASE_PACKAGES=(
  hyprland hyprpaper hyprlock hypridle
  xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  waybar fuzzel kitty mako grim slurp wl-clipboard cliphist
  networkmanager network-manager-applet bluez bluez-utils blueman
  pipewire pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack wireplumber
  pavucontrol easyeffects qpwgraph guitarix calf
  reaper reapack realtime-privileges
  polkit hyprpolkitagent sddm qt5-wayland qt6-wayland qt6ct qt5ct
  xdg-utils xdg-user-dirs gvfs thunar tumbler file-roller
  brightnessctl playerctl libnotify
  mesa vulkan-radeon libva-mesa-driver mesa-utils vulkan-tools vulkan-icd-loader
  xorg-xwayland
  papirus-icon-theme adwaita-cursors adw-gtk3
  ttf-jetbrains-mono-nerd inter-font noto-fonts noto-fonts-emoji
  python python-pip python-gobject python-pillow gtk4 rsync git curl jq flatpak ethtool
  firefox discord prismlauncher jre21-openjdk
)
GAMING_PACKAGES=(
  steam gamemode lib32-gamemode mangohud lib32-mangohud gamescope
  lib32-mesa lib32-vulkan-radeon lib32-vulkan-icd-loader
)
AI_PACKAGES=(ollama-vulkan)
FLATPAK_APPS=(
  com.spotify.Client
  com.heroicgameslauncher.hgl
  net.rpcs3.RPCS3
  com.ktechpit.whatsie
)

print_plan() {
  local with_ai="$1"
  printf '%s\n' "[Fenrir] Target: Arch Linux x86_64 / Hyprland / systemd."
  printf '%s\n' "[Fenrir] Desktop: Hyprland, Waybar, Fuzzel, Kitty, Mako, SDDM and portals."
  printf '%s\n' "[Fenrir] AMD graphics: Mesa/RADV Vulkan and 32-bit Vulkan."
  printf '%s\n' "[Fenrir] Gaming: Steam, Gamemode, MangoHud and Gamescope."
  printf '%s\n' "[Fenrir] Audio: PipeWire, EasyEffects, QPWgraph, Guitarix, Calf and REAPER."
  printf '%s\n' "[Fenrir] REAPER extension: signed official Arch Extra package ReaPack."
  printf '%s\n' "[Fenrir] Applications: Firefox, Discord, Prism, Spotify, Heroic, RPCS3 and Whatsie."
  if (( with_ai )); then
    printf '%s\n' "[Fenrir] AI: official Arch Extra Ollama Vulkan runtime; model choice is benchmarked after installation."
  fi
  printf '%s\n' "[Fenrir] Network: NetworkManager, Bluetooth and supported wired Wake-on-LAN."
  printf '%s\n' "[Fenrir] Storage: no partition, format, fstab, mount or data-volume operation."
}

install_packages() {
  local with_ai="$1"
  local -a packages=("${BASE_PACKAGES[@]}" "${GAMING_PACKAGES[@]}")
  if (( with_ai )); then packages+=("${AI_PACKAGES[@]}"); fi
  sudo pacman -Syu --needed "${packages[@]}"
}

install_flatpak_apps() {
  sudo flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  sudo flatpak install --system --noninteractive --assumeyes flathub "${FLATPAK_APPS[@]}"
}
