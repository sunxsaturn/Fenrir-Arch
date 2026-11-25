# Fenrir wallpaper pack

This directory intentionally does not contain fabricated image URLs or scraped artwork.
The installer consumes `manifest.json` here, or a remote HTTPS manifest supplied with
`FENRIR_WALLPAPER_MANIFEST_URL`. The manifest must contain at least 5,000 unique items
and pass `manifest.schema.json` plus the stricter runtime checks in
`scripts/download_wallpaper_pack.py`.

## Visual target

- Landscape only; minimum decoded resolution: **2560×1440**.
- Preferred resolution: **3840×2160 or higher**.
- Contemporary digital art and premium desktop backgrounds.
- Priority: Nordic mythology/Viking fantasy; dark and medieval fantasy; warriors,
  battles, armor, fortresses, dragons and mythological creatures; cinematic game
  environments/concept art; mountains, forests, oceans and dramatic landscapes.
- Preferred palette: obsidian/deep black, arctic blue, violet/purple, emerald/deep
  green, with restrained dramatic red accents.
- Allowed license policy: CC0-1.0, CC BY 3.0/4.0, and CC BY-SA 3.0/4.0, each with
  actual source, license, creator and provider-terms evidence.

## Required per-image evidence

Every entry needs a unique ID and SHA-256, exact HTTPS download/source/license/terms
URLs, creator attribution, measured width/height, non-empty curation tags, an explicit
human-approved rights decision, explicit provider permission for automated download,
per-asset acquisition authorization, human acceptance, duplicate clearance, and
personal-use permission. The downloader verifies the image bytes, checksum, format,
orientation and actual dimensions before publishing it into the local wallpaper folder.

The Fenrir Wallpaper Catalog deliberately separates discovery, rights review,
authorization, acquisition, acceptance and redistribution. It does not authorize a
5,000-image mass download merely because an API exposes image URLs. A ready manifest
must be produced from the individually reviewed catalog evidence. The pack is for
local personal use; it must not be redistributed unless every item separately permits it.
