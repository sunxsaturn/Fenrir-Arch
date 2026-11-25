#!/usr/bin/env bash
set -Eeuo pipefail

# ReaPack is a REAPER extension, not an Arch pacman package.
# Pin the upstream Linux x86_64 release and verify its published SHA-256.
VERSION="v1.2.6"
ASSET="reaper_reapack-x86_64.so"
URL="https://github.com/cfillion/reapack/releases/download/$VERSION/$ASSET"
EXPECTED_SHA256="35d80f63d8174c964af589c7d87c4728aa18f06899dce873e33f8d552d1bc7e0"

require_cmd() { command -v "$1" >/dev/null 2>&1 || { printf '[Fenrir] Required command is missing: %s\n' "$1" >&2; exit 1; }; }
require_cmd curl
require_cmd sha256sum
require_cmd readelf
require_cmd ldd

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
PLUGIN_DIR="$CONFIG_HOME/REAPER/UserPlugins"
STATE_DIR="$HOME/.local/state/fenrir"
STAMP="$(date +%Y%m%d-%H%M%S)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

curl --proto '=https' --tlsv1.2 --fail --location --retry 3 --retry-delay 2 \
  "$URL" -o "$TMP/$ASSET"
printf '%s  %s\n' "$EXPECTED_SHA256" "$TMP/$ASSET" | sha256sum --check --status || {
  echo "[Fenrir] ReaPack checksum verification failed; the existing plugin was not changed." >&2
  exit 1
}

header="$(readelf -h "$TMP/$ASSET")"
grep -Eq 'Class:[[:space:]]+ELF64' <<<"$header" || {
  echo "[Fenrir] ReaPack release is not an ELF64 plugin." >&2
  exit 1
}
grep -Eq 'Machine:[[:space:]]+Advanced Micro Devices X86-64' <<<"$header" || {
  echo "[Fenrir] ReaPack release is not an x86_64 plugin." >&2
  exit 1
}
if ldd "$TMP/$ASSET" 2>&1 | grep -q 'not found'; then
  echo "[Fenrir] ReaPack has unresolved shared-library dependencies; it was not installed." >&2
  exit 1
fi

mkdir -p "$PLUGIN_DIR"
DEST="$PLUGIN_DIR/$ASSET"
if [[ -e "$DEST" || -L "$DEST" ]]; then
  BACKUP="$STATE_DIR/backups/$STAMP/.config/REAPER/UserPlugins/$ASSET"
  mkdir -p "$(dirname -- "$BACKUP")"
  cp -a -- "$DEST" "$BACKUP"
  printf '[Fenrir] Existing ReaPack plugin backed up to %s\n' "$BACKUP"
fi

install -m 0644 "$TMP/$ASSET" "$PLUGIN_DIR/.$ASSET.new"
mv -f -- "$PLUGIN_DIR/.$ASSET.new" "$DEST"
printf '[Fenrir] Installed verified ReaPack %s at %s\n' "$VERSION" "$DEST"
