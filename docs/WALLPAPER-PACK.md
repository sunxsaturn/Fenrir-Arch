# Fenrir Wallpaper Catalog and Desktop Sync

Fenrir uses the rights-aware **Fenrir Wallpaper Catalog** as the source of truth for discovered, acquired, reviewed and accepted assets. Fenrir Doctor provides a local desktop integration that can grow the wallpaper folder to 5,000, 10,000 or 20,000 images.

## Collection targets

The available targets are total qualifying local images, not a promise that the Catalog already contains that number:

- 20,000 images — recommended default for new installations.
- 10,000 images — selectable smaller target.
- 5,000 images — selectable smaller target.

Existing qualifying files in `~/Pictures/Wallpapers` count toward the target. Rotation can use the qualifying local images already present; reaching 20,000 is a collection goal, not a requirement to enable rotation. The runtime validates landscape image files at least 2560×1440; 3840×2160 or higher is preferred.

## Rights and acquisition workflow

The Catalog separates each stage. Discovery stores metadata only. A source must be enabled under current provider terms; each asset needs its own explicit acquisition authorization before transfer into private quarantine. Validation and SHA-256 evidence, exact/perceptual duplicate review, a human rights decision and explicit human acceptance are separate records.

The desktop sync command is intentionally stricter than simple acceptance. It copies only catalog assets that:

1. Have an explicit accepted-library decision.
2. Have `rights_status = human_approved`.
3. Have `license_decision = approved` and a license identifier.
4. Are locally stored in the private quarantine, not a provider URL.
5. Are valid landscape JPEG, PNG or WebP files at least 2560×1440.
6. Pass the Catalog consumer's no-follow path, SHA-256 and exact byte-count checks.

Human acceptance is not a grant of redistribution rights. The sync operation is local personal-library copying only: it does not upload or publish images, create public URLs, change rights or acceptance decisions, or authorize sharing. Follow each image's actual license and attribution requirements before redistributing it.

## Using Fenrir Doctor

Open **Fenrir Doctor** from the application launcher or press `Super+A`. Select **Wallpapers** to see:

- Accepted records in the Catalog.
- Current local image count.
- Selected total-image target and remaining count.
- The latest synchronization status and log.

The recommended default is 20,000; 5,000 and 10,000 remain selectable. First select **Preview sync plan**. Synchronization is enabled only after the bounded, read-only Catalog preflight confirms a complete, writable and conflict-free plan. Then select **Sync accepted wallpapers** and confirm the explicit local copy operation. The Catalog revalidates each quarantine file's bytes, SHA-256 and palette immediately before each copy. It uses deterministic content-addressed filenames, does not overwrite existing user files, and maintains `~/Pictures/Wallpapers/fenrir-catalog-attribution.json` with creator, source, license and acceptance references.

## Command-line use

The Catalog is installed in an isolated virtual environment. Use the wrapper installed by Fenrir:

```bash
fenrir-catalog catalog library facets \
  --database "$HOME/.local/share/fenrir/catalog/catalog.sqlite3"
```

To synchronize directly:

```bash
fenrir-catalog catalog library sync \
  --database "$HOME/.local/share/fenrir/catalog/catalog.sqlite3" \
  --quarantine-root "$HOME/.local/share/fenrir/catalog/quarantine" \
  --destination "$HOME/Pictures/Wallpapers" \
  --target-count 20000
```

Allowed targets are exactly 5000, 10000 and 20000. The command rejects `/mnt/storage` destinations and symlink wallpaper folders. It retains attribution metadata locally and does not delete existing images.

## Sources and image quality

Priority subjects remain Nordic/Viking mythology, dark and medieval fantasy, warriors/battles/armor/fortresses, dragons and mythological creatures, cinematic game environments/concept art, and dramatic mountains/forests/oceans/landscapes. The enforced `fenrir-wallpaper-palette-v1` policy excludes dominant yellow, orange and brown. Red, purple, blue, white and black are preferred; green and neutral grey are allowed. The Catalog checks decoded image pixels at acceptance, local counting and desktop synchronization.

A high-resolution image is not automatically authorized for acquisition or redistribution. Use the Catalog's documented source registry, provider terms, rights evidence, duplicate review, human acceptance and acquisition authorization. Unknown, conflicting, non-commercial, no-derivatives or undocumented rights remain excluded or held for human review. The project will not scrape providers or manufacture rights evidence to hit a numerical target.

## Attribution and verification

Every copied Catalog asset is named deterministically from its asset identifier and SHA-256. The local attribution sidecar retains:

- Creator, source URL and license identifier/URL.
- Actual dimensions and SHA-256.
- Catalog asset identifier and acceptance decision reference.

The Catalog's local database and quarantine remain under `~/.local/share/fenrir/catalog`; they are not stored in GitHub. Image files and the attribution sidecar live under `~/Pictures/Wallpapers`. Neither the source repository nor a GitHub release contains user-owned image files, credentials or catalog databases.
