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
  --no-reapack    Skip the optional ReaPack extension for REAPER
  --no-storage    Do not add eligible fixed data filesystems to /etc/fstab
  --no-wol        Do not enable Wake-on-LAN
  --yes           Skip Fenrir's confirmation prompt (package prompts remain)
  --help          Show this help

The installer fetches Fenrir-Dots automatically and installs the complete
Hyprland desktop, gaming suite, audio tools, Firefox Nightly and applications.
USAGE
}

DRY_RUN=0 AI=1 REAPACK=1 STORAGE=1 WOL=1 ASSUME_YES=0 GUI_MODE=1
while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --cli) GUI_MODE=0 ;;
    --no-reapack) REAPACK=0 ;;
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
print_plan "$AI" "$REAPACK"
(( REAPACK == 0 )) || log "ReaPack: installing the signed official Arch Extra package; no AUR helper or third-party binary download."
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

install_packages "$AI" "$REAPACK"
require_cmd python3
require_cmd curl
require_cmd ethtool
require_cmd flatpak

# The visual layer is maintained independently, like established Hyprland dotfiles projects.
DOTS_DIR="${FENRIR_DOTS_DIR:-$HOME/.local/share/fenrir/dots}"
DOTS_REPO="${FENRIR_DOTS_REPO:-https://github.com/sunxsaturn/Fenrir-Dots.git}"
DOTS_COMMIT="${FENRIR_DOTS_COMMIT:-8df1f8e4fd4070b0289ad844da4ea74e866d72f1}"
CATALOG_COMMIT="${FENRIR_CATALOG_COMMIT:-63882e57114450926ccccc96d2e503a02ba168d7}"
[[ "$DOTS_COMMIT" =~ ^[0-9a-f]{40}$ ]] || die "FENRIR_DOTS_COMMIT must be a full 40-character Git commit SHA."
mkdir -p "$(dirname -- "$DOTS_DIR")"
if [[ -d "$DOTS_DIR/.git" ]]; then
  log "Fetching the pinned Fenrir-Dots source at $DOTS_COMMIT"
  if [[ "$(git -C "$DOTS_DIR" rev-parse --is-shallow-repository)" == "true" ]]; then
    git -C "$DOTS_DIR" fetch --unshallow origin
  else
    git -C "$DOTS_DIR" fetch --prune origin
  fi
  git -C "$DOTS_DIR" checkout --detach "$DOTS_COMMIT"
elif [[ -e "$DOTS_DIR" ]]; then
  die "$DOTS_DIR already exists but is not a Git checkout. Move it aside and rerun; nothing there was overwritten."
else
  log "Cloning Fenrir-Dots and selecting the pinned source commit"
  git clone "$DOTS_REPO" "$DOTS_DIR"
  git -C "$DOTS_DIR" checkout --detach "$DOTS_COMMIT"
fi
DOTS_HEAD="$(git -C "$DOTS_DIR" rev-parse HEAD)"
[[ "$DOTS_HEAD" == "$DOTS_COMMIT" ]] || die "Fenrir-Dots checkout mismatch: expected $DOTS_COMMIT, found $DOTS_HEAD."
DOTS_VERSION="$(cat "$DOTS_DIR/VERSION" 2>/dev/null || true)"
[[ "$DOTS_VERSION" == "0.15.0" ]] || die "Fenrir-Dots 0.15.0 is required; found '${DOTS_VERSION:-missing}'. Update the companion source checkout."
DOTS_REQUIRED_FILES=(
  config/hypr/hyprland.lua
  apps/fenrir-settings/app.py
  apps/fenrir-welcome/app.py
  apps/fenrir-settings/monitor.py
  apps/fenrir-doctor/README.md
  apps/fenrir-doctor/server.py
  apps/fenrir-doctor/index.html
  apps/fenrir-doctor/assets/app.js
  apps/fenrir-doctor/assets/style.css
  bin/fenrir-doctor
  bin/fenrir-upgrade
  bin/fenrir-wallpaper
  bin/fenrir_wallpaper_library.py
  tests/test_theme_wallpaper.py
  tests/test_wallpaper_library_sync.py
  systemd/user/fenrir-doctor.service
  applications/fenrir-doctor.desktop
  config/icons/Fenrir-Obsidian/scalable/apps/fenrir-doctor.svg
  tests/test_fenrir_doctor.py
)
for source_file in "${DOTS_REQUIRED_FILES[@]}"; do
  [[ -f "$DOTS_DIR/$source_file" ]] || die "Fenrir-Dots source is incomplete: missing tracked project file $source_file"
done
DOTS_ROOT="$(cd -- "$DOTS_DIR" && pwd -P)"
export ROOT DOTS_ROOT
source "$ROOT/scripts/deploy.sh"

install_flatpak_apps
"$ROOT/scripts/install-firefox-nightly.sh"
FENRIR_CATALOG_COMMIT="$CATALOG_COMMIT" bash "$ROOT/scripts/install-catalog.sh"
backup_and_deploy "$AI"
install_fenrir_doctor "$AI"
install_user_units
configure_system_services "$AI" "$WOL"

if (( STORAGE )); then
  sudo bash "$ROOT/scripts/configure-storage.sh" --apply
fi

sync_public_wallpaper_library
log "Fenrir Doctor is available for auditing the public library and managing separately accepted private Catalog assets."

sync_public_wallpaper_library() {
  local wallpaper_cli plan_json sync_json metrics final_metrics
  local manifest_records unique_images pending_downloads planned_bytes
  local destination_free destination_required state_free state_required storage_ok
  local total_downloaded total_verified failures total_unique remaining
  local final_pending final_present final_unique
  wallpaper_cli="$HOME/.local/bin/fenrir-wallpaper"
  [[ -x "$wallpaper_cli" ]] || die "Fenrir wallpaper sync command is missing: $wallpaper_cli"

  log "Preflighting every image in the three active public wallpaper volumes."
  if ! plan_json="$("$wallpaper_cli" sync-library --dry-run --json)"; then
    die "Could not read and validate every public wallpaper manifest. No image download was started."
  fi
  if ! metrics="$(python3 -c '
import json, sys
try:
    report = json.load(sys.stdin)
    if report.get("dry_run") is not True:
        raise ValueError("sync preview was not read-only")
    storage = report.get("storage_preflight")
    if not isinstance(storage, dict):
        raise ValueError("storage preflight is missing")
    fields = (
        "manifest_records", "unique_images", "planned_downloads",
        "selected_download_bytes",
    )
    values = []
    for field in fields:
        value = report.get(field)
        if isinstance(value, bool) or not isinstance(value, int) or value < 0:
            raise ValueError(f"invalid preview field: {field}")
        values.append(value)
    if report.get("selected_downloads") != report.get("planned_downloads"):
        raise ValueError("the preview did not select the entire missing public library")
    if report.get("remaining_after_limit") != 0:
        raise ValueError("the preview contains a transfer limit; full synchronization is required")
    if not isinstance(report.get("active_volumes"), list) or not report["active_volumes"]:
        raise ValueError("no active public wallpaper volumes were returned")
    for field in (
        "destination_available_bytes", "destination_required_bytes",
        "state_available_bytes", "state_required_bytes",
    ):
        value = storage.get(field)
        if isinstance(value, bool) or not isinstance(value, int) or value < 0:
            raise ValueError(f"invalid storage preflight field: {field}")
    enough = storage.get("sufficient")
    if not isinstance(enough, bool):
        raise ValueError("storage sufficiency result is missing")
    values.extend((
        storage["destination_available_bytes"],
        storage["destination_required_bytes"],
        storage["state_available_bytes"],
        storage["state_required_bytes"],
        int(enough),
    ))
    print("\t".join(str(value) for value in values))
except (ValueError, TypeError, json.JSONDecodeError) as exc:
    print(f"Invalid public wallpaper preflight report: {exc}", file=sys.stderr)
    raise SystemExit(2)
' <<<"$plan_json")"; then
    die "The public wallpaper library preflight returned an invalid report."
  fi
  IFS=
write_installed_versions() {
  local arch_version dots_version catalog_version manifest_dir manifest temporary
  arch_version="$(tr -d '\\n' < "$ROOT/VERSION")"
  dots_version="$DOTS_VERSION"
  catalog_version="$(python3 -c 'import sys,tomllib; print(tomllib.load(open(sys.argv[1], "rb"))["project"]["version"])' "$HOME/.local/share/fenrir/catalog-source/pyproject.toml")"

  for version in "$arch_version" "$dots_version" "$catalog_version"; do
    [[ "$version" =~ ^[0-9]+\\.[0-9]+\\.[0-9]+$ ]] || die "Refusing to write invalid installed component version: $version"
  done

  manifest_dir="$HOME/.local/share/fenrir"
  [[ ! -L "$HOME/.local" && ! -L "$HOME/.local/share" && ! -L "$manifest_dir" ]] || die "Refusing a symlinked Fenrir version-manifest directory."
  mkdir -p "$manifest_dir"
  manifest="$manifest_dir/installed-versions.json"
  backup_path "$manifest" ".local/share/fenrir/installed-versions.json"
  temporary="$(mktemp "$manifest_dir/.installed-versions.XXXXXX")"
  chmod 0600 "$temporary"
  printf '{\n  "Fenrir-Arch": "%s",\n  "Fenrir-Dots": "%s",\n  "Fenrir-Wallpaper-Catalog": "%s"\n}\n' \\
    "$arch_version" "$dots_version" "$catalog_version" > "$temporary"
  mv -f -- "$temporary" "$manifest"
  log "Recorded installed component versions at $manifest"
}
write_installed_versions

printf '\nFenrir workstation installation finished.\n'
printf 'Log out and choose Hyprland in SDDM. Verify WoL firmware options.\n'
printf 'Open Fenrir Doctor → Wallpapers to audit the existing inventory and sync already accepted images.\n'
printf 'No reboot was performed.\n'
\t' read -r manifest_records unique_images pending_downloads planned_bytes \
    destination_free destination_required state_free state_required storage_ok <<<"$metrics"

  if (( storage_ok == 0 )); then
    die "Insufficient free space for the complete wallpaper library. Destination: $destination_free available / $destination_required required bytes; resumable cache: $state_free available / $state_required required bytes. Free space or change wallpaper.directory, then rerun ./install.sh."
  fi

  log "Public wallpaper library: $manifest_records manifest records / $unique_images unique images."
  log "Missing images: $pending_downloads; estimated transfer: $((planned_bytes / 1073741824)) GiB; storage preflight passed."
  if (( pending_downloads > 0 && ! ASSUME_YES )); then
    local answer
    read -r -p "Download all $pending_downloads missing public wallpapers now? [y/N] " answer
    case "$answer" in
      y|Y|yes|YES|Yes) ;;
      *) die "Wallpaper download cancelled. Re-run ./install.sh to complete the full public wallpaper synchronization." ;;
    esac
  fi

  log "Synchronizing the complete public wallpaper library through the Fenrir Dots command (no batch limit)."
  if ! sync_json="$("$wallpaper_cli" sync-library --json)"; then
    printf '%s\n' "$sync_json" >&2
    die "Public wallpaper synchronization reported a failed transfer. Re-run ./install.sh to resume the verified partial downloads."
  fi

  if ! metrics="$(python3 -c '
import json, sys
try:
    report = json.load(sys.stdin)
    fields = ("downloaded", "already_present", "failed", "unique_images", "remaining_after_limit")
    values = []
    for field in fields:
        value = report.get(field)
        if isinstance(value, bool) or not isinstance(value, int) or value < 0:
            raise ValueError(f"invalid synchronization field: {field}")
        values.append(value)
    if report.get("dry_run") is not False:
        raise ValueError("sync report does not describe a real transfer")
    if values[2] != 0 or values[4] != 0 or values[0] + values[1] != values[3]:
        raise ValueError("the public library was not fully synchronized")
    print("\t".join(str(value) for value in values))
except (ValueError, TypeError, json.JSONDecodeError) as exc:
    print(f"Invalid public wallpaper sync report: {exc}", file=sys.stderr)
    raise SystemExit(2)
' <<<"$sync_json")"; then
    printf '%s\n' "$sync_json" >&2
    die "The public wallpaper synchronization report is incomplete or invalid."
  fi
  IFS=
write_installed_versions() {
  local arch_version dots_version catalog_version manifest_dir manifest temporary
  arch_version="$(tr -d '\\n' < "$ROOT/VERSION")"
  dots_version="$DOTS_VERSION"
  catalog_version="$(python3 -c 'import sys,tomllib; print(tomllib.load(open(sys.argv[1], "rb"))["project"]["version"])' "$HOME/.local/share/fenrir/catalog-source/pyproject.toml")"

  for version in "$arch_version" "$dots_version" "$catalog_version"; do
    [[ "$version" =~ ^[0-9]+\\.[0-9]+\\.[0-9]+$ ]] || die "Refusing to write invalid installed component version: $version"
  done

  manifest_dir="$HOME/.local/share/fenrir"
  [[ ! -L "$HOME/.local" && ! -L "$HOME/.local/share" && ! -L "$manifest_dir" ]] || die "Refusing a symlinked Fenrir version-manifest directory."
  mkdir -p "$manifest_dir"
  manifest="$manifest_dir/installed-versions.json"
  backup_path "$manifest" ".local/share/fenrir/installed-versions.json"
  temporary="$(mktemp "$manifest_dir/.installed-versions.XXXXXX")"
  chmod 0600 "$temporary"
  printf '{\n  "Fenrir-Arch": "%s",\n  "Fenrir-Dots": "%s",\n  "Fenrir-Wallpaper-Catalog": "%s"\n}\n' \\
    "$arch_version" "$dots_version" "$catalog_version" > "$temporary"
  mv -f -- "$temporary" "$manifest"
  log "Recorded installed component versions at $manifest"
}
write_installed_versions

printf '\nFenrir workstation installation finished.\n'
printf 'Log out and choose Hyprland in SDDM. Verify WoL firmware options.\n'
printf 'Open Fenrir Doctor → Wallpapers to audit the existing inventory and sync already accepted images.\n'
printf 'No reboot was performed.\n'
\t' read -r total_downloaded total_verified failures total_unique remaining <<<"$metrics"
  log "Verified public wallpaper library: $total_verified existing + $total_downloaded newly downloaded = $total_unique unique images."

  if ! plan_json="$("$wallpaper_cli" sync-library --dry-run --json)"; then
    die "Could not verify the final public wallpaper inventory."
  fi
  final_metrics="$(python3 -c '
import json, sys
report = json.load(sys.stdin)
if report.get("dry_run") is not True:
    raise SystemExit(2)
for key in ("planned_downloads", "already_present", "unique_images"):
    value = report.get(key)
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise SystemExit(2)
print(report["planned_downloads"], report["already_present"], report["unique_images"])
' <<<"$plan_json")" || die "Final public wallpaper verification returned an invalid report."
  read -r final_pending final_present final_unique <<<"$final_metrics"
  (( final_pending == 0 && final_present == final_unique )) || die "Public wallpaper verification found missing or invalid files ($final_pending still missing). Re-run ./install.sh to resume synchronization."
  log "Public wallpaper synchronization complete: all $final_unique manifest-listed images are present and verified."
}

validate_install "$AI" "$REAPACK"

write_installed_versions() {
  local arch_version dots_version catalog_version manifest_dir manifest temporary
  arch_version="$(tr -d '\\n' < "$ROOT/VERSION")"
  dots_version="$DOTS_VERSION"
  catalog_version="$(python3 -c 'import sys,tomllib; print(tomllib.load(open(sys.argv[1], "rb"))["project"]["version"])' "$HOME/.local/share/fenrir/catalog-source/pyproject.toml")"

  for version in "$arch_version" "$dots_version" "$catalog_version"; do
    [[ "$version" =~ ^[0-9]+\\.[0-9]+\\.[0-9]+$ ]] || die "Refusing to write invalid installed component version: $version"
  done

  manifest_dir="$HOME/.local/share/fenrir"
  [[ ! -L "$HOME/.local" && ! -L "$HOME/.local/share" && ! -L "$manifest_dir" ]] || die "Refusing a symlinked Fenrir version-manifest directory."
  mkdir -p "$manifest_dir"
  manifest="$manifest_dir/installed-versions.json"
  backup_path "$manifest" ".local/share/fenrir/installed-versions.json"
  temporary="$(mktemp "$manifest_dir/.installed-versions.XXXXXX")"
  chmod 0600 "$temporary"
  printf '{\n  "Fenrir-Arch": "%s",\n  "Fenrir-Dots": "%s",\n  "Fenrir-Wallpaper-Catalog": "%s"\n}\n' \\
    "$arch_version" "$dots_version" "$catalog_version" > "$temporary"
  mv -f -- "$temporary" "$manifest"
  log "Recorded installed component versions at $manifest"
}
write_installed_versions

printf '\nFenrir workstation installation finished.\n'
printf 'Log out and choose Hyprland in SDDM. Verify WoL firmware options.\n'
printf 'Open Fenrir Doctor → Wallpapers to audit the existing inventory and sync already accepted images.\n'
printf 'No reboot was performed.\n'
