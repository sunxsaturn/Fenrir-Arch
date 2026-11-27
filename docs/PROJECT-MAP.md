# Fenrir project map

This is the ecosystem navigation page for Fenrir Desktop. Start here when you need to find the correct repository, understand how the pieces fit together, or decide where a change belongs.

## Current integrated release set

| Component | Current release | Installed/pinned by |
|---|---:|---|
| Fenrir-Arch | 0.9.4 | System installer and deployment |
| Fenrir-Dots | 0.14.1 | Fenrir-Arch 0.9.4, exact commit `9b9e85c084e397141389c28778988bf009280fcf` |
| Fenrir Wallpaper Catalog | 0.36.0 | Fenrir-Arch 0.9.4, exact commit `4e6ed27e6425956ea2fa444db5fc03193767025c` |

The release values above describe the latest integrated Arch release, not a floating checkout of each repository's `main` branch. See [Versioning and release policy](VERSIONING.md).

## Repositories at a glance

| Repository | Visibility | Owns | Start here |
|---|---|---|---|
| [Fenrir-Arch](https://github.com/sunxsaturn/Fenrir-Arch) | Public | Arch Linux installation, package selection, system services, deployment safety and component pins | [README](../README.md) · [Install guide](ARCH-BASE.md) |
| [Fenrir-Dots](https://github.com/sunxsaturn/Fenrir-Dots) | Public | Hyprland desktop, user configuration, Settings, Welcome, Doctor, wallpaper rotation and desktop commands | [README](https://github.com/sunxsaturn/Fenrir-Dots#readme) · [Docs index](https://github.com/sunxsaturn/Fenrir-Dots/tree/main/docs) |
| [Fenrir-Wallpaper-Catalog](https://github.com/sunxsaturn/Fenrir-Wallpaper-Catalog) | Private | Discovery metadata, provenance, licensing evidence, rights review, authorization, quarantine, deduplication, acceptance and curated collections | [README](https://github.com/sunxsaturn/Fenrir-Wallpaper-Catalog#readme) · [Architecture](https://github.com/sunxsaturn/Fenrir-Wallpaper-Catalog/blob/main/docs/ARCHITECTURE.md) · [Usage](https://github.com/sunxsaturn/Fenrir-Wallpaper-Catalog/blob/main/docs/USAGE.md) |
| [Fenrir-Wallpapers](https://github.com/sunxsaturn/Fenrir-Wallpapers) | Public | Wallpaper library hub and Volume 01; canonical volume registry and publication tooling | [README](https://github.com/sunxsaturn/Fenrir-Wallpapers#readme) · [Volume registry](https://github.com/sunxsaturn/Fenrir-Wallpapers/blob/main/manifest/volumes.json) |
| [Fenrir-Wallpapers-02](https://github.com/sunxsaturn/Fenrir-Wallpapers-02) | Public | Volume 02 image files and volume manifest | [README](https://github.com/sunxsaturn/Fenrir-Wallpapers-02#readme) · [Manifest](https://github.com/sunxsaturn/Fenrir-Wallpapers-02/blob/main/manifest/index.json) |
| [Fenrir-Wallpapers-03](https://github.com/sunxsaturn/Fenrir-Wallpapers-03) | Public | Volume 03 image files and volume manifest; balanced overflow using live manifests and shared capacity | [README](https://github.com/sunxsaturn/Fenrir-Wallpapers-03#readme) · [Manifest](https://github.com/sunxsaturn/Fenrir-Wallpapers-03/blob/main/manifest/index.json) |

The hub registry is authoritative for active volume discovery. Desktop code must read it rather than hard-code the current number of volumes.

## How the system fits together

```text
Fenrir-Arch
  ├── pins and installs Fenrir-Dots
  └── pins and installs the private Wallpaper Catalog

Fenrir-Dots
  ├── Settings / Welcome / Doctor
  ├── wallpaper rotation and public-library mirror sync
  └── local integration with the private Catalog

Private Wallpaper Catalog
  Discovery metadata
    → source terms and rights evidence
    → explicit per-asset acquisition authorization
    → verified quarantine
    → exact/perceptual duplicate review
    → human rights decision and acceptance
    → curated collections
    → local desktop sync

Separately approved public publication
  → Fenrir-Wallpapers hub registry
  → Volume 01 / Volume 02 / Volume 03 / future volumes
  → fenrir-wallpaper sync-library
  → one local wallpaper directory and normal rotation
```

The private Catalog and public mirror are deliberately separate. Catalog acceptance permits the defined local desktop workflow; public redistribution requires its own per-asset publication approval and compatible provider terms.

## Where changes belong

| Change | Correct home |
|---|---|
| Arch packages, system services, installer prompts, disk safety, Wake-on-LAN and deploy logic | Fenrir-Arch |
| Hyprland behavior, dotfiles, desktop UI, user commands, wallpaper rotation and local sync UX | Fenrir-Dots |
| Provider adapters, discovery profiles, metadata schemas, rights records, acquisition, quarantine, duplicate review, human acceptance and curated Catalog data | Fenrir-Wallpaper-Catalog |
| Public image bytes, attribution manifests, volume registry and public population workflows | Fenrir-Wallpapers and numbered volumes |

Avoid putting application logic in the installer, duplicating Catalog rights rules in the desktop, or hard-coding volume names in the desktop consumer.

## Navigation by task

### Install and maintain Fenrir

- [Minimal Arch base and preflight](ARCH-BASE.md)
- [Post-install guide](POST-INSTALL.md)
- [Installer source](../install.sh)
- [System and storage helpers](../scripts/)

### Desktop and user experience

- [Fenrir Dots](https://github.com/sunxsaturn/Fenrir-Dots)
- [Fenrir Doctor source map](https://github.com/sunxsaturn/Fenrir-Dots/tree/main/apps/fenrir-doctor)
- [Wallpaper library sync guide](https://github.com/sunxsaturn/Fenrir-Dots/blob/main/docs/WALLPAPER-LIBRARY.md)

### Wallpaper lifecycle and public library

- [Catalog architecture](https://github.com/sunxsaturn/Fenrir-Wallpaper-Catalog/blob/main/docs/ARCHITECTURE.md)
- [Catalog integration contract](https://github.com/sunxsaturn/Fenrir-Wallpaper-Catalog/blob/main/docs/INTEGRATION.md)
- [Catalog source and provider inventory](https://github.com/sunxsaturn/Fenrir-Wallpaper-Catalog/blob/main/docs/SOURCES.md)
- [Public library and publication workflow](https://github.com/sunxsaturn/Fenrir-Wallpapers#publish-accepted-catalog-assets)
- [Live volume registry](https://github.com/sunxsaturn/Fenrir-Wallpapers/blob/main/manifest/volumes.json)

## Release and compatibility model

Version numbers advance independently per repository. Feature milestones advance the minor component; maintenance releases advance the patch component. The installer pins full commit SHAs and expected versions. Never update a version label without updating its authoritative metadata and release tag.

Fenrir-Arch pins exact Fenrir-Dots and Catalog commit SHAs. The installer verifies each checkout, component version and required source-file set before deployment. Treat those pins as the compatibility contract; never replace them with a floating `main` checkout.

When changing a pinned component:

1. Complete and test the component change in its own repository.
2. Release the component and record its exact merged commit SHA.
3. Update the matching installer pin, expected version and required-file contract in Fenrir-Arch.
4. Run the full installer CI against that exact companion checkout.
5. Publish the installer release only after the integration check passes.

The wallpaper volumes have independent image manifests. The hub registry determines which volumes are active; manifests remain the source of truth for per-volume files and counts.

## Repository entry points

| Repository | Code | Tests | CI / release |
|---|---|---|---|
| Fenrir-Arch | `install.sh`, `scripts/`, `systemd/` | `tests/` | `.github/workflows/` |
| Fenrir-Dots | `bin/`, `apps/`, `config/`, `systemd/user/` | `tests/` | `.github/workflows/` |
| Wallpaper Catalog | `src/fenrir_catalog/`, `pyproject.toml` | `tests/` | `.github/workflows/` |
| Wallpaper library | `Fenrir Wallpapers/`, `manifest/`, `tools/` | importer-specific checks | `.github/workflows/` |

## Safety boundaries

- The installer does not partition, format or modify user data-volume contents.
- The Catalog database and quarantine are private local data and must never be committed to the public wallpaper repositories.
- Discovery is metadata-only; it does not imply rights clearance or acquisition authorization.
- Local Catalog sync and public redistribution are separate operations and approvals.
- Public-library sync is additive, verifies committed bytes and never overwrites existing local files.
- Do not commit credentials, private Catalog databases, quarantine assets or unapproved third-party images.
