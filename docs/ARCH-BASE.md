# Minimal Arch base for Fenrir Desktop

Fenrir installs the graphical environment and applications after Arch's base system. Do not install KDE, GNOME, another compositor or a third-party Hyprland profile during Archinstall.

## Archinstall choices

1. Boot the official Arch ISO and connect to a reliable network.
2. Run `archinstall` and select the minimal/base profile.
3. Use UEFI boot mode and configure a working bootloader and initramfs.
4. Select only the 1 TB NVMe for Arch partitioning. Keep the 960 GB SATA data SSD disconnected while creating partitions and installing the OS; reconnect it after the first successful boot. Fenrir's storage step can then add eligible data volumes to `/etc/fstab` without formatting or changing their contents.
5. Create the intended regular user and add it to `wheel`; install `sudo`. Do not run Fenrir as root.
6. Configure network connectivity, a bootloader and a working initramfs.
7. Use `America/Sao_Paulo` for the timezone. The Fenrir Hyprland XKB configuration sets `us` + `intl` (US International dead keys); the installer also applies it with `localectl`.
8. Reboot into the installed base system and log in as the regular user. Verify `sudo`, `pacman`, networking and systemd.

Archinstall prompts and profile labels may change. Read the current screen rather than relying on fixed menu numbers.

## Preflight

```bash
id
sudo -v
pacman -Q base systemd
uname -r
ip route
lsblk -o NAME,SIZE,MODEL,FSTYPE,UUID,LABEL,MOUNTPOINTS,RM,RO
```

Inspect `lsblk` output and confirm the intended OS disk and any data disks before running the installer.

## Install Fenrir

Download and execute the self-extracting bundle with:

```bash
bash fenrir-desktop-0.3.0.run
```

Or extract the source archive and run `./install.sh --dry-run` then `./install.sh`. The full install performs `pacman -Syu`, enables the standard multilib section for Steam/32-bit gaming libraries with a timestamped backup, installs the complete desktop and app profile, and adds eligible fixed data filesystems to `/etc/fstab` by UUID. It never partitions, formats or copies/deletes files on data disks.

No reboot is triggered. Log out and select Hyprland in SDDM after the install completes.
