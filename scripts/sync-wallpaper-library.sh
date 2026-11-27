#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "$0")" && pwd -P)/lib.sh"

[[ $# -eq 1 && ("$1" == "0" || "$1" == "1") ]] || die "Expected the installer confirmation flag (0 or 1)."
ASSUME_YES="$1"
WALLPAPER_CLI="$HOME/.local/bin/fenrir-wallpaper"

[[ -x "$WALLPAPER_CLI" ]] || die "Fenrir Dots wallpaper command is missing: $WALLPAPER_CLI"

log "Preflighting every committed image in the active public wallpaper volumes."
PLAN_JSON="$("$WALLPAPER_CLI" sync-library --dry-run --json)" || die "Could not validate all public wallpaper manifests. No wallpaper files were downloaded."

METRICS="$(printf '%s' "$PLAN_JSON" | python3 -c '
import json, sys

try:
    report = json.load(sys.stdin)
    if report.get("dry_run") is not True:
        raise ValueError("the sync plan was not read-only")
    active = report.get("active_volumes")
    if not isinstance(active, list) or not active:
        raise ValueError("the registry contains no active wallpaper volumes")
    storage = report.get("storage_preflight")
    if not isinstance(storage, dict):
        raise ValueError("the storage preflight is missing")
    names = ("manifest_records", "unique_images", "planned_downloads", "selected_downloads",
             "selected_download_bytes", "remaining_after_limit")
    values = {}
    for name in names:
        value = report.get(name)
        if isinstance(value, bool) or not isinstance(value, int) or value < 0:
            raise ValueError(f"invalid sync-plan field: {name}")
        values[name] = value
    if values["selected_downloads"] != values["planned_downloads"] or values["remaining_after_limit"] != 0:
        raise ValueError("the preflight did not select the complete missing library")
    for name in ("destination_available_bytes", "destination_required_bytes",
                 "state_available_bytes", "state_required_bytes"):
        value = storage.get(name)
        if isinstance(value, bool) or not isinstance(value, int) or value < 0:
            raise ValueError(f"invalid storage field: {name}")
    enough = storage.get("sufficient")
    if not isinstance(enough, bool):
        raise ValueError("storage sufficiency was not determined")
    output = [
        values["manifest_records"], values["unique_images"],
        values["planned_downloads"], values["selected_download_bytes"],
        storage["destination_available_bytes"], storage["destination_required_bytes"],
        storage["state_available_bytes"], storage["state_required_bytes"], int(enough),
    ]
    print("|".join(str(value) for value in output))
except (ValueError, TypeError, json.JSONDecodeError) as exc:
    print(f"Invalid Fenrir wallpaper preflight report: {exc}", file=sys.stderr)
    raise SystemExit(2)
')" || die "The public wallpaper preflight report was invalid."

IFS='|' read -r MANIFEST_RECORDS UNIQUE_IMAGES PENDING_DOWNLOADS PLANNED_BYTES \
  DESTINATION_FREE DESTINATION_REQUIRED STATE_FREE STATE_REQUIRED STORAGE_OK <<<"$METRICS"

if (( STORAGE_OK == 0 )); then
  die "Insufficient free space for the complete public wallpaper library. Destination: $DESTINATION_FREE available / $DESTINATION_REQUIRED required bytes; resumable cache: $STATE_FREE available / $STATE_REQUIRED required bytes. Free space or change wallpaper.directory, then rerun ./install.sh."
fi

log "Public wallpaper inventory: $MANIFEST_RECORDS manifest records / $UNIQUE_IMAGES unique images."
log "Missing images: $PENDING_DOWNLOADS; estimated transfer: $((PLANNED_BYTES / 1073741824)) GiB."
log "Destination and resumable-cache storage checks passed."

if (( PENDING_DOWNLOADS > 0 && ASSUME_YES == 0 )); then
  read -r -p "Download all $PENDING_DOWNLOADS missing public wallpapers now? [y/N] " ANSWER
  case "$ANSWER" in
    y|Y|yes|YES|Yes) ;;
    *) die "Wallpaper synchronization was declined. Re-run ./install.sh to complete the installation with all public wallpapers." ;;
  esac
fi

log "Downloading every missing committed image through the Fenrir Dots sync command (no --limit)."
if ! SYNC_JSON="$("$WALLPAPER_CLI" sync-library --json)"; then
  printf '%s\n' "$SYNC_JSON" >&2
  die "One or more public wallpaper downloads failed. Re-run ./install.sh to resume verified partial transfers."
fi

SYNC_METRICS="$(printf '%s' "$SYNC_JSON" | python3 -c '
import json, sys

try:
    report = json.load(sys.stdin)
    if report.get("dry_run") is not False:
        raise ValueError("sync report does not describe a completed transfer")
    fields = ("downloaded", "already_present", "failed", "unique_images", "remaining_after_limit")
    values = []
    for field in fields:
        value = report.get(field)
        if isinstance(value, bool) or not isinstance(value, int) or value < 0:
            raise ValueError(f"invalid sync result field: {field}")
        values.append(value)
    downloaded, present, failed, unique, remaining = values
    if failed or remaining or downloaded + present != unique:
        raise ValueError("the sync report does not account for every unique image")
    print("|".join(str(value) for value in values))
except (ValueError, TypeError, json.JSONDecodeError) as exc:
    print(f"Invalid Fenrir wallpaper sync report: {exc}", file=sys.stderr)
    raise SystemExit(2)
')" || {
  printf '%s\n' "$SYNC_JSON" >&2
  die "The public wallpaper sync completed with an incomplete or invalid report."
}

IFS='|' read -r DOWNLOADED PRESENT FAILED UNIQUE REMAINING <<<"$SYNC_METRICS"
log "Wallpaper sync reports $PRESENT already present + $DOWNLOADED newly downloaded = $UNIQUE unique images."

FINAL_JSON="$("$WALLPAPER_CLI" sync-library --dry-run --json)" || die "The final public wallpaper inventory could not be verified."
FINAL_METRICS="$(printf '%s' "$FINAL_JSON" | python3 -c '
import json, sys

try:
    report = json.load(sys.stdin)
    if report.get("dry_run") is not True:
        raise ValueError("final verification was not read-only")
    pending = report.get("planned_downloads")
    present = report.get("already_present")
    unique = report.get("unique_images")
    if any(isinstance(value, bool) or not isinstance(value, int) or value < 0
           for value in (pending, present, unique)):
        raise ValueError("invalid final inventory counts")
    print(f"{pending}|{present}|{unique}")
except (ValueError, TypeError, json.JSONDecodeError) as exc:
    print(f"Invalid final wallpaper inventory report: {exc}", file=sys.stderr)
    raise SystemExit(2)
')" || die "Final public wallpaper verification returned an invalid report."

IFS='|' read -r FINAL_PENDING FINAL_PRESENT FINAL_UNIQUE <<<"$FINAL_METRICS"
(( FINAL_PENDING == 0 && FINAL_PRESENT == FINAL_UNIQUE )) || die "The final inventory still has $FINAL_PENDING missing images. Rerun ./install.sh to resume."
log "Complete public wallpaper library installed and verified: all $FINAL_UNIQUE images are present."
