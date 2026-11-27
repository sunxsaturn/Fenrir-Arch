# Fenrir Wallpaper Library and Desktop Sync

Fenrir keeps two distinct wallpaper libraries:

1. **Private Catalog library:** assets with current rights evidence, explicit acquisition authorization, verified quarantine bytes, duplicate review and human acceptance. These assets can be synchronized into the local desktop folder.
2. **Public GitHub library:** separately approved, redistributable images already committed to the three public volumes. The public population is closed; existing images remain available for sync.

There is no fixed wallpaper-count target, no category quota and no requirement to expand the existing library. Rotation uses the qualifying images already available locally.

## Local rotation

Fenrir Dots rotates only readable landscape wallpapers at least 2560×1440; 3840×2160 or higher is preferred. The `fenrir-wallpaper status` command reports the qualifying local inventory and quality exclusions. Rotation does not wait for a collection goal.

The `fenrir-wallpaper` runtime applies the current palette policy: dominant yellow, orange and brown are excluded; red, purple, blue, white and black are preferred; green and neutral grey are allowed.

## Synchronize existing accepted Catalog assets

The private Catalog remains the source of truth for its accepted local library. Discovery metadata, license evidence, acquisition authorization, private quarantine, duplicate adjudication and human acceptance remain distinct lifecycle states. The desktop sync never creates or changes any of them.

In Fenrir Doctor, open **Wallpapers → Sync accepted wallpapers**:

1. Select **Preview all accepted assets**.
2. Review the read-only preflight. It scans the accepted metadata index across all pages and reports eligible copies, already-present files and blockers.
3. The synchronization action is enabled only when the metadata scan is complete, the destination is writable and there are no target conflicts.
4. Explicitly confirm **Sync accepted wallpapers**.

The sync copies every currently eligible human-accepted asset; there is no image-count target. It repeats the current rights/license checks, verifies quarantine file identity, exact byte count, SHA-256, dimensions and palette, and uses deterministic filenames. Existing local wallpapers are never overwritten or deleted. The local attribution sidecar records creator, source, license and acceptance references.

A technical metadata preflight ceiling protects the planner from unbounded scans. It is not an image target. If the planner cannot inspect the full accepted index within that safety ceiling, it blocks synchronization instead of claiming completion.

## Public multi-volume library

Public population is **closed on 2026-11-27**. The three existing repositories remain active for desktop synchronization:

| Volume | Repository | Images | Population |
|---|---|---:|---|
| 01 | [Fenrir-Wallpapers](https://github.com/sunxsaturn/Fenrir-Wallpapers) | 134 | Closed |
| 02 | [Fenrir-Wallpapers-02](https://github.com/sunxsaturn/Fenrir-Wallpapers-02) | 1,132 | Closed |
| 03 | [Fenrir-Wallpapers-03](https://github.com/sunxsaturn/Fenrir-Wallpapers-03) | 605 | Closed |
| **Total** | | **1,871** | **Existing assets only** |

All nine category folders already exist. The 2026-11-27 manifest/tree snapshot is:

| Category | Images |
|---|---:|
| Arctic Blue/Violet | 228 |
| Cinematic Nature | 228 |
| Cosmic Science Fiction | 228 |
| Deep Ocean/Bioluminescence | 221 |
| Monochrome Futuristic Architecture | 228 |
| Nordic Mythology/Fantasy | 228 |
| Obsidian Minimalism/Abstract Geometry | 171 |
| Red/Violet Dark Fantasy | 228 |
| Unsorted | 111 |
| **Total** | **1,871** |

This is the actual inventory, not a goal. The distribution is intentionally preserved. No more source acquisition, count-based balancing, category quota or fourth volume is scheduled. Existing image files and their content-addressed paths are immutable.

### Audit and synchronization

The manifest-only public audit reads the canonical volume registry, all active manifests and GitHub repository metadata. It reports SHA-256 declarations/uniqueness, path/hash consistency, dimensions, source and attribution completeness, license classification, dominant-color metadata, category distribution and approximate repository storage headroom. It does not download image bytes or inspect the local wallpaper folder. The downloaded bytes are verified separately by the sync client.

Run the audit and preview from a current Fenrir Dots installation:

```bash
fenrir-wallpaper audit-library --json
fenrir-wallpaper sync-library --dry-run
```

After reviewing the dry-run, explicitly run:

```bash
fenrir-wallpaper sync-library
```

The sync reads all active registered volumes; it does not use hard-coded repository lists. It downloads only already-published manifest entries, verifies SHA-256 and decoded-image quality, deduplicates globally and preserves existing local files. The public library remains a separate rights boundary: local Catalog acceptance alone does not grant public redistribution rights.

## Rights, provenance and safety

Public images retain source, creator/credit, attribution and license metadata. Each license and provider term still applies; publication does not grant new reuse rights. Do not delete, overwrite, recompress, rename or move committed files to make category counts equal. The public hub's `manifest/volumes.json` and each volume's `manifest/index.json` are authoritative.

The private Catalog database and quarantine remain local and must never be copied into the public wallpaper repositories. Neither public wallpaper sync nor private Catalog sync creates new rights decisions or acquisition authorizations.
