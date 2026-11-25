# Fenrir Arch + Fenrir Dots

Fenrir is an original Arch Linux + Hyprland desktop environment, shipped in two repositories using the installer/dotfiles model.

## One-command installation

Start from a minimal Arch Linux x86_64 installation with systemd, network access, Git and a regular sudo-enabled account. Do not preinstall KDE, GNOME or a competing Hyprland dotfiles distribution.

```bash
git clone --depth=1 https://github.com/sunxsaturn/Fenrir-Arch.git ~/Fenrir && cd ~/Fenrir && ./install.sh
```

The default command opens the GTK4 guided installer; on a clean text-only TTY it bootstraps Cage and presents the same wizard full-screen. In an existing Wayland/X11 session it opens normally; use `./install.sh --cli` for a terminal-only install. The first login guide and Fenrir Control Center provide tutorials, keybindings and display/appearance/wallpaper/power customization. The installer fetches the pinned Fenrir-Dots source commit `a12e3278e336fd709bd8a4fdd779a3ee4bcb9187` automatically, validates its version and complete required file set, then installs packages and configures the complete desktop. Sun AI and Ollama Vulkan are mandatory parts of the full profile; only model-weight downloads remain manual. It performs one synchronized `pacman -Syu`, enables official multilib for Steam, installs the gaming and audio suites, obtains Mozilla Firefox Nightly with SHA-512 verification, deploys the dotfiles, sets US International with dead keys, enables Ethernet Wake-on-LAN where supported, and adds eligible fixed data filesystems to `/etc/fstab` by UUID.

Review the initial prompt and every package transaction. REAPER has its own EULA. ReaPack is installed from the official Arch Extra repository as an optional package; it is not fetched from AUR or installed as an unverified third-party binary. It does not partition/format drives, edit data-volume contents, install a bootloader, modify firmware, or reboot.

Options: `--dry-run`, `--cli`, `--no-reapack`, `--no-storage`, `--no-wol`, `--yes`, `--help`. Sun AI cannot be disabled because it is a required Fenrir component. See `docs/POST-INSTALL.md`.

## Repositories

- **Fenrir-Arch**: installer, packages, system services, disk/keyboard/WoL integration and validated wallpaper-pack installer.
- **Fenrir-Dots**: Hyprland Lua config, Waybar, Fuzzel, Kitty, Mako, GTK, icons, Fimbulwinter Glass, wallpaper rotation/theme services, GTK4 Fenrir Control Center and Sun AI.
  - Sun AI is first-party, versioned source in [`Fenrir-Dots/apps/sun-ai/`](https://github.com/sunxsaturn/Fenrir-Dots/tree/main/apps/sun-ai), including its server, web assets, CLI, user unit, desktop launcher, icon, docs and tests. Fenrir-Arch validates this complete source bundle before deploying it.
- **Fenrir-Wallpaper-Catalog**: separate catalog and rights-aware acquisition project.

## Requested applications

Firefox Nightly; Spotify; Discord; Whatsie; QPWgraph; Guitarix; REAPER + ReaPack; Steam; RPCS3; Heroic Games Launcher; Prism Launcher; Sun AI + Ollama Vulkan; EasyEffects; Calf LV2 plugins. AUR is not required by the current profile.

Spotify/RPCS3 Flatpak builds and Whatsie are third-party packages; verify their trust and permissions. Ollama does not download a model automatically. Fenrir also disables automatic screen blanking and idle locking by default; the screen lock remains available manually with Super+L.

## Wallpapers

Fenrir-Dots rotates wallpapers every 15 minutes and derives the system accent palette from the current wallpaper. It requires at least 5,000 valid landscape files at minimum 2560×1440 (3840×2160 preferred), with the selected source themes and colors documented in `Fenrir-Arch/docs/WALLPAPER-PACK.md`.

No 5,000-image corpus is falsely claimed to be bundled. The separate wallpaper catalog requires per-asset rights evidence, explicit acquisition authorization, duplicate review and human acceptance. Fenrir-Arch only downloads a supplied validated pack manifest; it does not scrape or mass-download unlicensed artwork.

## License

No software license has been selected yet. Publication does not imply permission to redistribute or relicense third-party content.
