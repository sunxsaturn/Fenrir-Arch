# Fenrir Desktop — Arch Linux installer

**Version:** 2.0.0 · **Rebuild status:** implementation in progress

Fenrir-Arch deploys a complete Fenrir Desktop workstation onto an existing minimal Arch Linux x86_64 installation. It is not an operating-system installer and does not partition or format drives.

## Intended one-command installation

```bash
git clone --depth=1 https://github.com/sunxsaturn/Fenrir-Arch.git ~/Fenrir && cd ~/Fenrir && ./install.sh
```

The default path is a GTK4 guided installer. A terminal-only mode will be available with `./install.sh --cli`.

## Component boundaries

- **Fenrir-Arch:** system packages, services, hardware and session integration.
- **Fenrir-Dots:** Hyprland desktop, applications, terminal theme, wallpaper rotation, Control Center and Doctor.
- **Fenrir Wallpaper Catalog:** private discovery, rights, acquisition, validation and curation.
- **Fenrir Wallpapers:** three separate public gallery repositories. Software repositories never contain gallery image bytes.

## Target machine

Arch Linux x86_64, systemd, AMD Ryzen 5 7600X, 32 GiB RAM and Radeon RX 6750 XT 12 GiB. The system profile uses Mesa/RADV and installs gaming, audio production and desktop applications.

## Safety contract

- Never run this installer on Debian or another non-Arch distribution.
- Never partition, format, erase or resize any disk.
- Never install a bootloader, modify firmware or reboot automatically.
- Never mount, scan or alter `/mnt/storage`.
- Never alter the secondary SATA SSD automatically.
- Data-disk mounting is opt-in and requires a separate reviewed device selection.
- SDDM, NetworkManager and supported Ethernet Wake-on-LAN are configured without destructive disk operations.

## Release readiness

This repository is being rebuilt from a clean source tree. The installation gate remains closed until the Arch VM acceptance suite, component pins, complete wallpaper inventory and package validation pass. Do not run this in-progress tree as a finished workstation installer.
