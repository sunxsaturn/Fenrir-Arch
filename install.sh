#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
die() { printf '[Fenrir] ERROR: %s\n' "$*" >&2; exit 1; }

[[ -f /etc/arch-release ]] ||
  die "Fenrir-Arch only runs on Arch Linux. This host was not changed."
[[ "$(uname -m)" == "x86_64" ]] ||
  die "Fenrir requires Arch Linux x86_64. This host was not changed."
[[ "$EUID" -ne 0 ]] ||
  die "Run as a regular sudo-enabled user, not as root."
command -v sudo >/dev/null 2>&1 || die "sudo is required."
command -v pacman >/dev/null 2>&1 || die "pacman is required."
command -v git >/dev/null 2>&1 || die "Git is required."

usage() {
  cat <<'EOF'
Fenrir Desktop — Arch workstation installer

Usage:
  ./install.sh           Open the GTK4 guided installer
  ./install.sh --cli     Terminal-based installation
  ./install.sh --dry-run Show the package plan without changing the system
  ./install.sh --help    Show this help

This is not an OS/partitioning installer. It never formats disks, installs a
bootloader, modifies firmware or reboots. Data disks are not mounted by default.
EOF
}
case "${1:-}" in
  --help|-h) usage; exit 0 ;;
  --dry-run) exec bash "$ROOT/scripts/install-transaction.sh" --dry-run ;;
  --cli) shift; exec bash "$ROOT/scripts/install-transaction.sh" "$@" ;;
  "") ;;
  *) die "Unknown option: $1" ;;
esac

READY="$(python3 - "$ROOT/installer/release-state.json" <<'PY'
import json, sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print("yes" if data.get("release_ready") is True else "no")
PY
)"
[[ "$READY" == "yes" ]] ||
  die "Fenrir is still being rebuilt. No packages were installed. Follow the repository's acceptance status before running the installer."

sudo -v
if [[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]]; then
  sudo pacman -Syu --needed gtk4 python-gobject
  exec python3 "$ROOT/installer/gtk_installer.py" "$ROOT"
fi

# A minimal Arch TTY has no desktop compositor yet. Cage runs the GTK4 wizard
# directly on the active seat; this does not install a bootloader or reboot.
sudo pacman -Syu --needed cage gtk4 python-gobject
command -v cage >/dev/null 2>&1 || die "Cage was not installed."
exec cage -s -- python3 "$ROOT/installer/gtk_installer.py" "$ROOT"
