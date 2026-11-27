#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
source "$ROOT/scripts/lib.sh"
# shellcheck disable=SC1091
source "$ROOT/scripts/packages.sh"

usage(){
  cat <<'EOF'
Fenrir Desktop — complete Arch Linux installer

Usage:
  git clone --depth=1 https://github.com/sunxsaturn/Fenrir-Arch.git ~/Fenrir
  cd ~/Fenrir && ./install.sh

Options:
  --cli           Use terminal mode instead of the GTK4 guided installer
  --dry-run       Show the plan only; make no system changes
  --catalog-only  Install and schedule the private Catalog (Arch/Debian/Ubuntu)
  --no-glass      Do not enable Fimbulwinter Glass
  --no-ollama     Skip Ollama model downloads and benchmarks
  --no-wol        Do not enable Wake-on-LAN
  --no-reapack    Skip the official ReaPack package
  --yes           Skip the terminal confirmation prompt
  --help          Show this help

This is an Arch Linux workstation installer, not an OS/partitioning installer.
It never formats disks, partitions drives, installs a bootloader, modifies firmware,
changes /etc/fstab, deletes personal files or reboots.
The complete 5,000-image gallery is a mandatory pre-installation gate.
EOF
}

GUI_MODE=1 DRY_RUN=0 CATALOG_ONLY=0 GLASS=1 OLLAMA=1 WOL=1 REAPACK=1 ASSUME_YES=0
while (($#)); do
  case "$1" in
    --cli) GUI_MODE=0 ;;
    --dry-run) DRY_RUN=1 ;;
    --catalog-only) CATALOG_ONLY=1 GUI_MODE=0 ;;
    --no-glass) GLASS=0 ;;
    --no-ollama) OLLAMA=0 ;;
    --no-wol) WOL=0 ;;
    --no-reapack) REAPACK=0 ;;
    --yes) ASSUME_YES=1 ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

if (( DRY_RUN && CATALOG_ONLY )); then
  log "Catalog-only plan: prepare the private Catalog on Arch or Debian/Ubuntu with Python 3.13+, verify exclusions, seed 176 metadata campaigns and enable the user timer."
  log "No desktop packages, system services, boot settings or personal data volumes will be changed."
  log "Dry run complete. No changes were made."
  exit 0
fi

if (( CATALOG_ONLY )); then
  [[ "$(uname -s)" == Linux ]] || die "Catalog-only preparation requires Linux."
  [[ "$EUID" -ne 0 ]] || die "Run Catalog-only preparation as a normal user, not root."
  [[ -n "${HOME:-}" && "$HOME" != "/" ]] || die "A valid user home directory is required."
  require_cmd sudo
  require_cmd git
  require_cmd python3
  [[ -r /etc/os-release ]] || die "Cannot identify the Linux distribution."
  # shellcheck disable=SC1091
  source /etc/os-release
  CATALOG_PLATFORM="${ID:-unknown}"
  case "$CATALOG_PLATFORM" in
    arch|debian|ubuntu) ;;
    *) die "Catalog-only preparation supports Arch, Debian and Ubuntu; detected: $CATALOG_PLATFORM" ;;
  esac
  python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 13) else 1)' \
    || die "The private Catalog requires Python 3.13 or newer."
  CATALOG_REPO="$(sed -n 's/^catalog_repository = "\\(.*\\)"/\\1/p' "$ROOT/components.lock")"
  [[ -n "$CATALOG_REPO" ]] || die "Private Catalog repository is missing from components.lock."
  log "Checking private Catalog access before installing prerequisites."
  if ! GIT_TERMINAL_PROMPT=0 git ls-remote "$CATALOG_REPO" HEAD >/dev/null 2>&1; then
    die "Private Catalog access is unavailable. Configure GitHub SSH or a Git credential helper, then rerun."
  fi
  sudo -v
  case "$CATALOG_PLATFORM" in
    arch)
      require_cmd pacman
      log "Ensuring the Arch Python packaging prerequisite is installed."
      sudo pacman -S --needed python-pip
      ;;
    debian|ubuntu)
      require_cmd apt-get
      log "Checking that the system Python can create isolated virtual environments."
      probe_root="$(mktemp -d "${TMPDIR:-/tmp}/fenrir-catalog-venv-check.XXXXXX")"
      if ! python3 -m venv "$probe_root/probe" >/dev/null 2>&1; then
        rm -rf -- "$probe_root"
        log "Installing only the Python venv prerequisite; no distribution upgrade will be run."
        sudo apt-get update
        sudo apt-get install -y python3-venv
        probe_root="$(mktemp -d "${TMPDIR:-/tmp}/fenrir-catalog-venv-check.XXXXXX")"
        python3 -m venv "$probe_root/probe" >/dev/null 2>&1 \
          || { rm -rf -- "$probe_root"; die "Python venv support is still unavailable after installing python3-venv."; }
      fi
      rm -rf -- "$probe_root"
      ;;
  esac
  log "Installing only the private rights-aware Catalog and its bounded metadata-discovery timer."
  bash "$ROOT/scripts/install-catalog.sh"
  log "Catalog-only preparation complete. No desktop packages or desktop configuration were changed."
  exit 0
fi

require_arch
require_user
require_cmd pacman
require_cmd python3
require_cmd git

if (( DRY_RUN )); then
  log "Plan: Arch Linux x86_64; Fenrir-Arch 1.2.8; pinned Dots 0.20.0; private Catalog 0.39.6."
  log "Desktop: Hyprland >= 0.57, SDDM, Quickshell 0.3.2 native shell, Waybar fallback, Fuzzel, Kitty, Thunar."
  log "Gaming: Steam, Proton support, GameMode, MangoHud, Gamescope, RPCS3, Heroic, Prism Launcher."
  log "Audio: PipeWire, EasyEffects, QPWGraph, Guitarix, Calf, REAPER and ReaPack."
  log "Productivity/device/recovery: VSCodium, VLC, LibreOffice, scrcpy/ADB, SMART/NVMe, Btrfs/Snapper and Restic tools."
  log "Gallery: mandatory 5,000-image registry and manifest preflight, complete SHA-256-verified sync."
  (( GLASS )) && log "Fimbulwinter Glass: 60% window opacity, compositor blur, user toggle enabled."
  (( OLLAMA )) && log "Ollama: Vulkan runtime, Qwen 3.5 9B / Gemma 3 12B / Gemma 3 4B download and benchmark."
  (( WOL )) && log "Wake-on-LAN: enable only adapters that advertise magic-packet capability."
  (( REAPACK )) || log "ReaPack skipped."
  log "No data-disk mounts will be configured; /mnt/storage is protected."
  log "Dry run complete. No changes were made."
  exit 0
fi


log "Preflighting the complete 5,000-image public gallery before any system changes."
if ! python3 "$ROOT/scripts/check-wallpaper-ready.py"; then
  die "The 5,000-image public gallery is incomplete or unavailable. No system packages, services or configuration were changed. Complete the Catalog rights/acquisition/publication workflow, then rerun this installer."
fi

if (( GUI_MODE )); then
  if [[ -z "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]] && [[ ! -t 0 || ! -t 1 ]]; then
    die "The GTK installer needs a local display/TTY. Rerun with --cli from a terminal."
  fi
  if [[ -z "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]]; then
    read -r -p "Install GTK4/Cage prerequisites and open the guided installer? [y/N] " answer
    [[ "${answer,,}" == y || "${answer,,}" == yes ]] || { log "Cancelled."; exit 0; }
    sudo pacman -Syu --needed cage gtk4 python python-gobject curl
    exec cage -s -- python3 "$ROOT/installer/gtk_installer.py" "$ROOT/install.sh"
  else
    read -r -p "Install GTK4 prerequisites and open the guided installer? [y/N] " answer
    [[ "${answer,,}" == y || "${answer,,}" == yes ]] || { log "Cancelled."; exit 0; }
    sudo pacman -Syu --needed gtk4 python python-gobject curl
    exec python3 "$ROOT/installer/gtk_installer.py" "$ROOT/install.sh"
  fi
fi

if (( ! ASSUME_YES )); then
  printf '\nFenrir will deploy the complete Arch workstation.\n'
  printf 'It will not partition or format drives, modify data-volume contents, edit /etc/fstab,\n'
  printf 'install a bootloader, modify firmware or reboot. Existing personal disks are left alone.\n'
  read -r -p 'Continue? [y/N] ' answer
  [[ "${answer,,}" == y || "${answer,,}" == yes ]] || { log "Cancelled."; exit 0; }
fi

sudo -v
command -v curl >/dev/null || die "curl is required. Run the standard GTK installer to bootstrap prerequisites."
command -v python3 >/dev/null || die "Python 3 is required."

DOTS_COMMIT="$(sed -n 's/^dots_commit = "\(.*\)"/\1/p' "$ROOT/components.lock")"
CATALOG_REPO="$(sed -n 's/^catalog_repository = "\(.*\)"/\1/p' "$ROOT/components.lock")"
[[ "$DOTS_COMMIT" =~ ^[0-9a-f]{40}$ ]] || die "Invalid pinned Fenrir-Dots commit."
[[ -n "$CATALOG_REPO" ]] || die "Private Catalog repository is missing from components.lock."

log "Checking private Catalog access before system changes."
if ! GIT_TERMINAL_PROMPT=0 git ls-remote "$CATALOG_REPO" HEAD >/dev/null 2>&1; then
  die "Private Catalog access is unavailable. Configure GitHub SSH or a Git credential helper, then rerun."
fi

enable_multilib(){
  if awk '
    /^\[multilib\]$/ {section=1; sections++; next}
    /^\[/ {section=0}
    section && /^Include = \/etc\/pacman.d\/mirrorlist$/ {includes++}
    END {exit !(sections==1 && includes==1)}
  ' /etc/pacman.conf; then
    return
  fi
  local backup stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  backup="/etc/pacman.conf.fenrir-$stamp"
  sudo cp -a /etc/pacman.conf "$backup"
  sudo sed -i '/^#\[multilib\]$/,/^#Include = \/etc\/pacman.d\/mirrorlist$/ s/^#//' /etc/pacman.conf
  if ! awk '
    /^\[multilib\]$/ {section=1; sections++; next}
    /^\[/ {section=0}
    section && /^Include = \/etc\/pacman.d\/mirrorlist$/ {includes++}
    END {exit !(sections==1 && includes==1)}
  ' /etc/pacman.conf; then
    sudo cp -a "$backup" /etc/pacman.conf
    die "Could not enable stock multilib safely; original pacman.conf restored."
  fi
  log "Enabled official multilib. Original pacman.conf: $backup"
}

enable_multilib
PACKAGES=("${BASE_PACKAGES[@]}" "${GAMING_PACKAGES[@]}")
(( OLLAMA == 0 )) || PACKAGES+=("${OLLAMA_PACKAGES[@]}")
if (( REAPACK == 0 )); then
  FILTERED=()
  for item in "${PACKAGES[@]}"; do [[ "$item" == reapack ]] || FILTERED+=("$item"); done
  PACKAGES=("${FILTERED[@]}")
fi

log "Installing the complete official Arch package profile. Review the pacman transaction and REAPER EULA."
sudo pacman -Syu --needed "${PACKAGES[@]}"

log "Adding Flathub and installing the requested desktop applications."
sudo flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak install --system --assumeyes flathub "${FLATPAK_APPS[@]}"

if getent group realtime >/dev/null 2>&1; then
  sudo usermod -aG realtime "$USER"
fi

log "Installing first-party Wake-on-LAN service."
sudo install -Dm755 "$ROOT/scripts/fenrir-wol" /usr/local/lib/fenrir/fenrir-wol
sudo install -Dm644 "$ROOT/systemd/system/fenrir-wol.service" /etc/systemd/system/fenrir-wol.service
if (( WOL )); then sudo systemctl enable fenrir-wol.service; fi

log "Deploying pinned Fenrir-Dots."
DOTS_DIR="$HOME/.local/share/fenrir/dots-source"
mkdir -p "$(dirname "$DOTS_DIR")"
export FENRIR_DOTS_COMMIT="$DOTS_COMMIT" FENRIR_DOTS_DIR="$DOTS_DIR"
if [[ ! -d "$DOTS_DIR/.git" ]]; then
  [[ ! -e "$DOTS_DIR" ]] || die "$DOTS_DIR exists but is not a Git checkout."
  git clone --filter=blob:none https://github.com/sunxsaturn/Fenrir-Dots.git "$DOTS_DIR"
fi
bash "$DOTS_DIR/scripts/install-dots.sh"
export PATH="$HOME/.local/bin:$PATH"

if (( GLASS )); then
  fenrir-glass enable --opacity 0.60
else
  fenrir-glass disable
fi

log "Installing the pinned private Wallpaper Catalog and seeding metadata-only population campaigns."
bash "$ROOT/scripts/install-catalog.sh"

log "Enabling NetworkManager, Bluetooth and SDDM. No service is force-started and no reboot is performed."
sudo systemctl enable NetworkManager bluetooth sddm
sudo systemctl daemon-reload

log "Synchronizing all 5,000 verified public images as the final library-install stage."
fenrir-wallpaper sync-public --destination "$HOME/Pictures/Wallpapers"

if (( OLLAMA )); then
  log "Installing Ollama Vulkan models and running local GPU/CPU benchmarks."
  bash "$ROOT/scripts/install-ollama-models.sh"
fi

HYPRLAND_VERSION="$(hyprland --version 2>/dev/null | head -n1 || true)"
python3 - "$HYPRLAND_VERSION" <<'PY'
import re, sys
value=sys.argv[1]
match=re.search(r"(\d+)\.(\d+)", value)
if not match or tuple(map(int, match.groups())) < (0,57):
    raise SystemExit("Fenrir requires Hyprland 0.57 or newer; detected: " + value)
PY

mkdir -p "$HOME/.local/share/fenrir"
python3 - "$ROOT" "$HOME" <<'PY'
import json,sys,tomllib
from pathlib import Path
root,home=Path(sys.argv[1]),Path(sys.argv[2])
lock=tomllib.loads((root/"components.lock").read_text())
versions={
 "Fenrir-Arch":lock["arch_version"],
 "Fenrir-Dots":lock["dots_version"],
 "Fenrir-Wallpaper-Catalog":lock["catalog_version"],
}
destination=home/".local/share/fenrir/installed-versions.json"
temporary=destination.with_suffix(".json.tmp")
temporary.write_text(json.dumps(versions,indent=2)+"\n",encoding="utf-8")
temporary.replace(destination)
print(json.dumps(versions,indent=2))
PY

log "Validating core install state."
command -v Hyprland >/dev/null || die "Hyprland command is missing."
command -v fenrir-wallpaper >/dev/null || die "Fenrir wallpaper command is missing."
command -v fenrir-catalog >/dev/null || die "Fenrir Catalog command is missing."
command -v ollama >/dev/null || (( OLLAMA == 0 )) || die "Ollama is missing."
log "Fenrir deployment completed. No reboot was performed; choose the Fenrir session in SDDM after reviewing the verification report."
