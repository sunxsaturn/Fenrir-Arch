#!/usr/bin/env bash
set -Eeuo pipefail

log(){ printf '[Fenrir] %s\n' "$*"; }
die(){ printf '[Fenrir] ERROR: %s\n' "$*" >&2; exit 1; }
require_cmd(){ command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"; }

require_arch(){
  [[ -f /etc/arch-release ]] || die "This installer targets Arch Linux only. Never run it on Debian."
  # shellcheck disable=SC1091
  source /etc/os-release
  [[ "${ID:-}" == arch ]] || die "Unsupported operating system: ${ID:-unknown}"
  [[ "$(uname -m)" == x86_64 ]] || die "Only Arch Linux x86_64 is supported."
  [[ "$(getconf LONG_BIT)" == 64 ]] || die "A 64-bit userspace is required."
}

require_user(){
  [[ "$EUID" -ne 0 ]] || die "Run as a normal user with sudo access, not as root."
  [[ -n "${HOME:-}" && "$HOME" != "/" ]] || die "A valid user home directory is required."
  id "$USER" >/dev/null 2>&1 || die "Could not resolve the invoking user."
  require_cmd sudo
  require_cmd git
  require_cmd lsblk
  require_cmd findmnt
}

assert_not_protected_path(){
  local path
  path="$(realpath -m -- "$1")"
  case "$path" in
    /mnt/storage|/mnt/storage/*) die "Protected path rejected: $path" ;;
  esac
}

