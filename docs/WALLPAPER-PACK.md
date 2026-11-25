# Fenrir wallpaper pack contract

## Visual selection criteria

Every accepted wallpaper must be a valid, decodable landscape image of at least **2560×1440**. Prefer **3840×2160 or higher**. Priority subjects are Nordic/Viking mythology, dark and medieval fantasy, warriors/battles/armor/fortresses, dragons and mythological creatures, cinematic game environments/concept art, and dramatic mountains/forests/oceans/landscapes. Preferred palette: deep black/obsidian, arctic blue, violet/purple, emerald/deep green and dramatic red accents.

The desktop target is at least **5,000 distinct validated wallpapers**. The downloader rejects duplicate IDs, filenames and SHA-256 hashes. The runtime index checks file type, decoded bytes, EXIF orientation and minimum dimensions. Rotation is deliberately paused until at least 5,000 qualifying files are present.

## Rights and source constraints

A high-resolution image is not automatically authorized for automated download or personal use. The Fenrir Wallpaper Catalog source policy currently allows metadata discovery through documented endpoints but prohibits scraping and automated mass downloads unless the current provider terms explicitly allow them and each asset has its own explicit acquisition authorization. Every image separately requires rights evidence, a human rights decision, acquisition authorization, SHA-256 validation, exact/perceptual duplicate review and explicit human acceptance. Rights acceptance does not grant redistribution permission.

The supported license identifiers are CC0-1.0, CC-BY-3.0, CC-BY-4.0, CC-BY-SA-3.0 and CC-BY-SA-4.0, subject to verification of the actual source terms and attribution/ShareAlike duties. Unknown, non-commercial, no-derivatives or undocumented rights are excluded or held for human review. Providers and artists must be credited.

The current Fenrir Wallpaper Catalog release does not publish a production desktop pack or direct wallpaper consumer. Consequently, **no 5,000-image pack is included in this desktop source archive**. It would be misleading to claim the 5,000-image requirement is already met. The installer keeps the wallpaper/theme service functional, checks the 5,000 target, and downloads only a separately prepared manifest that passes this contract.

## Installer manifest

The production pack is one JSON file, `manifest.json`, following `manifest.schema.json`. The top-level object must include:

- `schema`: `org.fenrir.wallpaper-pack`, `version`: `1`.
- `criteria`: `minimum_width` at least 2560, `minimum_height` at least 1440, preferred dimensions at least 3840×2160, `orientation` set to `landscape`, and the full preferred palette list: `obsidian`, `arctic-blue`, `violet`, `emerald`, `deep-green`, `dramatic-red`.
- `minimum_transfer_interval_seconds`: provider-approved minimum time between image requests (0.25–60 seconds, default 1.0). The downloader takes the greater of this and its local delay setting.
- `allowed_hosts`: exact HTTPS hostnames used by image URLs and redirects.
- `items`: at least 5,000 unique records.

Each image record requires ID, simple filename, HTTPS source image URL, SHA-256, actual width/height, creator/uploader, source URL, license identifier and URL, provider terms URL, non-empty references to the human rights decision, provider-terms evidence, acquisition authorization, acceptance decision and duplicate review, and explicit booleans for automated download permission, acquisition authorization, human acceptance, duplicate clearance and personal-use permission. Tags must classify the item within Fenrir's approved theme scope.

The manifest's evidence-reference strings make an audit trail traceable but do not themselves prove legal rights. Those references must resolve to genuine Catalog records and current provider terms before a release maintainer creates the manifest. The script validates the supplied assertions and image bytes; it cannot independently authenticate a creator's rights claim or prove that an evidence ID refers to a genuine record. Treat the manifest as a pack-maintainer attestation, not cryptographic proof.

## Download behavior

The installer uses this order:

1. `FENRIR_WALLPAPER_MANIFEST_URL` if set, otherwise a local `wallpapers/manifest.json` when present.
2. Strict schema/policy validation, requiring 5,000 records by default.
3. HTTPS-only transfer; exact hostname allowlist; redirects constrained to allowlisted hosts; public DNS addresses only; sequential transfer with a one-second default pause.
4. Maximum 100 MiB per image; per-file SHA-256 verification; Pillow decode and EXIF-aware dimension validation; no overwrite of an existing file whose hash differs.
5. Attribution sidecar output at `~/Pictures/Wallpapers/fenrir-attribution.json`.

To supply a reviewed pack before install, set the manifest location in the shell that launches Fenrir:

```bash
FENRIR_WALLPAPER_MANIFEST_URL='https://your-approved-host.example/path/manifest.json' bash fenrir-desktop-0.3.0.run
```

The HTTPS host must be reachable and the manifest must conform to the schema. Only use source endpoints and transfer pacing explicitly permitted by the current source terms. The installer does not discover 5,000 images, scrape providers, generate rights decisions, accept assets or infer permission from a license label.

## Runtime behavior

`fenrir-wallpaper` indexes supported JPG/JPEG/PNG/WebP files. It rejects anything below 2560×1440 landscape and remains paused until it finds at least 5,000 qualifying images; after that it rotates randomly every 15 minutes. The dominant accent extracted from each wallpaper is applied to Waybar, Kitty, Fuzzel, Mako, GTK palette files and the live Hyprland border. The obsidian base and 0.60 surface opacity remain stable to protect contrast.
