# Fenrir Arch + Fenrir Dots

**Version:** 1.0.0

**Project navigation:** [Fenrir ecosystem map](docs/PROJECT-MAP.md) · [Versioning policy](docs/VERSIONING.md) · [Install guide](docs/ARCH-BASE.md) · [Post-install guide](docs/POST-INSTALL.md) · [Wallpaper integration](docs/WALLPAPER-PACK.md)

Fenrir is an original Arch Linux + Hyprland desktop environment, shipped in two repositories using the installer/dotfiles model.

## One-command installation

Start from a minimal Arch Linux x86_64 installation with systemd, network access, Git and a regular sudo-enabled account. Do not preinstall KDE, GNOME or a competing Hyprland dotfiles distribution.

```bash
git clone --depth=1 https://github.com/sunxsaturn/Fenrir-Arch.git ~/Fenrir && cd ~/Fenrir && ./install.sh
```

The default command opens the GTK4 guided installer; on a clean text-only TTY it bootstraps Cage and presents the same wizard full-screen. In an existing Wayland/X11 session it opens normally; use `./install.sh --cli` for a terminal-only install. The first login guide and Fenrir Control Center provide tutorials, keybindings and display/appearance/wallpaper/power customization. The installer fetches Fenrir-Dots at an exact immutable commit, validates the component version and required source tree, then deploys the system and dotfiles. As the final installation stage, it runs the Dots-owned public-library sync command to download every image in all active wallpaper volumes. It checks destination and resumable-cache free space, uses no transfer limit, verifies each image and confirms that no published image is missing. Fenrir Doctor and the pinned Fenrir Wallpaper Catalog are required components. The Ollama runtime is installed with the profile and starts on demand; model weights remain opt-in and are never downloaded automatically. The Catalog runs in an isolated Python environment with a private local database and quarantine. Catalog 0.38.0 syncs all currently eligible human-accepted assets without a wallpaper-count target. Its read-only preflight traverses the accepted metadata index and blocks incomplete scans; portfolio output reports observed inventory and acceptance activity, not a completion forecast. Existing per-asset rights, duplicate review and human acceptance gates remain unchanged. The Catalog source repository is private, so a fresh installation must already have GitHub access configured for this account (SSH key or Git credential helper); Fenrir never embeds or stores an access token. It performs one synchronized `pacman -Syu`, enables official multilib for Steam, installs the gaming and audio suites, obtains Mozilla Firefox Nightly with SHA-512 verification, deploys the dotfiles, sets US International with dead keys, enables Ethernet Wake-on-LAN where supported, and adds eligible fixed data filesystems to `/etc/fstab` by UUID.

Review the initial prompt and every package transaction. REAPER has its own EULA. ReaPack is installed from the official Arch Extra repository as an optional package; it is not fetched from AUR or installed as an unverified third-party binary. It does not partition/format drives, edit data-volume contents, install a bootloader, modify firmware, or reboot.

Options: `--dry-run`, `--cli`, `--no-reapack`, `--no-storage`, `--no-wol`, `--yes`, `--help`. Fenrir Doctor and the Wallpaper Catalog cannot be disabled because they are required Fenrir components. See `docs/POST-INSTALL.md`.

## Repositories

- **Fenrir-Arch**: installer, packages, system services, disk/keyboard/WoL integration and pinned Catalog deployment.
- **Fenrir-Dots 0.16.0**: Hyprland Lua config, Waybar, Fuzzel, Kitty, Mako, GTK, icons, Fimbulwinter Glass, wallpaper rotation/theme services, GTK4 Fenrir Control Center and Fenrir Doctor, now integrated with the Catalog’s guarded human Rights Review Studio.
  - Fenrir Doctor is first-party, versioned source in [`Fenrir-Dots/apps/fenrir-doctor/`](https://github.com/sunxsaturn/Fenrir-Dots/tree/main/apps/fenrir-doctor), including diagnostics, release tracking, recovery, wallpaper inventory and public-library audit, opt-in automatic metadata discovery, a sanitized rights-review queue and launcher for the Catalog’s session-protected Rights & Acquisition Studio, including human decisions, separately confirmed per-asset authorizations, a read-only provider-specific batch preflight and a SHA-256/size/device/inode-verified quarantine intake preview, explicit append-only exact/perceptual duplicate adjudication with session-protected writes, local assistant, CLI, user unit, desktop launcher, icon, docs and tests. Fenrir-Arch validates this complete source bundle before deploying it.
- **Fenrir-Wallpaper-Catalog 0.38.0**: pinned rights-aware discovery, acquisition, human review and visual collection workbench. The Rights & Acquisition Studio adds a read-only quarantine intake desk with transient, exact-inode-verified previews and existing duplicate-review history; same-image and deferred decisions remain blockers, and human acceptance/rejection/deferral are separate explicit, confirmation-gated decisions. Acceptance repeats current rights, authorization, duplicate and quality checks and never moves files or starts sync. The Wallpaper Studio supports batch curation of up to 100 accepted wallpapers, side-by-side duplicate comparison, license/evidence inspection, non-destructive 16:9–32:9 display-fit previews, and automatic collection-to-rotation sync.

## Requested applications

Firefox Nightly; Spotify; Discord; Whatsie; QPWgraph; Guitarix; REAPER + ReaPack; Steam; RPCS3; Heroic Games Launcher; Prism Launcher; Fenrir Doctor + Ollama Vulkan; EasyEffects; Calf LV2 plugins. AUR is not required by the current profile.

Spotify/RPCS3 Flatpak builds and Whatsie are third-party packages; verify their trust and permissions. Ollama does not download a model automatically. Fenrir also disables automatic screen blanking and idle locking by default; the screen lock remains available manually with Super+L.

## Wallpapers

Fenrir-Dots rotates wallpapers every 15 minutes and derives the system accent palette from the current wallpaper. There is no wallpaper-count goal. Rotation uses all qualifying local landscape images at least 2560×1440 (3840×2160 preferred), with quality and palette rules documented in `Fenrir-Arch/docs/WALLPAPER-PACK.md`.

The public wallpaper library is closed at the existing 1,871 published images across three active sync volumes; no further image-count balancing or new volume is planned. A fresh Fenrir installation downloads all three volumes automatically as part of the same `./install.sh` run. Do not run a separate downloader after a successful fresh install. The same `fenrir-wallpaper sync-library` command is available for later reconciliation or recovery on an existing installation. The integrated Catalog retains per-asset rights evidence, explicit authorization, duplicate review and human acceptance. Local sync copies all currently eligible accepted assets without a quota, after a complete read-only preflight; the Catalog repeats quarantine SHA-256, byte-size and palette verification. Sync does not acquire new images or publish private Catalog assets.

## License

No software license has been selected yet. Publication does not imply permission to redistribute or relicense third-party content.
