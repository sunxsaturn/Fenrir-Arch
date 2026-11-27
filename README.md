# Fenrir-Arch

Fenrir-Arch is the system installer and hardware integration layer for Fenrir Desktop. It targets minimal Arch Linux x86_64 with systemd. It is not an operating-system installer and must never format or partition a disk.

## Rebuild contract

The intended fresh-install entry point is:

```bash
git clone --depth=1 https://github.com/sunxsaturn/Fenrir-Arch.git ~/Fenrir && cd ~/Fenrir && ./install.sh
```

This command is a release target, not an installation-ready claim until the disposable-VM acceptance gate passes.

The guided installer must deploy the pinned Fenrir-Dots desktop, the private Wallpaper Catalog integration, Fenrir Doctor, applications, gaming/audio packages, hardware services and the complete public wallpaper library. No separate wallpaper downloader is permitted.

## Safety invariants

- Arch Linux only; fail closed on Debian and other distributions.
- Never partition, format, erase, repartition or install a bootloader.
- Never modify user files on data volumes.
- Never automatically configure additional data-disk mounts without explicit consent.
- Treat `/mnt/storage` as protected and never inspect or write inside it.
- Require a verified backup and explicit disk identity selection before any separately documented OS migration.
- Never embed private GitHub credentials in source, logs or command arguments.
- Keep the private Catalog separate from public wallpaper repositories.

## Hardware target

The reference workstation uses a Ryzen 5 7600X, 32 GiB RAM and Radeon RX 6750 XT 12 GiB. AMD Mesa/RADV acceleration is the primary graphics path. Hardware-specific choices must be detected and verified rather than assumed.

## Release gates

1. Reproducible package and service deployment on clean minimal Arch.
2. Exact immutable pins for Dots and Catalog.
3. Full public-library manifest preflight and SHA-256-verified sync in the same install run.
4. No-overwrite and resumable-download regression tests.
5. Hyprland/SDDM, audio, gaming, GPU and Wake-on-LAN validation.
6. Successful disposable Arch VM acceptance before publishing a release.

Historical release tags remain immutable. The next implementation release must advance beyond v1.0.0.
