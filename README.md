# Fenrir Arch + Fenrir Dots

Fenrir is an original Arch Linux + Hyprland desktop environment, shipped in two repositories using the installer/dotfiles model.

## One-command installation

Start from a minimal Arch Linux x86_64 installation with systemd, network access, Git and a regular sudo-enabled account. Do not preinstall KDE, GNOME or a competing Hyprland dotfiles distribution.

```bash
git clone --depth=1 https://github.com/sunxsaturn/Fenrir-Arch.git ~/Fenrir && cd ~/Fenrir && ./install.sh
```

The default command opens the GTK4 guided installer; on a clean text-only TTY it bootstraps Cage and presents the same wizard full-screen. In an existing Wayland/X11 session it opens normally; use `./install.sh --cli` for a terminal-only install. The first login guide and Fenrir Control Center provide tutorials, keybindings and display/appearance/wallpaper/power customization. The installer fetches the pinned Fenrir-Dots source commit `af440bc07eec817a986786c41eeb23e8ac8fba0d` automatically, pins Fenrir-Dots 0.12.5 and validates its version and complete required file set, then installs packages and configures the complete desktop. Fenrir Doctor, Ollama Vulkan and the pinned Fenrir Wallpaper Catalog are mandatory parts of the full profile; only model-weight downloads remain manual. The Catalog runs in an isolated Python environment with a private local database and quarantine. Catalog 0.31.0 adds six curated metadata-only discovery profiles and verified portable collection packages, transactional restore into already accepted local assets, a bounded quality report with display-fit analysis, and optional collection-scoped wallpaper synchronization. The Catalog source repository is private, so a fresh installation must already have GitHub access configured for this account (SSH key or Git credential helper); Fenrir never embeds or stores an access token. It performs one synchronized `pacman -Syu`, enables official multilib for Steam, installs the gaming and audio suites, obtains Mozilla Firefox Nightly with SHA-512 verification, deploys the dotfiles, sets US International with dead keys, enables Ethernet Wake-on-LAN where supported, and adds eligible fixed data filesystems to `/etc/fstab` by UUID.

Review the initial prompt and every package transaction. REAPER has its own EULA. ReaPack is installed from the official Arch Extra repository as an optional package; it is not fetched from AUR or installed as an unverified third-party binary. It does not partition/format drives, edit data-volume contents, install a bootloader, modify firmware, or reboot.

Options: `--dry-run`, `--cli`, `--no-reapack`, `--no-storage`, `--no-wol`, `--yes`, `--help`. Fenrir Doctor and the Wallpaper Catalog cannot be disabled because they are required Fenrir components. See `docs/POST-INSTALL.md`.

## Repositories

- **Fenrir-Arch**: installer, packages, system services, disk/keyboard/WoL integration and pinned Catalog deployment.
- **Fenrir-Dots 0.12.5**: Hyprland Lua config, Waybar, Fuzzel, Kitty, Mako, GTK, icons, Fimbulwinter Glass, wallpaper rotation/theme services, GTK4 Fenrir Control Center and Fenrir Doctor, now integrated with the Catalog’s guarded human Rights Review Studio.
  - Fenrir Doctor is first-party, versioned source in [`Fenrir-Dots/apps/fenrir-doctor/`](https://github.com/sunxsaturn/Fenrir-Dots/tree/main/apps/fenrir-doctor), including diagnostics, release tracking, recovery, wallpaper intelligence, opt-in automatic metadata discovery, a sanitized rights-review queue and launcher for the Catalog’s session-protected Rights & Acquisition Studio, including human decisions, separately confirmed per-asset authorizations, a read-only provider-specific batch preflight and a SHA-256/size/device/inode-verified quarantine intake preview, explicit append-only exact/perceptual duplicate adjudication with session-protected writes, local assistant, CLI, user unit, desktop launcher, icon, docs and tests. Fenrir-Arch validates this complete source bundle before deploying it.
- **Fenrir-Wallpaper-Catalog 0.31.0**: pinned rights-aware discovery, acquisition, human review and visual collection workbench. The Rights & Acquisition Studio adds a read-only quarantine intake desk with transient, exact-inode-verified previews and existing duplicate-review history; same-image and deferred decisions remain blockers, and human acceptance/rejection/deferral are separate explicit, confirmation-gated decisions. Acceptance repeats current rights, authorization, duplicate and quality checks and never moves files or starts sync. The Wallpaper Studio supports batch curation of up to 100 accepted wallpapers, side-by-side duplicate comparison, license/evidence inspection, non-destructive 16:9–32:9 display-fit previews, and automatic collection-to-rotation sync.

## Requested applications

Firefox Nightly; Spotify; Discord; Whatsie; QPWgraph; Guitarix; REAPER + ReaPack; Steam; RPCS3; Heroic Games Launcher; Prism Launcher; Fenrir Doctor + Ollama Vulkan; EasyEffects; Calf LV2 plugins. AUR is not required by the current profile.

Spotify/RPCS3 Flatpak builds and Whatsie are third-party packages; verify their trust and permissions. Ollama does not download a model automatically. Fenrir also disables automatic screen blanking and idle locking by default; the screen lock remains available manually with Super+L.

## Wallpapers

Fenrir-Dots rotates wallpapers every 15 minutes and derives the system accent palette from the current wallpaper. The collection target is at least 5,000 valid landscape files at minimum 2560×1440 (3840×2160 preferred); rotation works with the qualifying images already present, even below the target, with the selected source themes and colors documented in `Fenrir-Arch/docs/WALLPAPER-PACK.md`.

No 5,000-image corpus is falsely claimed to be bundled. The integrated Fenrir Wallpaper Catalog requires per-asset rights evidence, explicit acquisition authorization, duplicate review, human rights approval and human acceptance. Fenrir Doctor can locally synchronize approved, SHA-256-verified quarantine files into the desktop wallpaper folder at 5,000, 10,000 or 20,000 total-image targets. It does not scrape, publish or mass-download unlicensed artwork.

## License

No software license has been selected yet. Publication does not imply permission to redistribute or relicense third-party content.
