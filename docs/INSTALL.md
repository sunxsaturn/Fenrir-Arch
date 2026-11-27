# Fenrir Desktop — clean Arch installation

Fenrir-Arch is a workstation installer, not an operating-system installer. For the full desktop deployment, begin with minimal Arch Linux x86_64, systemd, networking, Git and a regular sudo-enabled user. Do not install a competing desktop distribution first.

## Private Catalog preparation

The fresh public gallery is populated through the private rights-aware Catalog. To seed and run its metadata-only discovery campaigns before the gallery is complete, use:

```bash
git clone --depth=1 https://github.com/sunxsaturn/Fenrir-Arch.git ~/Fenrir
cd ~/Fenrir
./install.sh --catalog-only
```

Catalog-only preparation runs on Arch Linux, Debian 13+ or Ubuntu with Python 3.13+, Git, sudo and a systemd user session. On Arch it installs only `python-pip` when needed; on Debian/Ubuntu it installs `python3-venv` only when the current interpreter cannot create a virtual environment. It then installs the pinned private Catalog under the user's home directory, verifies the 1,871-image legacy exclusion set, seeds the 528 bounded metadata-only campaigns and enables the user timer. It does not install the desktop package profile, change boot settings, configure system services or access personal data volumes. The normal desktop installer remains Arch-only. Configure GitHub access to the private Catalog with an SSH key or Git credential helper; no token is embedded in Fenrir or passed on the command line.

The discovery scheduler fetches metadata only. Exact asset license and provider terms are reviewed separately; an expiring authorization is required before image bytes can enter private quarantine. Technical validation, duplicate adjudication, human acceptance and separate public redistribution approval are independent gates. Only Public Domain and CC0 files may enter the new public generation.

## One-command desktop installation

After the new public gallery is fully published and its registry reports exactly 5,000 unique assets, run:

```bash
./install.sh
```

The default entry point opens the GTK4 guided installer. On a text-only Arch TTY it bootstraps Cage and opens the same GTK wizard. Use `./install.sh --cli` for terminal mode, or `./install.sh --dry-run` to print the plan without changing the workstation.

The normal installer validates the complete 5,000-image registry and every active volume manifest before installing GTK prerequisites, system packages, applications, desktop configuration or services. If the gallery is incomplete or unavailable, it exits without making those changes. Once the gate passes, it deploys the pinned Dots desktop, private Catalog integration, official Arch applications, Flathub applications, Wake-on-LAN service and selected integrations, then synchronizes all public images into `~/Pictures/Wallpapers`. There is no separate wallpaper downloader.

## Package and application profile

Fimbulwinter Glass defaults to 60% opacity, with compositor blur where supported and opaque exceptions for games, fullscreen media, lock and authentication surfaces. The official package profile includes Hyprland 0.57+, SDDM, Quickshell/QML shell, Waybar fallback, Fuzzel, Kitty, Mako, Thunar, Starship, qt6ct, Steam/Proton, GameMode, MangoHud, Gamescope, PipeWire/JACK, EasyEffects, QPWGraph, QjackCtl, REAPER/ReaPack, Guitarix and Calf. Flathub supplies Spotify, Heroic, RPCS3, Discord, ZapZap and Prism Launcher. The audio profile uses PipeWire's JACK compatibility layer; QjackCtl is a controller/patchbay frontend, not a second JACK server to install beside Pipewire.

### Additional applications, recovery and device tools

The official package profile also installs VSCodium from Flathub; VLC; LibreOffice Fresh; `scrcpy` and `android-tools` (ADB); `v4l-utils` for camera diagnostics; SMART/NVMe utilities (`smartmontools`, `nvme-cli`); and Btrfs/Snapper/Restic tooling (`btrfs-progs`, `snapper`, `restic`). `nftables` is installed as the firewall backend.

Installing the tools does not silently choose a backup destination, create a Snapper root configuration, schedule snapshots, or run a Restic backup. Those operations need a verified target filesystem and a user-selected backup destination; the installer deliberately leaves them unconfigured rather than writing to a personal data disk. The standard Firefox package is installed; Firefox Nightly is not included in this release.

`v4l2loopback-dkms` is not installed automatically. It is an external DKMS/kernel-module choice with kernel-header compatibility requirements and is not part of the official repository-only package set. The included `scrcpy`/ADB and `v4l-utils` tools provide Android connectivity and camera diagnostics, not a virtual webcam device.

## Storage and boot safety

- Fenrir never partitions or formats disks.
- Fenrir never installs a bootloader or changes firmware.
- Fenrir does not edit `/etc/fstab` or mount extra data disks automatically.
- `/mnt/storage` is protected.
- Personal files and additional data volumes are not installer targets.
- Fenrir does not reboot automatically.

Review the package transaction and REAPER's license. After installation completes, choose **Fenrir Desktop** in SDDM.

## Hardware and AI

The reference GPU is Radeon RX 6750 XT 12 GB. The profile uses AMD Mesa/RADV for desktop and gaming and Arch's Ollama Vulkan package for local inference. Model candidates are pulled and benchmarked after installation. The report records model, tokens/second and Ollama's CPU/GPU processor report. A successful download alone is not proof of GPU acceleration.
