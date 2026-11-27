# Changelog

## 1.0.0 — 2026-11-27

- First stable Fenrir release; the `0.9` development line advances to canonical `1.0.0`.
- The documented single-command installer now deploys the pinned desktop and downloads the complete existing public wallpaper library into its rotation directory.
- Added complete manifest preflight, destination/cache free-space checks, resumable transfers and final zero-missing verification; no fixed wallpaper-count goal is used.
- Align installer documentation and component pins to Fenrir Dots 0.16.0 and Wallpaper Catalog 0.38.0.
- Keep public-library population closed; all existing published images remain available for synchronization.


## 0.9.6 — 2026-11-27

- Pin Fenrir-Dots 0.15.0 and Wallpaper Catalog 0.37.0 to exact immutable commits.
- Integrate target-free accepted-asset sync and the public-library metadata audit in Fenrir Doctor.
- Close public wallpaper population at the existing 1,871 committed images across three active sync volumes.
- Remove all recommended image-count goals and category-balancing targets from installer documentation.


Notable changes to the Fenrir-Arch installer and integration layer.

## 0.9.5 — 2026-11-27

- Rename the installer feature-list entry from the retired “Sun AI” name to Fenrir Doctor.
- Clarify that Ollama starts on demand and model weights are never downloaded automatically.
- Keep the integrated Dots 0.14.1 and Wallpaper Catalog 0.36.0 pins unchanged.
