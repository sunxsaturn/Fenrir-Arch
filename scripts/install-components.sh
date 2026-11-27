#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
LOCK="$ROOT/components.lock"
die() { printf '[Fenrir] ERROR: %s\n' "$*" >&2; exit 1; }

[[ -f "$LOCK" ]] || die "Missing components.lock."
read -r DOTS_COMMIT CATALOG_COMMIT < <(python3 - "$LOCK" <<'PY'
import json, sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(data.get("dots_commit", ""), data.get("catalog_commit", ""))
PY
)
[[ "$DOTS_COMMIT" =~ ^[0-9a-f]{40}$ ]] || die "Fenrir-Dots commit pin is not finalized."
[[ "$CATALOG_COMMIT" =~ ^[0-9a-f]{40}$ ]] || die "Catalog commit pin is not finalized."

FENRIR_ROOT="$HOME/.local/share/fenrir"
DOTS_DIR="$FENRIR_ROOT/dots"
CATALOG_DIR="$FENRIR_ROOT/catalog-source"
mkdir -p "$FENRIR_ROOT" "$HOME/.local/bin"

checkout_exact() {
  local repo="$1" directory="$2" commit="$3"
  if [[ -e "$directory" && ! -d "$directory/.git" ]]; then
    die "$directory exists but is not a Git checkout. It was not overwritten."
  fi
  if [[ ! -d "$directory/.git" ]]; then
    git clone --no-checkout "$repo" "$directory" ||
      die "Could not clone $repo. Check GitHub access and credentials."
  fi
  git -C "$directory" fetch --depth=1 origin "$commit" ||
    die "Could not fetch pinned commit $commit from $repo."
  git -C "$directory" checkout --detach "$commit"
  [[ "$(git -C "$directory" rev-parse HEAD)" == "$commit" ]] ||
    die "Checkout pin mismatch for $directory."
}

checkout_exact "https://github.com/sunxsaturn/Fenrir-Dots.git" "$DOTS_DIR" "$DOTS_COMMIT"
checkout_exact "https://github.com/sunxsaturn/Fenrir-Wallpaper-Catalog.git" "$CATALOG_DIR" "$CATALOG_COMMIT"

DOTS_VERSION="$(cat "$DOTS_DIR/VERSION")"
CATALOG_VERSION="$(python3 - "$CATALOG_DIR/pyproject.toml" <<'PY'
import sys, tomllib
from pathlib import Path
print(tomllib.loads(Path(sys.argv[1]).read_text())["project"]["version"])
PY
)"
[[ "$DOTS_VERSION" == "0.17.0" ]] || die "Expected Fenrir-Dots 0.17.0; found $DOTS_VERSION."
[[ "$CATALOG_VERSION" == "0.39.0" ]] || die "Expected Catalog 0.39.0; found $CATALOG_VERSION."

DOTS_VENV="$FENRIR_ROOT/dots-venv"
CATALOG_VENV="$FENRIR_ROOT/catalog-venv"
python3 -m venv --system-site-packages "$DOTS_VENV"
python3 -m venv --system-site-packages "$CATALOG_VENV"
"$DOTS_VENV/bin/python" -m pip install --upgrade pip
"$DOTS_VENV/bin/python" -m pip install --no-deps "$DOTS_DIR"
"$CATALOG_VENV/bin/python" -m pip install --upgrade pip
"$CATALOG_VENV/bin/python" -m pip install --no-deps "$CATALOG_DIR"

ln -sfn "$DOTS_VENV/bin/fenrir-glass" "$HOME/.local/bin/fenrir-glass"
ln -sfn "$CATALOG_VENV/bin/fenrir-catalog" "$HOME/.local/bin/fenrir-catalog"

[[ -f "$DOTS_DIR/scripts/install-dots.sh" ]] ||
  die "Pinned Fenrir-Dots source is missing scripts/install-dots.sh."
bash "$DOTS_DIR/scripts/install-dots.sh"

# The complete public wallpaper sync is the final install gate. This is the
# single integrated sync step, not a separate post-install downloader.
[[ -x "$DOTS_VENV/bin/fenrir-wallpaper" ]] ||
  die "Pinned Fenrir-Dots wallpaper command was not installed in its virtual environment."
"$DOTS_VENV/bin/fenrir-wallpaper" sync-library --json

python3 - "$FENRIR_ROOT/installed-versions.json" "$ROOT/VERSION" "$DOTS_VERSION" "$CATALOG_VERSION" <<'PY'
import json, re, sys
from pathlib import Path
arch = Path(sys.argv[2]).read_text(encoding="utf-8").strip()
versions = {
    "Fenrir-Arch": arch,
    "Fenrir-Dots": sys.argv[3],
    "Fenrir-Wallpaper-Catalog": sys.argv[4],
}
if any(not re.fullmatch(r"\d+\.\d+\.\d+", value) for value in versions.values()):
    raise SystemExit("Invalid non-canonical Fenrir component version.")
target = Path(sys.argv[1])
target.parent.mkdir(parents=True, exist_ok=True)
temporary = target.with_suffix(".tmp")
temporary.write_text(json.dumps(versions, indent=2) + "\n", encoding="utf-8")
temporary.replace(target)
print(versions)
PY
