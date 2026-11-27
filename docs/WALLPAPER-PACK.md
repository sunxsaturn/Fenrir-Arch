# Fenrir Wallpaper Library and Desktop Sync

Fenrir keeps two distinct wallpaper libraries:

1. **Private Catalog library:** assets with current rights evidence, explicit acquisition authorization, verified quarantine bytes, duplicate review and human acceptance. These assets can be synchronized into the local desktop folder.
2. **Public GitHub library:** separately approved, redistributable images already committed to the three public volumes. The public population is closed; existing images remain available for sync.

There is no fixed wallpaper-count target, no category quota and no requirement to expand the existing library. Rotation uses the qualifying images already available locally.

## Local rotation

Fenrir Dots rotates only readable landscape wallpapers at least 2560×1440; 3840×2160 or higher is preferred. The `fenrir-wallpaper status` command reports the qualifying local inventory and quality exclusions. Rotation uses all currently qualifying local images; no collection-size goal is defined.

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

## Public multi-volume library — included in the one-command installer

Public population is **closed on 2026-11-27**. The three existing repositories contain 1,871 images and remain active for synchronization. No further acquisition, category balancing, image-count quota or fourth volume is planned.

A fresh installation uses the documented single command:

```bash
git clone --depth=1 https://github.com/sunxsaturn/Fenrir-Arch.git ~/Fenrir && cd ~/Fenrir && ./install.sh
```

After deploying the exact pinned Fenrir Dots source, the system installer invokes **the same `fenrir-wallpaper sync-library` implementation shipped by Fenrir Dots**. It synchronizes every unique image from all active volumes to the configured rotation directory. There is no separate downloader, no second manual command and no fixed transfer limit in the fresh-install path.

Before any wallpaper bytes are downloaded, the installer:

1. Reads and validates the canonical volume registry and every active manifest.
2. Deduplicates the inventory globally by SHA-256 and computes the complete missing-image byte total.
3. Checks available space for both the destination and resumable cache. If both directories share one filesystem, it checks their combined temporary-storage requirement.
4. Stops before image transfers if either filesystem lacks enough free space.

It then runs the Dots command without `--limit`. The existing downloader resumes interrupted transfers, verifies exact byte size and SHA-256, validates decoded image format, landscape dimensions and palette, and installs files atomically without replacing existing files. The installer checks the final inventory again and only reports success when every unique manifest-listed image is present and verified.

The user can decline the image transfer when the installer runs interactively; in that case the installation stops with a clear instruction to rerun `./install.sh` to complete the full install. The GTK setup wizard has its own explicit Start action. Running `./install.sh --yes` accepts the installer confirmations, including complete public-library synchronization. A failed or interrupted transfer can be resumed by rerunning the same installer command.

For an already-installed system, the same Dots sync command remains available for reconciliation and recovery:

```bash
fenrir-wallpaper audit-library --json
fenrir-wallpaper sync-library --dry-run
fenrir-wallpaper sync-library
```

The dry-run is read-only. `--limit` is reserved for deliberate maintenance staging and is never used by the fresh installer.

The private Catalog workflow remains distinct. Newly discovered provider metadata is not downloaded or accepted automatically. Only existing assets with current per-asset rights evidence, explicit acquisition authorization, verified quarantine bytes, duplicate review and human acceptance may be synchronized locally through Fenrir Doctor. This protects the private rights lifecycle and does not grant public redistribution permission.

The dated public inventory snapshot remains 134 / 1,132 / 605 images across Volumes 01 / 02 / 03 (1,871 total). The actual nine-category distribution is documented in the [public population status](https://github.com/sunxsaturn/Fenrir-Wallpapers/blob/main/docs/POPULATION-STATUS.md).

## Rights, provenance and safety

Public images retain source, creator/credit, attribution and license metadata. Each license and provider term still applies; publication does not grant new reuse rights. Do not delete, overwrite, recompress, rename or move committed files to make category counts equal. The public hub's `manifest/volumes.json` and each volume's `manifest/index.json` are authoritative.

The private Catalog database and quarantine remain local and must never be copied into the public wallpaper repositories. Neither public wallpaper sync nor private Catalog sync creates new rights decisions or acquisition authorizations.
