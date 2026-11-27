# Fenrir wallpaper delivery

This repository does not maintain a separate wallpaper pack manifest or downloader.

**The only supported public wallpaper download path is the registry-driven synchronization command shipped by Fenrir Dots.** Fenrir-Arch invokes it automatically as the final wallpaper stage of the single-command system installation:

```bash
git clone --depth=1 https://github.com/sunxsaturn/Fenrir-Arch.git ~/Fenrir && cd ~/Fenrir && ./install.sh
```

That command reads the canonical [public volume registry](https://github.com/sunxsaturn/Fenrir-Wallpapers/blob/main/manifest/volumes.json), synchronizes every active published volume, verifies image bytes and checks that no manifest-listed image remains missing. There is no separate wallpaper-pack manifest, second downloader or image-count target.

For maintenance on an existing Fenrir installation, use the same Dots-owned command:

```bash
fenrir-wallpaper sync-library --dry-run
fenrir-wallpaper sync-library
```

Private Catalog acquisitions remain a different rights-controlled workflow: per-asset evidence, authorization, quarantine, duplicate review and human acceptance are required before local Catalog sync.
