# Fenrir Desktop 2.0 rebuild plan

## Phase A — component foundations

1. Rebuild the private Catalog's fixed 5,000-image policy, exact category quotas, palette and rights rules.
2. Rebuild Dots' Fimbulwinter design system, shared glass state, Hyprland session, Control Center and Doctor.
3. Rebuild Arch's safe GTK4 installer, package transaction, component pinning, system services and acceptance harness.
4. Establish the new public wallpaper registry and empty volume manifests.

## Phase B — wallpaper population

Use metadata-only discovery campaigns across providers with documented open-access or public-domain terms. Preserve creator, source URL, object ID, license, attribution and the evidence used for each decision. Download only to private quarantine. Decode and validate actual image bytes, compute SHA-256, enforce the private legacy exclusion set, apply palette/resolution checks, perform duplicate review and require publication approval before export.

The exact global distribution is six categories × 455 images plus five categories × 454 images = 5,000.

## Phase C — install integration

Pin immutable Dots and Catalog commits. The installer performs one complete registry/manifest/storage preflight, asks for confirmation in the guided wizard, downloads every active manifest-listed image, verifies all bytes, and performs a final zero-missing inventory check. There is no separate wallpaper downloader.

## Phase D — acceptance

Run CI and a disposable clean Arch VM. Validate versions, SDDM, Hyprland, AMD RADV, desktop services, gaming, audio, Wake-on-LAN, Ollama Vulkan, complete wallpaper inventory and protected storage. Release only after real VM acceptance; mocked tests do not count as end-to-end completion.
