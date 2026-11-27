# Fenrir-Arch

**Version:** 1.2.2

Fenrir-Arch is the system installer and hardware integration layer for Fenrir Desktop. It targets minimal Arch Linux x86_64 with systemd. It is not an operating-system installer and must never format or partition a disk.

## Rebuild contract

For private Catalog preparation before the public image gallery is complete, run this isolated mode on Arch Linux, Debian 13+ or Ubuntu with Python 3.13+, Git, sudo and a systemd user session:

```bash
git clone --depth=1 https://github.com/sunxsaturn/Fenrir-Arch.git ~/Fenrir
cd ~/Fenrir
./install.sh --catalog-only
```

This mode installs the private Catalog, verifies the legacy exclusion set, seeds bounded metadata-only campaigns and enables the discovery timer. It does not install the desktop package profile.

The full one-command workstation installation is:

```bash
./install.sh
```

The full installer runs a complete registry and volume-manifest preflight before making system changes. It refuses to proceed until all 5,000 globally unique, rights-approved images are published. It then deploys Fenrir-Dots 0.17.4 with 60% Fimbulwinter Glass and Catalog 0.39.2, applications, gaming/audio packages, hardware services and the complete public wallpaper library. No separate wallpaper downloader is required.

## Safety invariants

- Arch Linux only; fail closed on Debian and other distributions.
- Never partition, format, erase, repartition or install a bootloader.
- Never modify user files on data volumes.
- Never automatically configure additional data-disk mounts without explicit consent.
- Treat `/mnt/storage` as protected and never inspect or write inside it.
- Never embed private GitHub credentials in source, logs or command arguments.
- Keep the private Catalog separate from public wallpaper repositories.
- Do not automatically reboot.

## Hardware target

The reference workstation uses a Ryzen 5 7600X, 32 GiB RAM and Radeon RX 6750 XT 12 GiB. AMD Mesa/RADV acceleration is the primary graphics path. Hardware-specific choices must be detected and verified rather than assumed.

## Release gates

1. Reproducible package and service deployment on clean minimal Arch.
2. Exact immutable pins for Dots and Catalog.
3. Full public-library manifest preflight and SHA-256-verified sync in the same install run.
4. No-overwrite and resumable-download regression tests.
5. Hyprland/SDDM, audio, gaming, GPU and Wake-on-LAN validation.
6. Successful disposable Arch VM acceptance before declaring the installer production-ready.

Historical release tags remain immutable.
