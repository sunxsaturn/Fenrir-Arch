# Fenrir Desktop

Fenrir is an original **Arch Linux + Hyprland** desktop environment. The installer, desktop layer and wallpaper catalog are maintained as separate components with explicit compatibility pins.

**Documentation:** [Project map](docs/PROJECT-MAP.md) · [Versioning and releases](docs/VERSIONING.md) · [Minimal Arch base](docs/ARCH-BASE.md) · [Post-install guide](docs/POST-INSTALL.md) · [Wallpaper workflow](docs/WALLPAPER-PACK.md)

## Install

Start from a minimal Arch Linux x86_64 installation with systemd, working network access, Git and a regular sudo-enabled user. Do not preinstall KDE, GNOME or another Hyprland configuration.

```bash
git clone --depth=1 https://github.com/sunxsaturn/Fenrir-Arch.git ~/Fenrir
cd ~/Fenrir
./install.sh
```

The default installer opens the GTK4 guided setup. On a text-only TTY it bootstraps Cage and presents the same wizard; use `./install.sh --cli` for a terminal-only flow.

Review the plan and every package transaction. Fenrir runs one synchronized `pacman -Syu`, enables official multilib for Steam, installs the selected desktop, gaming and audio stack, deploys the pinned desktop source, obtains Firefox Nightly with SHA-512 verification, configures US International with dead keys, and can enable Ethernet Wake-on-LAN and mount eligible fixed data filesystems by UUID.

### Installer options

| Option | Purpose |
|---|---|
| `--dry-run` | Print the plan without changing the system |
| `--cli` | Use the terminal installer |
| `--no-reapack` | Skip optional ReaPack integration |
| `--no-storage` | Do not add eligible fixed data filesystems to `/etc/fstab` |
| `--no-wol` | Do not enable Wake-on-LAN |
| `--yes` | Skip Fenrir's confirmation prompt; package prompts remain |
| `--help` | Show all options |

The installer does not partition or format disks, change data-volume contents, install a bootloader, modify firmware or reboot. Keep REAPER's EULA and all package prompts under review. ReaPack comes from the official Arch Extra repository; an AUR helper is not required.

## Components and compatibility pins

| Component | Responsibility | Pinned installer version |
|---|---|---:|
| [Fenrir-Arch](https://github.com/sunxsaturn/Fenrir-Arch) | System installer, packages, system services, deployment and hardware integration | Read `VERSION` |
| [Fenrir-Dots](https://github.com/sunxsaturn/Fenrir-Dots) | Hyprland configuration, Settings, Welcome, Doctor, wallpaper rotation and user services | **0.14.1** |
| [Fenrir Wallpaper Catalog](https://github.com/sunxsaturn/Fenrir-Wallpaper-Catalog) | Private metadata, rights, acquisition, quarantine, review and curated collections | **0.35.0** |

The installer pins Fenrir-Dots commit `9b9e85c084e397141389c28778988bf009280fcf` and Catalog commit `d8742dde2c7540cc2d18eef8ed1cc58a2a12de04`. It verifies the component version and required source files before deployment; it never follows a floating `main` branch. The Catalog repository is private, so GitHub access must already be configured for the installing user (SSH key or Git credential helper). Fenrir never embeds or stores an access token.

Version numbers are monotonic **within each component**, not synchronized across repositories. See [Versioning and releases](docs/VERSIONING.md) before changing a version or compatibility pin.

## Desktop experience

Fenrir-Dots provides:

- Hyprland 0.57+ with Lua configuration, monitor detection and generated workspace/keybinding modules.
- Fenrir Settings, a GTK4 control center with validated settings, atomic writes and backups.
- Fenrir Welcome & Tutorial for first login, shortcuts and common tasks.
- Fimbulwinter Glass: an obsidian base, restrained blur, frosted surfaces and wallpaper-derived accents.
- Waybar, Fuzzel, Kitty, Mako, GTK styling and the Fenrir-Obsidian icon theme.
- Wallpaper rotation every 15 minutes, with dynamic palette synchronization.
- Fenrir Doctor for diagnostics, release tracking, configuration recovery and wallpaper intelligence. Its local Ollama assistant starts on demand; model weights remain opt-in.
- Public multi-volume wallpaper sync and a separate, rights-checked sync path for curated Catalog collections.
- Keep-awake behavior without automatic screen blanking or idle locking; manual lock remains available with `Super+L`.

## Wallpaper lifecycle

The recommended collection target is **20,000 qualifying local images**. It is a goal, not a claim that images are bundled or a requirement for rotation. Rotation can use the qualifying files already present; images must be landscape and at least 2560×1440 (3840×2160 preferred).

Fenrir Doctor can supervise metadata-only discovery across four sources — Openverse, Wikimedia Commons, SFW Wallhaven and Cleveland Museum of Art Open Access — using eight visual profiles and a queue of up to **32 source/profile combinations**. Each provider-balanced scheduler turn is capped at **four API requests**. Discovery downloads no image bytes and makes no rights or acceptance decisions.

The private Catalog keeps these steps separate:

1. Discover metadata and retain source provenance.
2. Review the individual asset's license, rights and provider terms.
3. Record a separate human acquisition authorization.
4. Acquire into private quarantine and verify the bytes.
5. Review exact/perceptual duplicate candidates.
6. Record a human rights decision and a separate acceptance decision.
7. Curate collections and run a bounded, read-only desktop sync preflight.
8. Copy only eligible, accepted assets into the desktop rotation directory.

Local acceptance does **not** authorize public redistribution. The public wallpaper mirror has its own publication approval and provider-terms requirements. See [Wallpaper workflow](docs/WALLPAPER-PACK.md).

## Applications

The current profile includes Firefox Nightly, Spotify, Discord, Whatsie, QPWgraph, Guitarix, REAPER + optional ReaPack, Steam, RPCS3, Heroic Games Launcher, Prism Launcher, Fenrir Doctor, Ollama Vulkan, EasyEffects and Calf LV2 plugins.

Third-party application packages retain their own trust, license and permission considerations. Ollama does not download a model automatically.

## After installation

Start with the [post-install guide](docs/POST-INSTALL.md) for first login, keybindings, display and audio checks, gaming, data volumes, Wake-on-LAN and recovery.

## License

No software license has been selected yet. Publishing Fenrir source does not grant redistribution rights to third-party applications, artwork or assets.
