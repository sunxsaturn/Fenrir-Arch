#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck disable=SC1091
source "$ROOT/scripts/lib.sh"

[[ $EUID -ne 0 ]] || die "Run Catalog deployment as the desktop user."
CATALOG_REPO="$(sed -n 's/^catalog_repository = "\(.*\)"/\1/p' "$ROOT/components.lock")"
CATALOG_COMMIT="$(sed -n 's/^catalog_commit = "\(.*\)"/\1/p' "$ROOT/components.lock")"
CATALOG_VERSION="$(sed -n 's/^catalog_version = "\(.*\)"/\1/p' "$ROOT/components.lock")"
[[ "$CATALOG_COMMIT" =~ ^[0-9a-f]{40}$ ]] || die "Invalid Catalog commit pin."
CATALOG_DIR="$HOME/.local/share/fenrir/catalog-source"
VENV="$HOME/.local/share/fenrir/catalog-venv"
CATALOG_HOME="$HOME/.local/share/fenrir/catalog"

for path in "$CATALOG_DIR" "$VENV" "$CATALOG_HOME"; do
  assert_not_protected_path "$path"
done
mkdir -p "$(dirname "$CATALOG_DIR")" "$CATALOG_HOME"
chmod 0700 "$CATALOG_HOME"

if [[ -e "$CATALOG_DIR" ]]; then
  [[ -d "$CATALOG_DIR/.git" ]] || die "$CATALOG_DIR exists but is not a Git checkout."
  [[ "$(git -C "$CATALOG_DIR" remote get-url origin)" == "$CATALOG_REPO" ]] || die "Unexpected Catalog remote."
  git -C "$CATALOG_DIR" fetch --depth=1 origin "$CATALOG_COMMIT"
else
  git clone --filter=blob:none "$CATALOG_REPO" "$CATALOG_DIR" || die "Private Catalog access failed. Configure SSH or Git credential-helper access; no token is stored by Fenrir."
  git -C "$CATALOG_DIR" fetch --depth=1 origin "$CATALOG_COMMIT"
fi
git -C "$CATALOG_DIR" checkout --detach "$CATALOG_COMMIT"
[[ "$(git -C "$CATALOG_DIR" rev-parse HEAD)" == "$CATALOG_COMMIT" ]] || die "Catalog pin mismatch."
[[ "$(tr -d '\r\n' < "$CATALOG_DIR/VERSION")" == "$CATALOG_VERSION" ]] || die "Catalog version mismatch."

python3 -m venv "$VENV"
"$VENV/bin/python" -m pip install --disable-pip-version-check "$CATALOG_DIR"
"$VENV/bin/fenrir-catalog" verify-exclusions --expected 1871
ln -sfn "$VENV/bin/fenrir-catalog" "$HOME/.local/bin/fenrir-catalog"
printf '%s\n' '{"schema":"org.fenrir.catalog.local-state.v1","private":true}' > "$CATALOG_HOME/install-state.json"
chmod 0600 "$CATALOG_HOME/install-state.json"
log "Installed private Catalog $CATALOG_VERSION at $CATALOG_COMMIT."
