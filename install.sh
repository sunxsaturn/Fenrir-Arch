#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$ROOT/scripts/lib.sh"

usage() {
  cat <<'USAGE'
Fenrir Arch — one-command full workstation installer

Usage: ./install.sh [options]
  --dry-run       Print the complete plan; do not change the system
  --cli           Use terminal installer instead of the GTK guided installer
  --no-ai         Skip Ollama and Sun AI
  --no-storage    Do not add eligible fixed data filesystems to /etc/fstab
  --no-wol        Do not enable Wake-on-LAN
  --yes           Skip Fenrir's confirmation prompt (package prompts remain)
  --help          Show this help

The installer fetches Fenrir-Dots automatically and installs the complete
Hyprland desktop, gaming suite, audio tools, Firefox Nightly and applications.
USAGE
}

DRY_RUN=0 AI=1 STORAGE=1 WOL=1 ASSUME_YES=0 GUI_MODE=1
while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --cli) GUI_MODE=0 ;;
    --no-ai) AI=0 ;;
    --no-storage) STORAGE=0 ;;
    --no-wol) WOL=0 ;;
    --yes) ASSUME_YES=1 ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

require_arch
require_user
require_cmd sudo
require_cmd pacman
require_cmd git
require_cmd lsblk
require_cmd findmnt

# The default path is a GTK4 guided installer. Bootstrap only the GUI toolkit,
# then let the user choose optional integration features before the full install.
if (( GUI_MODE && ! DRY_RUN && ! ASSUME_YES )); then
    if [[ ! -t 0 ]]; then
        echo "Fenrir GUI bootstrap needs a terminal for consent; rerun with --cli or explicitly pass --yes." >&2
        exit 2
    fi
    echo "The graphical installer must first install GTK4 and Python GObject so the wizard can start."
    echo "No disks, partitions, user configuration, or desktop files are changed by this bootstrap."
    read -r -p "Install the installer interface prerequisites and continue? [y/N] " answer
    case "${answer,,}" in
        y|yes) ;;
        *) echo "Fenrir installer cancelled before making changes."; exit 0 ;;
    esac
fi

if (( GUI_MODE && ! DRY_RUN )); then
  if [[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]]; then
    sudo -v
    sudo pacman -Syu --needed gtk4 python-gobject
    exec python3 "$ROOT/scripts/fenrir-installer.py" "$ROOT/install.sh"
  elif [[ -t 0 && -t 1 && -z "${SSH_TTY:-}" ]] && tty 2>/dev/null | grep -Eq '^/dev/tty[0-9]+'; then
    # A minimal Arch install has no graphical session yet. Launch the same GTK
    # wizard in Cage directly on the active VT instead of dropping to a CLI.
    sudo -v
    sudo pacman -Syu --needed cage gtk4 python-gobject
    exec cage -s -- python3 "$ROOT/scripts/fenrir-installer.py" "$ROOT/install.sh"
  fi
fi

source "$ROOT/scripts/packages.sh"
print_plan "$AI"
(( STORAGE == 0 )) || log "Storage setup will append UUID-based fstab entries for eligible fixed data filesystems; root/boot/removable/unsupported volumes are excluded."
(( WOL == 0 )) || log "Wake-on-LAN will be enabled for physical Ethernet devices that advertise magic-packet support. BIOS/UEFI support is still required."

if (( DRY_RUN )); then
  log "Dry run complete. No changes were made; the companion dotfiles checkout is not fetched in dry-run mode."
  exit 0
fi

if (( ! ASSUME_YES )); then
  printf '\nThis is a full workstation install and performs a synchronized Arch upgrade.\n'
  printf 'It installs the requested desktop, gaming and audio packages, Mozilla Firefox Nightly,\n'
  printf 'clones Fenrir-Dots, deploys its configurations, sets US International dead keys,\n'
  printf 'enables Ethernet WoL where supported, and adds eligible data volumes to /etc/fstab.\n'
  printf 'It will not partition/format disks, alter data-volume contents, install a bootloader, or reboot.\n'
  read -r -p 'Continue? [y/N] ' answer
  [[ "$answer" =~ ^[Yy]$ ]] || { log "Cancelled; no changes made."; exit 0; }
fi

sudo -v

# Safely enable the stock multilib section before one complete system upgrade.
if ! awk '/^[[:space:]]*\[multilib\][[:space:]]*$/{sections++;inside=1;next} /^[[:space:]]*\[/{inside=0} inside && /^[[:space:]]*Include[[:space:]]*=[[:space:]]*\/etc\/pacman.d\/mirrorlist([[:space:]]|$)/ {includes++} END{exit !(sections == 1 && includes == 1)}' /etc/pacman.conf; then
  stamp="$(date +%Y%m%d-%H%M%S)"
  backup="/etc/pacman.conf.fenrir-backup-$stamp"
  sudo cp -a /etc/pacman.conf "$backup"
  sudo sed -i '/^[[:space:]]*#\[multilib\][[:space:]]*$/,/^[[:space:]]*#Include[[:space:]]*=[[:space:]]*\/etc\/pacman.d\/mirrorlist[[:space:]]*$/ s/^[[:space:]]*#//' /etc/pacman.conf
  if ! awk '/^[[:space:]]*\[multilib\][[:space:]]*$/{sections++;inside=1;next} /^[[:space:]]*\[/{inside=0} inside && /^[[:space:]]*Include[[:space:]]*=[[:space:]]*\/etc\/pacman.d\/mirrorlist([[:space:]]|$)/ {includes++} END{exit !(sections == 1 && includes == 1)}' /etc/pacman.conf; then
    sudo cp -a "$backup" /etc/pacman.conf
    die "Could not safely enable the standard multilib section; original pacman.conf restored."
  fi
  log "Enabled multilib. Original pacman.conf saved at $backup"
fi

install_packages "$AI"
require_cmd python3
require_cmd curl
require_cmd ethtool
require_cmd flatpak

# The visual layer is maintained independently, like established Hyprland dotfiles projects.
DOTS_DIR="${FENRIR_DOTS_DIR:-$HOME/.local/share/fenrir/dots}"
DOTS_REPO="${FENRIR_DOTS_REPO:-https://github.com/sunxsaturn/Fenrir-Dots.git}"
DOTS_REF="${FENRIR_DOTS_REF:-main}"
mkdir -p "$(dirname -- "$DOTS_DIR")"
if [[ -d "$DOTS_DIR/.git" ]]; then
  log "Updating existing Fenrir-Dots checkout at $DOTS_DIR"
  git -C "$DOTS_DIR" fetch --prune origin "$DOTS_REF"
  git -C "$DOTS_DIR" checkout -q "$DOTS_REF"
  git -C "$DOTS_DIR" pull --ff-only origin "$DOTS_REF"
elif [[ -e "$DOTS_DIR" ]]; then
  die "$DOTS_DIR already exists but is not a Git checkout. Move it aside and rerun; nothing there was overwritten."
else
  log "Cloning Fenrir-Dots ($DOTS_REF)"
  git clone --depth=1 --branch "$DOTS_REF" "$DOTS_REPO" "$DOTS_DIR"
fi
[[ -f "$DOTS_DIR/config/hypr/hyprland.lua" && -d "$DOTS_DIR/apps/sun-ai" ]] || die "Fenrir-Dots checkout is incomplete or incompatible."
DOTS_ROOT="$(cd -- "$DOTS_DIR" && pwd -P)"
export ROOT DOTS_ROOT
source "$ROOT/scripts/deploy.sh"

install_flatpak_apps
"$ROOT/scripts/install-firefox-nightly.sh"
backup_and_deploy "$AI"
install_sun_ai "$AI"
install_user_units
configure_system_services "$AI" "$WOL"

if (( STORAGE )); then
  sudo bash "$ROOT/scripts/configure-storage.sh" --apply
fi

wallpaper_manifest="${FENRIR_WALLPAPER_MANIFEST_URL:-}"
if [[ -z "$wallpaper_manifest" && -f "$ROOT/wallpapers/manifest.json" ]]; then
  wallpaper_manifest="$ROOT/wallpapers/manifest.json"
fi
if [[ -n "$wallpaper_manifest" ]]; then
  python3 "$ROOT/scripts/download_wallpaper_pack.py" --manifest "$wallpaper_manifest" --destination "$HOME/Pictures/Wallpapers" || die "Wallpaper pack failed validation/download. Other components may already be installed; correct the manifest and rerun Fenrir."
else
  log "No approved 5000+ wallpaper manifest is bundled or configured. No images were scraped or bulk-downloaded."
fi

validate_install "$AI"
printf '\nFenrir workstation installation finished.\n'
printf 'Log out and choose Hyprland in SDDM. Verify WoL firmware options.\n'
printf 'Run fenrir-wallpaper status to inspect the 5000-image requirement.\n'
printf 'No reboot was performed.\n'
