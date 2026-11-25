#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"

CATALOG_REPO="${FENRIR_CATALOG_REPO:-https://github.com/sunxsaturn/Fenrir-Wallpaper-Catalog.git}"
CATALOG_COMMIT="${FENRIR_CATALOG_COMMIT:-cd4dc6be4644042b121c515f540c563cef1b1114}"
CATALOG_SOURCE="${FENRIR_CATALOG_SOURCE_DIR:-$HOME/.local/share/fenrir/catalog-source}"
CATALOG_HOME="${FENRIR_CATALOG_HOME:-$HOME/.local/share/fenrir/catalog}"
CATALOG_DB="$CATALOG_HOME/catalog.sqlite3"
QUARANTINE_ROOT="$CATALOG_HOME/quarantine"
VENV="$HOME/.local/share/fenrir/catalog-venv"
WRAPPER="$HOME/.local/bin/fenrir-catalog"

[[ "$CATALOG_COMMIT" =~ ^[0-9a-f]{40}$ ]] || die "FENRIR_CATALOG_COMMIT must be a full 40-character Git commit SHA."
mkdir -p "$(dirname -- "$CATALOG_SOURCE")" "$CATALOG_HOME" "$QUARANTINE_ROOT" "$HOME/.local/bin"
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
  git clone "$CATALOG_REPO" "$CATALOG_SOURCE"
  git -C "$CATALOG_SOURCE" checkout --detach "$CATALOG_COMMIT"
fi

actual="$(git -C "$CATALOG_SOURCE" rev-parse HEAD)"
[[ "$actual" == "$CATALOG_COMMIT" ]] || die "Catalog checkout mismatch: expected $CATALOG_COMMIT, found $actual."
version="$(python3 -c 'import sys,tomllib; print(tomllib.load(open(sys.argv[1], "rb"))["project"]["version"])' "$CATALOG_SOURCE/pyproject.toml")"
[[ "$version" == "0.19.0" ]] || die "Fenrir Wallpaper Catalog 0.19.0 is required; found $version."

required_files=(
  pyproject.toml
  src/fenrir_catalog/cli.py
  src/fenrir_catalog/desktop_sync.py
  src/fenrir_catalog/consumer.py
  src/fenrir_catalog/library.py
  src/fenrir_catalog/schemas/wallpaper-library-manifest-v1.schema.json
  tests/test_desktop_sync.py
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
