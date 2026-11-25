# Post-install notes

## First login

- The GTK4 Fenrir Setup window launches from `./install.sh` (using Cage on a text-only TTY, or your existing graphical session when available). Sun AI and Ollama Vulkan are always installed as required Fenrir components. The wizard lets you opt out only of UUID-based fixed data-disk mounts and Ethernet Wake-on-LAN; the core desktop, gaming and audio suite is always included. You can use `./install.sh --cli` for a terminal-only installation.
- Fenrir First Login Guide opens once after your first Hyprland login. It explains the desktop and keybindings. Reopen **Fenrir Control Center** from the app launcher whenever you need the guide or configuration options.
- Fenrir Control Center provides GUI options for display mode, scaling, wallpaper folder/interval, surface opacity, blur, wallpaper-derived colors and keep-awake behavior. It creates backups of the settings it changes.
- Log into the Hyprland session from SDDM.
- Check `systemctl status NetworkManager bluetooth sddm` and `systemctl status fenrir-wol`.
- Confirm the input layout: `localectl status`; Hyprland uses `kb_layout = "us"` and `kb_variant = "intl"`.
- If a black screen occurs, use `Ctrl+Alt+F3`, inspect `journalctl --user -b`, and restore selected files from `~/.local/state/fenrir/backups/<timestamp>/`.
- The default display rule requests **2560×1440 at 155 Hz** (`2560x1440@155`) on outputs without a more specific rule. Confirm your panel advertises this exact mode with `hyprctl monitors all`; if the connector uses a slightly different advertised refresh value, update `~/.config/hypr/monitors.lua` to match it. Hyprland monitor mode syntax and advertised modes are documented in the [Hyprland monitor guide](https://wiki.hypr.land/configuring/core/monitors/).
- Check audio with `wpctl status` and connect/route endpoints in QPWgraph.
- The default monitor target is 2560×1440 at 155 Hz. Hyprland applies the mode only when the output supports it; verify with `hyprctl monitors all`.

## Wallpaper and dynamic theme

Fenrir rotates a valid landscape wallpaper every 15 minutes. The minimum is 2560×1440; 3840×2160 or higher is preferred. Each change extracts a dominant accent and updates Waybar, Kitty, Fuzzel, Mako, GTK palette files and the active Hyprland border. Surfaces retain a fixed obsidian base and Fimbulwinter Glass 0.60 opacity.

```bash
fenrir-wallpaper status
fenrir-wallpaper next
systemctl --user status fenrir-wallpaper.service
```

The wallpaper folder defaults to `~/Pictures/Wallpapers`; it can be changed in `~/.config/fenrir/settings.toml`. See `docs/WALLPAPER-PACK.md` for the 5,000-image pack contract and why an approved pack must be supplied before the installer can download it.

## Keyboard shortcuts

`Super` is the Windows/Super key.

| Shortcut | Action |
|---|---|
| `Super + Enter` | Kitty terminal |
| `Super + Space` | Fuzzel application launcher |
| `Super + E` | Thunar file manager |
| `Super + B` | Firefox Nightly |
| `Super + A` | Sun AI |
| `Super + W` | Next wallpaper |
| `Super + L` | Lock screen manually |
| `Super + Q` | Close active window |
| `Super + F` | Toggle fullscreen |
| `Super + Arrow` | Move focus |
| `Super + 1…0` | Switch workspace |
| `Super + Shift + 1…0` | Move window to workspace |
| `Super + Shift + R` | Reload Hyprland configuration |
| `Super + Shift + Q` | Exit Hyprland |
| `Super + Shift + S` | Select screenshot region and copy |
| `Print` | Screenshot all displays to clipboard |
| `Super + V` | Clipboard history |
| `XF86Audio…` | Volume and media controls |

## Screen and power behavior

Fenrir does not start `hypridle`, does not auto-lock, and does not issue a DPMS-off command. The default `fenrir-stay-awake.service` holds a logind idle/sleep inhibitor for the graphical session. `Super + L` is a manual lock only. The Control Center allows you to release the keep-awake inhibitor; do so only when you want normal idle/sleep behavior again.

## Gaming

Steam uses Arch's official multilib packages. The installer installs GameMode, MangoHud, Gamescope, Mesa/RADV 64-bit and 32-bit libraries, Prism Launcher/Java, Heroic and RPCS3. Use `mangohud %command%` in a Steam game's launch options to display the overlay, or prefix a game command with `gamemoderun`. Verify Vulkan after the first boot:

```bash
vulkaninfo --summary
```

Login to each game service yourself and configure game directories/proton versions. ROMs, game files, console firmware and proprietary game assets are not downloaded by Fenrir.

## Audio production

PipeWire/JACK, EasyEffects, QPWgraph, Guitarix, Calf LV2, REAPER, ReaPack is available as an optional package from the official Arch Extra repository and can be selected in the Advanced customization section of the setup wizard. No AUR helper or custom plugin binary is required. The current account is added to the `realtime` group if the package provides it; group membership takes effect at the next login. Confirm that PipeWire/JACK routing works before a recording session. Avoid applying extra latency/kernel tuning without measuring it on the actual interface.

## Sun AI and GPU

```bash
ollama --version
sun-ai status
sun-ai start
ollama pull qwen3:8b
ollama run qwen3:8b
sun-ai stop
```

No model is downloaded automatically. `sun-ai start` uses the Hyprland Polkit agent to start the Ollama system service on demand; stop it before gaming or recording when you want the GPU/CPU free. The local UI binds only to `127.0.0.1:8765`.

## Data volumes

The installer excludes the current root/boot device and removable media. It adds supported fixed data partitions with UUID-based entries and `nofail` to `/etc/fstab`, preserving existing non-system mount points where possible. It backs up `/etc/fstab` before appending entries and validates the result. Review `lsblk -f` and `findmnt --verify` after installation. Existing volume contents are not changed. If an entry causes a boot problem, restore the exact `fstab.fenrir-backup-*` file from `/etc/` using a TTY.

## Wake-on-LAN

Fenrir enables magic-packet mode on physical Ethernet NICs advertising `g` support and reapplies it on boot. Check:

```bash
sudo ethtool <ethernet-interface> | grep -E 'Supports Wake-on|Wake-on'
systemctl status fenrir-wol.service
```

WoL also requires firmware support: enable PCIe/network wake or the equivalent BIOS option and disable ErP if it powers down the NIC. An Ethernet cable is required for conventional wired WoL; this does not configure WoWLAN.

## Rollback

User files are backed up beneath `~/.local/state/fenrir/backups/<timestamp>/`. The multilib and fstab files have timestamped backups alongside their originals. There is no automated destructive uninstaller. Restore only the files you have reviewed, and do not remove unrelated settings.
