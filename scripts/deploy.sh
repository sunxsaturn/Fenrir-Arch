#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"
ARCH_ROOT="${ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)}"
DOTS_ROOT="${DOTS_ROOT:?DOTS_ROOT must point to the Fenrir-Dots checkout}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="$HOME/.local/state/fenrir/backups/$STAMP"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL_BIN="$HOME/.local/bin"

backup_path() {
  local source_path="$1" rel="$2"
  [[ -e "$source_path" || -L "$source_path" ]] || return 0
  mkdir -p "$BACKUP_ROOT/$(dirname -- "$rel")"
  cp -a -- "$source_path" "$BACKUP_ROOT/$rel"
  log "Backed up $source_path -> $BACKUP_ROOT/$rel"
}

backup_and_deploy() {
  local ai="${1:-1}"
  mkdir -p "$HOME/.local/state/fenrir" "$LOCAL_BIN" "$CONFIG_HOME" "$HOME/Pictures/Wallpapers"
  local dir
  for dir in hypr waybar fuzzel kitty mako gtk-3.0 gtk-4.0; do
    backup_path "$CONFIG_HOME/$dir" ".config/$dir"
    mkdir -p "$CONFIG_HOME/$dir"
    cp -a "$DOTS_ROOT/config/$dir/." "$CONFIG_HOME/$dir/"
  done

  backup_path "$HOME/.local/share/icons/Fenrir-Obsidian" ".local/share/icons/Fenrir-Obsidian"
  mkdir -p "$HOME/.local/share/icons"
  cp -a "$DOTS_ROOT/config/icons/Fenrir-Obsidian" "$HOME/.local/share/icons/"

  local file
  for file in "$DOTS_ROOT"/bin/*; do
    [[ -f "$file" ]] || continue
    if [[ "$ai" == "0" && "$(basename "$file")" == "sun-ai" ]]; then continue; fi
    backup_path "$LOCAL_BIN/$(basename "$file")" ".local/bin/$(basename "$file")"
    install -m 0755 "$file" "$LOCAL_BIN/$(basename "$file")"
  done
  if [[ "$ai" == "0" ]]; then
    # Do not leave a dead Super+A keybind when the optional Sun AI module is omitted.
    sed -i '/sun-ai open/d' "$CONFIG_HOME/hypr/hyprland.lua"
  fi

  # Deploy the application source trees used by the small command launchers.
  # Without these payloads fenrir-settings/fenrir-welcome/fenrir-monitor would
  # exist on PATH but fail at startup.
  local app
  for app in fenrir-settings fenrir-welcome; do
    [[ -d "$DOTS_ROOT/apps/$app" ]] || die "Required Fenrir app source is missing: $DOTS_ROOT/apps/$app"
    backup_path "$HOME/.local/share/fenrir/apps/$app" ".local/share/fenrir/apps/$app"
    mkdir -p "$HOME/.local/share/fenrir/apps/$app"
    cp -a "$DOTS_ROOT/apps/$app/." "$HOME/.local/share/fenrir/apps/$app/"
  done

  backup_path "$HOME/.config/systemd/user/fenrir-wallpaper.service" ".config/systemd/user/fenrir-wallpaper.service"
  backup_path "$HOME/.config/systemd/user/fenrir-stay-awake.service" ".config/systemd/user/fenrir-stay-awake.service"
  mkdir -p "$HOME/.config/systemd/user" "$HOME/.local/share/applications" "$HOME/.config/autostart"
  install -m 0644 "$DOTS_ROOT/systemd/user/fenrir-wallpaper.service" "$HOME/.config/systemd/user/fenrir-wallpaper.service"
  install -m 0644 "$DOTS_ROOT/systemd/user/fenrir-stay-awake.service" "$HOME/.config/systemd/user/fenrir-stay-awake.service"

  backup_path "$HOME/.local/share/applications/fenrir-control-center.desktop" ".local/share/applications/fenrir-control-center.desktop"
  install -m 0644 "$DOTS_ROOT/applications/fenrir-control-center.desktop" "$HOME/.local/share/applications/fenrir-control-center.desktop"
  backup_path "$HOME/.local/share/applications/fenrir-welcome.desktop" ".local/share/applications/fenrir-welcome.desktop"
  install -m 0644 "$DOTS_ROOT/applications/fenrir-welcome.desktop" "$HOME/.local/share/applications/fenrir-welcome.desktop"

  backup_path "$HOME/.local/share/applications/fenrir-wallpaper-next.desktop" ".local/share/applications/fenrir-wallpaper-next.desktop"
  install -m 0644 "$DOTS_ROOT/applications/fenrir-wallpaper-next.desktop" "$HOME/.local/share/applications/fenrir-wallpaper-next.desktop"
  if [[ "$ai" != "0" ]]; then
    backup_path "$HOME/.local/share/applications/sun-ai.desktop" ".local/share/applications/sun-ai.desktop"
    install -m 0644 "$DOTS_ROOT/applications/sun-ai.desktop" "$HOME/.local/share/applications/sun-ai.desktop"
  fi
  mkdir -p "$HOME/.config/fenrir"
  backup_path "$HOME/.config/fenrir/settings.toml" ".config/fenrir/settings.toml"
  backup_path "$HOME/.config/fenrir/palette.json" ".config/fenrir/palette.json"
  python3 "$DOTS_ROOT/scripts/update-settings.py" \
    "$HOME/.config/fenrir/settings.toml" "$DOTS_ROOT/config/fenrir-settings.toml"

  gtk-update-icon-cache -f -t "$HOME/.local/share/icons/Fenrir-Obsidian" >/dev/null 2>&1 || true
  log "User configuration deployed. Backup location: $BACKUP_ROOT"
}

install_sun_ai() {
  local ai="$1"
  (( ai == 0 )) && { log "Sun AI deployment skipped (--no-ai)."; return 0; }
  local destination="$HOME/.local/share/sun-ai"
  backup_path "$destination" ".local/share/sun-ai"
  mkdir -p "$destination/assets" "$HOME/.local/state/sun-ai" "$HOME/.config/sun-ai"
  chmod 0700 "$HOME/.local/state/sun-ai" "$HOME/.config/sun-ai"
  cp -a "$DOTS_ROOT/apps/sun-ai/." "$destination/"
  backup_path "$HOME/.config/systemd/user/sun-ai.service" ".config/systemd/user/sun-ai.service"
  install -m 0644 "$DOTS_ROOT/systemd/user/sun-ai.service" "$HOME/.config/systemd/user/sun-ai.service"
  log "Sun AI local application installed under $destination"
}

install_user_units() {
  systemctl --user daemon-reload
  systemctl --user enable fenrir-wallpaper.service fenrir-stay-awake.service
  # Keep-awake starts with graphical-session.target; Sun AI remains on-demand.
  systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null || true
}

configure_system_services() {
  local ai="$1" wol="${2:-1}"
  sudo systemctl enable --now NetworkManager.service bluetooth.service
  # The package transaction includes official Arch audio, gaming and desktop apps.
  # Flathub applications are installed separately by install.sh.
  sudo localectl set-x11-keymap us pc105 intl
  if getent group realtime >/dev/null; then
    sudo usermod -aG realtime "$USER"
  fi
  if (( wol )); then
    sudo install -d -m 0755 /usr/local/libexec
    sudo install -m 0755 "$ARCH_ROOT/scripts/fenrir-enable-wol" /usr/local/libexec/fenrir-enable-wol
    if [[ -e /etc/systemd/system/fenrir-wol.service ]]; then
      sudo cp -a /etc/systemd/system/fenrir-wol.service "/etc/systemd/system/fenrir-wol.service.fenrir-backup-$(date +%Y%m%d-%H%M%S)"
    fi
    sudo install -m 0644 "$ARCH_ROOT/systemd/system/fenrir-wol.service" /etc/systemd/system/fenrir-wol.service
    sudo systemctl daemon-reload
    sudo systemctl enable --now fenrir-wol.service
  fi
  # Do not disable or replace an existing display manager.
  local other_dm=0
  for unit in gdm.service lightdm.service greetd.service ly.service; do
    if systemctl is-enabled --quiet "$unit" 2>/dev/null; then other_dm=1; fi
  done
  if (( other_dm == 0 )); then
    sudo systemctl enable sddm.service
  else
    log "Another display manager is enabled; SDDM was not enabled. Resolve this manually after verifying your login path."
  fi
  if (( ai )); then
    if getent group render >/dev/null && id ollama >/dev/null 2>&1; then
      sudo usermod -aG render ollama
    fi
    if getent group video >/dev/null && id ollama >/dev/null 2>&1; then
      sudo usermod -aG video ollama
    fi
    # Ollama remains manual-start: do not let local inference compete with gaming/audio at login.
    sudo systemctl stop ollama.service 2>/dev/null || true
    sudo systemctl disable ollama.service 2>/dev/null || true
  fi
}

validate_install() {
  local ai="$1" reapack="${2:-1}"
  local required=(hyprland hyprpaper hyprlock waybar fuzzel kitty pipewire pipewire-pulse pipewire-jack steam gamemode lib32-gamemode mangohud lib32-mangohud gamescope lib32-mesa lib32-vulkan-radeon lib32-vulkan-icd-loader easyeffects qpwgraph guitarix calf reaper realtime-privileges discord prismlauncher jre21-openjdk)
  local p
  for p in "${required[@]}"; do pacman -Q "$p" >/dev/null 2>&1 || die "Validation failed: package $p is not installed."; done
  [[ -x "$HOME/.local/bin/fenrir-wallpaper" ]] || die "Fenrir wallpaper command missing."
  [[ -f "$HOME/.local/share/fenrir/apps/fenrir-settings/app.py" ]] || die "Fenrir Settings app source was not deployed."
  [[ -f "$HOME/.local/share/fenrir/apps/fenrir-settings/core.py" ]] || die "Fenrir Settings core was not deployed."
  [[ -f "$HOME/.local/share/fenrir/apps/fenrir-welcome/app.py" ]] || die "Fenrir Welcome app source was not deployed."
  [[ -f "$HOME/.local/share/fenrir/apps/fenrir-settings/monitor.py" ]] || die "Fenrir monitor helper was not deployed."
  [[ -f "$CONFIG_HOME/hypr/hyprland.lua" ]] || die "Hyprland Lua configuration missing."
  [[ -x "$HOME/.local/bin/firefox-nightly" ]] || die "Mozilla Firefox Nightly launcher missing."
  local flatpak_apps
  flatpak_apps="$(flatpak list --system --app --columns=application 2>/dev/null || true)"
  for p in com.spotify.Client com.heroicgameslauncher.hgl net.rpcs3.RPCS3 com.ktechpit.whatsie; do
    grep -Fxq "$p" <<<"$flatpak_apps" || die "Validation failed: Flatpak $p is not installed."
  done
  if (( reapack )); then
    pacman -Q reapack >/dev/null 2>&1 || die "Official Arch ReaPack package is missing."
  fi
  if (( ai )); then
    pacman -Q ollama-vulkan >/dev/null 2>&1 || die "Ollama Vulkan package is missing."
    [[ -x "$HOME/.local/bin/sun-ai" ]] || die "Sun AI CLI launcher is missing."
    [[ -f "$HOME/.local/share/sun-ai/server.py" ]] || die "Sun AI server source is missing."
    [[ -f "$HOME/.local/share/sun-ai/index.html" ]] || die "Sun AI dashboard HTML is missing."
    [[ -f "$HOME/.local/share/sun-ai/assets/app.js" ]] || die "Sun AI dashboard JavaScript is missing."
    [[ -f "$HOME/.local/share/sun-ai/assets/style.css" ]] || die "Sun AI dashboard stylesheet is missing."
    [[ -f "$HOME/.config/systemd/user/sun-ai.service" ]] || die "Sun AI user service is missing."
    [[ -f "$HOME/.local/share/applications/sun-ai.desktop" ]] || die "Sun AI desktop launcher is missing."
    [[ -f "$HOME/.local/share/icons/Fenrir-Obsidian/scalable/apps/sun-ai.svg" ]] || die "Sun AI icon is missing."
  fi
  log "Software installation validation passed."
  if command -v fenrir-wallpaper >/dev/null 2>&1; then
    fenrir-wallpaper status || true
  else
    "$HOME/.local/bin/fenrir-wallpaper" status || true
  fi
}
