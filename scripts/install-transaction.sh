#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$ROOT/scripts/packages.sh"

WITH_AI=1
ENABLE_WOL=1
DRY_RUN=0
ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --without-ai) WITH_AI=0 ;;
    --with-ai) WITH_AI=1 ;;
    --no-wol) ENABLE_WOL=0 ;;
    --wol) ENABLE_WOL=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --yes) ASSUME_YES=1 ;;
    *) printf '[Fenrir] Unknown option: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

die() { printf '[Fenrir] ERROR: %s\n' "$*" >&2; exit 1; }
[[ -f /etc/arch-release ]] || die "Fenrir-Arch only supports Arch Linux. No changes were made."
[[ "$(uname -m)" == "x86_64" ]] || die "Fenrir requires x86_64."
[[ "$EUID" -ne 0 ]] || die "Run as a regular user with sudo access, not as root."
command -v sudo >/dev/null 2>&1 || die "sudo is required."
command -v pacman >/dev/null 2>&1 || die "pacman is required."
sudo -v

print_plan "$WITH_AI"
if (( DRY_RUN )); then
  printf '[Fenrir] Dry run complete; no system changes were made.\n'
  exit 0
fi

READY="$(python3 - "$ROOT/installer/release-state.json" <<'PY'
import json, sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print("yes" if data.get("release_ready") is True else "no")
PY
)"
[[ "$READY" == "yes" ]] || die "This source tree is still under rebuild. The installation gate is intentionally closed."

if (( ! ASSUME_YES )); then
  printf '\nThis installs the Fenrir workstation on the current Arch system.\n'
  printf 'It does not partition, format, mount, erase or resize any disk.\n'
  printf 'It does not alter /mnt/storage or the secondary SATA SSD.\n'
  printf 'It does not install a bootloader, modify firmware or reboot.\n'
  read -r -p 'Continue? [y/N] ' answer
  [[ "$answer" =~ ^[Yy]$ ]] || { printf '[Fenrir] Cancelled.\n'; exit 0; }
fi

sudo -v
sudo python3 "$ROOT/scripts/enable-multilib.py"
install_packages "$WITH_AI"
install_flatpak_apps

sudo install -D -m 0755 "$ROOT/scripts/fenrir-enable-wol" /usr/lib/fenrir/fenrir-enable-wol
sudo install -D -m 0644 "$ROOT/systemd/system/fenrir-wol.service" /etc/systemd/system/fenrir-wol.service
sudo systemctl daemon-reload
sudo systemctl enable NetworkManager.service bluetooth.service sddm.service
if (( ENABLE_WOL )); then
  sudo systemctl enable fenrir-wol.service
fi
if (( WITH_AI )); then
  sudo systemctl enable ollama.service
fi

bash "$ROOT/scripts/install-components.sh"

printf '[Fenrir] System packages, user components and complete public wallpaper sync passed.\n'
printf '[Fenrir] Storage volumes were not mounted or modified. No reboot was performed.\n'
