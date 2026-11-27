#!/usr/bin/env python3
"""Preflight the complete public Fenrir gallery before system changes."""
from __future__ import annotations

import json
import re
import shutil
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

REGISTRY_URL = "https://raw.githubusercontent.com/sunxsaturn/Fenrir-Wallpapers/main/manifest/volumes.json"
REGISTRY_SCHEMA = "org.fenrir.wallpaper-library-volumes.v2"
MANIFEST_SCHEMA = "org.fenrir.public-wallpapers.index.v2"
LIBRARY_ID = "fenrir-wallpapers-v2"
SHA256 = re.compile(r"^[0-9a-f]{64}$")
CATEGORIES = {
    "nordic-landscapes", "medieval-landscapes", "fantasy", "epic-battles",
    "mountains", "astronomy", "planets", "knights-in-battle", "swords",
    "magic", "nordic-mythology",
}


def fetch_json(url: str) -> dict:
    request = urllib.request.Request(
        url, headers={"User-Agent": "Fenrir-Arch-Installer/1.1", "Accept": "application/json"}
    )
    with urllib.request.urlopen(request, timeout=45) as response:
        raw = response.read(32 * 1024 * 1024 + 1)
    if len(raw) > 32 * 1024 * 1024:
        raise ValueError("gallery metadata exceeds 32 MiB")
    value = json.loads(raw.decode("utf-8"))
    if not isinstance(value, dict):
        raise ValueError("gallery metadata is not a JSON object")
    return value


def existing_free(path: Path) -> int:
    current = path.expanduser()
    while not current.exists() and current != current.parent:
        current = current.parent
    return shutil.disk_usage(current).free


def raw_url(repository: str, branch: str, path: str) -> str:
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository):
        raise ValueError("unsafe repository in registry")
    if not branch or branch.startswith("/") or ".." in branch.split("/"):
        raise ValueError("unsafe branch in registry")
    pure = Path(path)
    if pure.is_absolute() or ".." in pure.parts or not path:
        raise ValueError("unsafe manifest path in registry")
    return (
        "https://raw.githubusercontent.com/" + repository + "/"
        + urllib.parse.quote(branch, safe="/") + "/"
        + urllib.parse.quote(path, safe="/")
    )


def main() -> int:
    try:
        registry = fetch_json(REGISTRY_URL)
        if registry.get("schema") != REGISTRY_SCHEMA or registry.get("library_id") != LIBRARY_ID:
            raise ValueError("unsupported public wallpaper registry")
        population = registry.get("population", {})
        if (
            population.get("state") != "published"
            or population.get("target_unique_images") != 5000
            or population.get("published_unique_images") != 5000
            or population.get("legacy_images_reused") != 0
        ):
            raise ValueError(
                "the new 5,000-image gallery is not fully published; "
                "installer stopped before system package changes"
            )

        categories = registry.get("categories")
        if not isinstance(categories, list) or len(categories) != 11:
            raise ValueError("registry must define exactly eleven categories")
        quotas = {}
        for entry in categories:
            category_id, target = entry.get("id"), entry.get("target_count")
            if category_id not in CATEGORIES or category_id in quotas or type(target) is not int:
                raise ValueError("invalid category or duplicate category quota")
            quotas[category_id] = target
        expected = {name: 455 if index < 6 else 454 for index, name in enumerate(
            [item["id"] for item in categories]
        )}
        if set(quotas) != CATEGORIES or quotas != expected or sum(quotas.values()) != 5000:
            raise ValueError("category quotas must be six 455s and five 454s in registry order")

        volumes = registry.get("volumes")
        if not isinstance(volumes, list) or not volumes:
            raise ValueError("registry contains no volumes")
        seen_volume_ids, seen_repositories = set(), set()
        global_hashes = set()
        counts = {name: 0 for name in CATEGORIES}
        total_bytes = 0
        total_records = 0
        active = 0

        for volume in volumes:
            if volume.get("active") is not True:
                continue
            active += 1
            volume_id, repository = volume.get("id"), volume.get("repository")
            branch, manifest_path = volume.get("branch"), volume.get("manifest_path")
            if not all(isinstance(x, str) and x for x in (volume_id, repository, branch, manifest_path)):
                raise ValueError("incomplete active volume record")
            if volume_id in seen_volume_ids or repository in seen_repositories:
                raise ValueError("duplicate active volume ID or repository")
            seen_volume_ids.add(volume_id)
            seen_repositories.add(repository)
            manifest = fetch_json(raw_url(repository, branch, manifest_path))
            if (
                manifest.get("schema") != MANIFEST_SCHEMA
                or manifest.get("library_id") != LIBRARY_ID
                or manifest.get("volume_id") != volume_id
            ):
                raise ValueError(f"invalid manifest identity for {volume_id}")
            items = manifest.get("items")
            if not isinstance(items, list) or type(manifest.get("count")) is not int or manifest["count"] != len(items):
                raise ValueError(f"manifest count mismatch for {volume_id}")
            for item in items:
                path = item.get("path")
                digest = item.get("sha256")
                category = item.get("category")
                size = item.get("file_size_bytes")
                if not isinstance(path, str) or not path.startswith("images/") or ".." in Path(path).parts:
                    raise ValueError(f"unsafe image path in {volume_id}")
                if not isinstance(digest, str) or not SHA256.fullmatch(digest):
                    raise ValueError(f"invalid SHA-256 in {volume_id}")
                if digest in global_hashes:
                    raise ValueError("duplicate image content hash across public volumes")
                if category not in CATEGORIES or Path(path).parts[1] != category:
                    raise ValueError(f"invalid category/path for {path}")
                if type(size) is not int or size < 1 or size > 100 * 1024 * 1024:
                    raise ValueError(f"invalid image byte count for {path}")
                if item.get("license_identifier") not in {"Public Domain", "CC0"}:
                    raise ValueError(f"non-Public-Domain/CC0 image in public gallery: {path}")
                if not all(item.get(key) for key in ("creator", "source_page", "rights_evidence_id")):
                    raise ValueError(f"missing rights provenance in manifest record: {path}")
                global_hashes.add(digest)
                counts[category] += 1
                total_bytes += size
                total_records += 1

        if active == 0 or total_records != 5000 or len(global_hashes) != 5000:
            raise ValueError(f"expected 5000 unique manifest records, found {total_records}")
        if counts != quotas:
            raise ValueError(f"category inventory differs from quota: {counts}")

        destination = Path.home() / "Pictures" / "Wallpapers"
        state_dir = Path.home() / ".local" / "state" / "fenrir" / "wallpaper-sync"
        destination_free = existing_free(destination)
        state_free = existing_free(state_dir)
        required_with_headroom = total_bytes + 2 * 1024**3
        if destination_free < required_with_headroom or state_free < required_with_headroom:
            raise ValueError(
                "insufficient free space for the complete gallery: "
                f"need at least {required_with_headroom / 1024**3:.2f} GiB; "
                f"destination has {destination_free / 1024**3:.2f} GiB and "
                f"state filesystem has {state_free / 1024**3:.2f} GiB"
            )
        print(json.dumps({
            "ready": True,
            "library_id": LIBRARY_ID,
            "active_volumes": active,
            "unique_images": total_records,
            "category_counts": counts,
            "image_bytes": total_bytes,
            "image_gib": round(total_bytes / 1024**3, 2),
            "destination_free_gib": round(destination_free / 1024**3, 2),
            "state_free_gib": round(state_free / 1024**3, 2),
            "legacy_reused": 0,
        }, indent=2))
        return 0
    except (OSError, urllib.error.URLError, json.JSONDecodeError, ValueError, KeyError, TypeError) as exc:
        print(f"[Fenrir] Wallpaper install preflight failed: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
