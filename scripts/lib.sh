#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf '[Fenrir] %s\n' "$*"; }
die() { printf '[Fenrir] ERROR: %s\n' "$*" >&2; exit 1; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"; }
require_arch() {
  [[ -r /etc/arch-release ]] || die "This installer only supports Arch Linux. No changes made."
  [[ "$(uname -m)" == x86_64 ]] || die "Only x86_64 is currently supported."
}
require_user() {
  (( EUID != 0 )) || die "Run as a regular user, not root. The installer uses sudo only for system package/service tasks."
  [[ -n "${HOME:-}" && "$HOME" != / ]] || die "HOME is unset or invalid."
}
