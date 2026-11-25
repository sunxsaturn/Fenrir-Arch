# Fenrir Arch

The Arch Linux installer and system integration layer for **Fenrir Desktop**. This repository is intentionally separate from the desktop dotfiles, following the installer + dotfiles architecture used by established Hyprland setups.

## One-command installation

Start from a minimal Arch Linux x86_64 installation with systemd, networking and a regular sudo-enabled user. Do not preinstall KDE, GNOME or another Hyprland dotfiles distribution.

```bash
git clone --depth=1 https://github.com/sunxsaturn/Fenrir-Arch.git ~/Fenrir && cd ~/Fenrir && ./install.sh
```

The installer automatically clones or fast-forward-updates [Fenrir-Dots](https://github.com/sunxsaturn/Fenrir-Dots) into `~/.local/share/fenrir/dots`, then deploys the desktop configuration and applications. It performs a full `pacman -Syu`, enables the standard multilib repository for Steam, installs the complete gaming/audio/software profile, configures US International dead keys, persistent Ethernet Wake-on-LAN where supported, and eligible fixed data-disk mounts by UUID.

Review the confirmation prompt and pacman transaction. REAPER has its own EULA. No automatic reboot, partitioning, formatting, bootloader installation, firmware change or file operation on data volumes is performed.

### Options

```text
--dry-run       Print the plan without changing the system
--no-ai         Skip Ollama Vulkan and Sun AI
--no-storage    Do not append eligible fixed data volumes to /etc/fstab
--no-wol        Do not enable persistent Ethernet Wake-on-LAN
--yes           Skip Fenrir's confirmation prompt (pacman remains interactive)
--help          Show help
```

To select a different dotfiles checkout location or branch, set `FENRIR_DOTS_DIR` or `FENRIR_DOTS_REF`. To select a fork, set `FENRIR_DOTS_REPO`.

## Included software

- Hyprland, Waybar, Fuzzel, Kitty, Mako, XDG portals and Thunar
- Mozilla Firefox Nightly from Mozilla's official archive, with SHA-512 verification
- Steam, GameMode, MangoHud, Gamescope, 32-bit Mesa and RADV Vulkan libraries
- Heroic, RPCS3, Prism Launcher
- Discord, Spotify and Whatsie
- PipeWire, EasyEffects, QPWgraph, Guitarix, Calf LV2, REAPER and ReaPack
- Sun AI local dashboard and Ollama Vulkan (no model is downloaded automatically)

Spotify/RPCS3 Flathub builds and Whatsie are third-party packages; review their permissions and trust model before using them.

## Wallpapers

The companion dotfiles implement a 15-minute random rotation and wallpaper-derived color accents. The service enforces 5,000 valid landscape images (minimum 2560×1440; 3840×2160 preferred) before rotation starts. This repository does not pretend to contain that corpus. The Fenrir Wallpaper Catalog requires traceable rights evidence, individual acquisition authorization, duplicate review and explicit human acceptance. The installer only downloads a supplied manifest after strict schema, rights-attestation, host and image-integrity checks. No scraping or unauthorized bulk acquisition is performed. See [docs/WALLPAPER-PACK.md](docs/WALLPAPER-PACK.md).

## Tests

```bash
python3 -m unittest discover -s tests -v
bash -n install.sh scripts/*.sh scripts/fenrir-enable-wol
python3 -m compileall -q scripts tests
```

## Repository boundaries

- **Fenrir-Arch**: system installer, packages, system services, hardware/system integration and wallpaper-pack acquisition contract.
- **Fenrir-Dots**: Hyprland and application dotfiles, original visual theme, icons, wallpaper/theme runtime, user services and Sun AI.
- **Fenrir-Wallpaper-Catalog**: separate rights-aware wallpaper discovery, acquisition and catalog project.

The project software license has not yet been selected; no license grant is implied by publication.
