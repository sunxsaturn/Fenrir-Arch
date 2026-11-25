# Minimal Arch base for Fenrir Desktop

Fenrir installs the graphical environment and applications after Arch's base system. Do not install KDE, GNOME, another compositor or a third-party Hyprland profile during Archinstall.

## Archinstall choices

1. Boot the official Arch ISO and connect to a reliable network.
2. Run `archinstall` and select the minimal/base profile.
3. Use UEFI boot mode and configure a working bootloader and initramfs.
4. Select only the 1 TB NVMe for Arch partitioning. Keep the 960 GB SATA data SSD disconnected while creating partitions and installing the OS; reconnect it after the first successful boot. Fenrir's storage step can then add eligible data volumes to `/etc/fstab` without formatting or changing their contents.
5. Create the intended regular user and add it to `wheel`; ensure `sudo` and `git` are installed. Do not run Fenrir as root.
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

From the installed minimal Arch system, run the same one-command installer documented in the project README:

```bash
git clone --depth=1 https://github.com/sunxsaturn/Fenrir-Arch.git ~/Fenrir
cd ~/Fenrir
./install.sh --dry-run
./install.sh
```

The installer retrieves the pinned Fenrir-Dots commit, validates the complete Hyprland and application source tree, and installs the full Fenrir profile, including Sun AI and Ollama Vulkan. It performs `pacman -Syu`, enables the standard multilib section for Steam/32-bit gaming libraries with a timestamped backup, installs the desktop, gaming and audio applications, and adds eligible fixed data filesystems to `/etc/fstab` by UUID. It never partitions, formats or copies/deletes files on data disks.

This is a complete Fenrir environment installer for an existing minimal Arch base; it intentionally does not partition disks, install Arch itself, or replace the bootloader. No reboot is triggered. Log out and select Hyprland in SDDM after the install completes.
