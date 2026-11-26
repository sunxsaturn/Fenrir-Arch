#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"

CATALOG_REPO="${FENRIR_CATALOG_REPO:-https://github.com/sunxsaturn/Fenrir-Wallpaper-Catalog.git}"
CATALOG_COMMIT="${FENRIR_CATALOG_COMMIT:-b75a26c5bf53dd1ca4517b7b44166c74d6b3e2cc}"
CATALOG_SOURCE="${FENRIR_CATALOG_SOURCE_DIR:-$HOME/.local/share/fenrir/catalog-source}"
CATALOG_HOME="${FENRIR_CATALOG_HOME:-$HOME/.local/share/fenrir/catalog}"
CATALOG_DB="$CATALOG_HOME/catalog.sqlite3"
QUARANTINE_ROOT="$CATALOG_HOME/quarantine"
VENV="$HOME/.local/share/fenrir/catalog-venv"
WRAPPER="$HOME/.local/bin/fenrir-catalog"

[[ "$CATALOG_COMMIT" =~ ^[0-9a-f]{40}$ ]] || die "FENRIR_CATALOG_COMMIT must be a full 40-character Git commit SHA."

assert_safe_local_path() {
  local path="$1" current="$1"
  case "$path" in
    /mnt/storage|/mnt/storage/*) die "Catalog data paths inside /mnt/storage are protected and cannot be used." ;;
  esac
  while [[ "$current" != "/" ]]; do
    [[ ! -L "$current" ]] || die "Refusing Catalog path containing a symbolic link: $current"
    current="$(dirname -- "$current")"
  done
}

for path in "$CATALOG_SOURCE" "$CATALOG_HOME" "$QUARANTINE_ROOT" "$VENV" "$WRAPPER"; do
  assert_safe_local_path "$path"
done
mkdir -p "$(dirname -- "$CATALOG_SOURCE")" "$CATALOG_HOME" "$QUARANTINE_ROOT" "$HOME/.local/bin"
for path in "$CATALOG_SOURCE" "$CATALOG_HOME" "$QUARANTINE_ROOT" "$VENV" "$WRAPPER"; do
  assert_safe_local_path "$path"
done
chmod 0700 "$CATALOG_HOME" "$QUARANTINE_ROOT"

if [[ -d "$CATALOG_SOURCE/.git" ]]; then
  remote="$(git -C "$CATALOG_SOURCE" remote get-url origin)"
  case "$remote" in
    "$CATALOG_REPO"|"https://github.com/sunxsaturn/Fenrir-Wallpaper-Catalog"|git@github.com:sunxsaturn/Fenrir-Wallpaper-Catalog.git) ;;
    *) die "Unexpected remote in existing Fenrir Wallpaper Catalog checkout: $remote" ;;
  esac
  if [[ "$(git -C "$CATALOG_SOURCE" rev-parse --is-shallow-repository)" == "true" ]]; then
    git -C "$CATALOG_SOURCE" fetch --unshallow origin
  else
    git -C "$CATALOG_SOURCE" fetch --prune origin
  fi
  git -C "$CATALOG_SOURCE" checkout --detach "$CATALOG_COMMIT"
elif [[ -e "$CATALOG_SOURCE" ]]; then
  die "$CATALOG_SOURCE exists but is not a Git checkout. Move it aside; nothing there was overwritten."
else
  if ! git clone "$CATALOG_REPO" "$CATALOG_SOURCE"; then
    die "Fenrir Wallpaper Catalog is a private GitHub repository. Configure GitHub authentication (SSH key or credential helper) for this user, then rerun the installer. No access token is stored by Fenrir."
  fi
  git -C "$CATALOG_SOURCE" checkout --detach "$CATALOG_COMMIT"
fi

actual="$(git -C "$CATALOG_SOURCE" rev-parse HEAD)"
[[ "$actual" == "$CATALOG_COMMIT" ]] || die "Catalog checkout mismatch: expected $CATALOG_COMMIT, found $actual."
version="$(python3 -c 'import sys,tomllib; print(tomllib.load(open(sys.argv[1], "rb"))["project"]["version"])' "$CATALOG_SOURCE/pyproject.toml")"
[[ "$version" == "0.29.0" ]] || die "Fenrir Wallpaper Catalog 0.29.0 is required; found $version."

required_files=(
  pyproject.toml
  src/fenrir_catalog/__init__.py
  src/fenrir_catalog/cli.py
  src/fenrir_catalog/desktop_sync.py
  src/fenrir_catalog/acquisition_queue.py
  src/fenrir_catalog/rights_review.py
  src/fenrir_catalog/rights_assignments.py
  src/fenrir_catalog/rights_review_board.py
  src/fenrir_catalog/quarantine_review.py
  tests/test_acceptance.py
  src/fenrir_catalog/rights_board_assets/index.html
  src/fenrir_catalog/rights_board_assets/app.js
  src/fenrir_catalog/rights_board_assets/style.css
  tests/test_rights_review.py
  tests/test_rights_assignments.py
  tests/test_rights_review_board.py
  src/fenrir_catalog/consumer.py
  src/fenrir_catalog/library.py
  src/fenrir_catalog/picker.py
  src/fenrir_catalog/picker_assets/index.html
  src/fenrir_catalog/picker_assets/app.js
  src/fenrir_catalog/picker_assets/style.css
  tests/test_picker.py
  src/fenrir_catalog/schemas/wallpaper-library-manifest-v1.schema.json
  tests/test_desktop_sync.py
  src/fenrir_catalog/campaign.py
  src/fenrir_catalog/campaign_profiles.py
  src/fenrir_catalog/adapters/commons.py
  src/fenrir_catalog/palette_policy.py
  src/fenrir_catalog/palette_index.py
  src/fenrir_catalog/collection_portability.py
  src/fenrir_catalog/quality_dashboard.py
  src/fenrir_catalog/migrations/0014_discovery_campaigns.sql
  tests/test_workbench.py
  tests/test_campaign.py
  tests/test_acquisition_queue.py
  tests/test_palette_policy.py
  tests/test_palette_index.py
)
for file in "${required_files[@]}"; do
  [[ -f "$CATALOG_SOURCE/$file" ]] || die "Fenrir Wallpaper Catalog source is incomplete: missing $file"
done

if [[ ! -x "$VENV/bin/python" ]]; then
  python3 -m venv "$VENV"
fi
"$VENV/bin/python" -m pip install --disable-pip-version-check --no-cache-dir "$CATALOG_SOURCE[image-validation,manifest-client]"
"$VENV/bin/fenrir-catalog" init --database "$CATALOG_DB"
chmod 0600 "$CATALOG_DB"
chmod 0700 "$QUARANTINE_ROOT"

if [[ -e "$WRAPPER" || -L "$WRAPPER" ]]; then
  [[ ! -L "$WRAPPER" && -f "$WRAPPER" ]] || die "Refusing to replace a non-regular fenrir-catalog launcher."
  stamp="$(date +%Y%m%d-%H%M%S)"
  backup="$HOME/.local/state/fenrir/backups/$stamp/.local/bin/fenrir-catalog"
  mkdir -p "$(dirname -- "$backup")"
  cp -a "$WRAPPER" "$backup"
fi
temporary="$WRAPPER.tmp.$$"
cat > "$temporary" <<'WRAPPER'
#!/usr/bin/env bash
set -Eeuo pipefail
exec "$HOME/.local/share/fenrir/catalog-venv/bin/fenrir-catalog" "$@"
WRAPPER
chmod 0755 "$temporary"
mv -f "$temporary" "$WRAPPER"

log "Fenrir Wallpaper Catalog $version installed at $CATALOG_SOURCE"
log "Private database initialized at $CATALOG_DB"
log "Quarantine root: $QUARANTINE_ROOT"
log "fenrir-catalog CLI is available at $WRAPPER"
