# Fenrir installation contract

## Supported base

- Minimal Arch Linux x86_64.
- systemd.
- Network connectivity.
- Git.
- A regular user with working sudo access.
- No competing desktop distribution is required.

The installer is a desktop deployment tool, not an operating-system or partitioning installer. It must refuse non-Arch systems before installing prerequisites or changing files.

## Prohibited operations

The installer must never execute partitioning, formatting, filesystem creation, drive erasure, bootloader installation, firmware updates or automatic reboot. It must not write to, mount or inspect the contents of `/mnt/storage`. It must not alter the secondary SATA SSD without a separately requested and reviewed storage action.

Default storage integration is disabled. A future opt-in storage wizard must show the exact device model, serial, UUID, filesystem and target mount point, exclude the OS disk and protected paths, and require explicit confirmation before editing fstab.

## System integration

- Install Hyprland, SDDM, Wayland portals, NetworkManager, PipeWire and the requested desktop stack.
- Enable SDDM, NetworkManager and Bluetooth where present.
- Configure Wake-on-LAN only for wired interfaces that advertise magic-packet support.
- Configure AMD Mesa/RADV and 32-bit Vulkan for gaming.
- Install Steam, Gamemode, MangoHud, Gamescope, RPCS3, Heroic, Spotify, Discord, Whatsie, REAPER, ReaPack, Guitarix, QPWgraph and EasyEffects.
- Install Ollama's official Vulkan runtime; choose and benchmark model weights after the desktop is deployed.
- Deploy the exact pinned Fenrir-Dots and private Catalog sources.
- Download the complete active public wallpaper registry as the final install gate.

## Failure behavior

Any failed package transaction, missing private repository access, mismatched source pin, storage preflight failure, incomplete manifest, integrity error or remaining public wallpaper must produce a nonzero exit and must not be reported as a successful installation. Verified partial downloads remain resumable.
