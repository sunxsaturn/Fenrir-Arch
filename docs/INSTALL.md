# Fenrir Desktop — clean Arch installation

Fenrir-Arch is a workstation installer, not an operating-system installer. Begin with minimal Arch Linux x86_64, systemd, networking, Git and a regular sudo-enabled user. Do not install a competing desktop distribution first.

## Private Catalog access

Before installation, configure GitHub access to the private `sunxsaturn/Fenrir-Wallpaper-Catalog` repository using an SSH key or Git credential helper. The installer tests access before its main package transaction. No token is embedded in Fenrir source or passed on the command line.

## One-command entry point

```bash
git clone --depth=1 https://github.com/sunxsaturn/Fenrir-Arch.git ~/Fenrir &&
cd ~/Fenrir &&
./install.sh
```

The default entry point opens the GTK4 guided installer. On a text-only Arch TTY it bootstraps Cage and opens the same GTK wizard. Use `./install.sh --cli` for terminal mode, or `./install.sh --dry-run` to print the plan without changing the workstation.

The wizard deploys the official Arch package profile, Flathub applications, pinned Dots and private Catalog, the selected integrations, then runs the public wallpaper synchronization as the final installation stage. No separate wallpaper downloader is part of a fresh install.

## Installation gate

The current public library registry must declare the new generation as fully published: exactly 5,000 globally unique records, all eleven balanced categories, six quotas of 455 and five quotas of 454, verified Public Domain/CC0 metadata, and zero legacy-image reuse. The installer validates all active manifests and checks available space before the workstation package transaction.

After deployment, the Dots sync command verifies every image's byte size, SHA-256, decoded format, landscape resolution and color policy; it refuses existing-file conflicts, resumes interrupted downloads and requires a final zero-missing inventory. If the new public gallery is not complete, the installer stops before its main package transaction.

## Storage and boot safety

- Fenrir never partitions or formats disks.
- Fenrir never installs a bootloader or changes firmware.
- Fenrir does not edit `/etc/fstab` or mount extra data disks automatically.
- `/mnt/storage` is protected.
- The existing SATA SSD and personal files are not installer targets.
- Fenrir does not reboot automatically.

Review the package transaction and the REAPER license prompt. After the installer completes, choose **Fenrir Desktop** in SDDM. The first successful gallery sync is required before first login.

## Hardware and AI

The reference GPU is Radeon RX 6750 XT 12 GB. The profile uses AMD Mesa/RADV for desktop and gaming and the official Ollama Vulkan backend for local inference. Model candidates are pulled and benchmarked after installation. The benchmark report records model, tokens/second and Ollama's CPU/GPU processor report. A successful download alone is not counted as proof of GPU acceleration.
