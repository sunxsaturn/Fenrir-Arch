#!/usr/bin/env bash
set -Eeuo pipefail

# Install Mozilla's official 64-bit Linux Nightly build without an AUR helper.
# Mozilla publishes a latest-mozilla-central directory and a SHA-512 manifest.
HOME_DIR="${HOME:?HOME must be set}"
BASE_URL="https://archive.mozilla.org/pub/firefox/nightly/latest-mozilla-central"
DEST="$HOME_DIR/.local/opt/firefox-nightly"
BIN_DIR="$HOME_DIR/.local/bin"
APPS_DIR="$HOME_DIR/.local/share/applications"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

command -v curl >/dev/null 2>&1 || { echo "curl is required for Firefox Nightly" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required for Firefox Nightly" >&2; exit 1; }

index_file="$TMP/index.html"
curl --proto '=https' --tlsv1.2 -fsSL "$BASE_URL/" -o "$index_file"
archive_name="$(python3 - "$index_file" <<'PY'
from html.parser import HTMLParser
from pathlib import Path
import re, sys
class Links(HTMLParser):
    def __init__(self): super().__init__(); self.items=[]
    def handle_starttag(self, tag, attrs):
        if tag == "a":
            href = dict(attrs).get("href", "")
            if re.fullmatch(r"firefox-[0-9][A-Za-z0-9.+-]*\.en-US\.linux-x86_64\.tar\.xz", href):
                self.items.append(href)
p=Links(); p.feed(Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace"))
if not p.items: raise SystemExit("No official x86_64 Nightly archive found in Mozilla's current index")
def version(name):
    return tuple(int(x) if x.isdigit() else x for x in re.split(r"(\d+)", name))
print(max(set(p.items), key=version))
PY
)"
checksums_name="${archive_name%.tar.xz}.checksums"
curl --proto '=https' --tlsv1.2 -fsSL "$BASE_URL/$checksums_name" -o "$TMP/checksums"
expected="$(awk -v name="$archive_name" '$2 == "sha512" && $4 == name {print $1; exit}' "$TMP/checksums")"
[[ "$expected" =~ ^[a-fA-F0-9]{128}$ ]] || { echo "Mozilla SHA-512 checksum entry missing for $archive_name" >&2; exit 1; }
curl --proto '=https' --tlsv1.2 -fL --retry 3 --retry-delay 2 "$BASE_URL/$archive_name" -o "$TMP/$archive_name"
printf '%s  %s\n' "$expected" "$TMP/$archive_name" | sha512sum --check --status || { echo "Firefox Nightly checksum mismatch" >&2; exit 1; }

mkdir -p "$TMP/unpacked" "$DEST" "$BIN_DIR" "$APPS_DIR"
tar -xJf "$TMP/$archive_name" -C "$TMP/unpacked" --no-same-owner
[[ -x "$TMP/unpacked/firefox/firefox" ]] || { echo "Downloaded Nightly archive has no firefox executable" >&2; exit 1; }
# Atomic directory replacement: retain the previous version until the new one is verified.
new_dir="$HOME_DIR/.local/opt/firefox-nightly.new-$$"
rm -rf -- "$new_dir"
cp -a "$TMP/unpacked/firefox" "$new_dir"
chmod -R u+rwX,go+rX "$new_dir"
old_dir="$HOME_DIR/.local/opt/firefox-nightly.old-$$"
if [[ -d "$DEST" ]]; then mv "$DEST" "$old_dir"; fi
if mv "$new_dir" "$DEST"; then rm -rf -- "$old_dir"; else [[ ! -d "$old_dir" ]] || mv "$old_dir" "$DEST"; exit 1; fi
ln -sfn "$DEST/firefox" "$BIN_DIR/firefox-nightly"
cat > "$APPS_DIR/firefox-nightly.desktop" <<DESKTOP
[Desktop Entry]
Name=Firefox Nightly
Comment=Mozilla Firefox Nightly development build
Exec=$BIN_DIR/firefox-nightly %u
Icon=$DEST/browser/chrome/icons/default/default128.png
Terminal=false
Type=Application
Categories=Network;WebBrowser;Development;
StartupNotify=true
DESKTOP
update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
printf '[Fenrir] Installed Mozilla Firefox Nightly (%s) with SHA-512 verification.\n' "${archive_name#firefox-}"
