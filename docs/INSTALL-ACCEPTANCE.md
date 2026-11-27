# Clean-install acceptance

This is the release acceptance procedure for the documented one-command Arch installation. It complements CI: CI exercises the install-time wallpaper gate with controlled responses, while this procedure validates the real installer and real public repository content in a disposable Arch Linux VM.

## Preconditions

- Create a disposable x86_64 Arch Linux VM with a clean minimal install, systemd, networking, Git and a regular sudo-enabled user.
- Use a VM disk large enough for the workstation packages, the wallpaper destination and the resumable download cache. Do not attach host disks or shared folders.
- Configure GitHub authentication for the private Fenrir Wallpaper Catalog repository before installation (SSH agent/key or a Git credential helper). Do not put a token in the command line or repository.
- Take a VM snapshot before installation so the test can be repeated from a genuinely clean state.

## Primary one-command test

Run the documented command unchanged:

```bash
git clone --depth=1 https://github.com/sunxsaturn/Fenrir-Arch.git ~/Fenrir &&
cd ~/Fenrir &&
./install.sh
```

Complete the guided installer and review package transactions. The installation must finish without a separate wallpaper downloader or manual wallpaper sync command.

After installation, verify the version manifest:

```bash
python3 - <<'PY'
import json
from pathlib import Path

versions = json.loads(
    (Path.home() / ".local/share/fenrir/installed-versions.json").read_text()
)
expected = {
    "Fenrir-Arch": "1.0.0",
    "Fenrir-Dots": "0.16.0",
    "Fenrir-Wallpaper-Catalog": "0.38.0",
}
assert versions == expected, (versions, expected)
print(versions)
PY
```

Then ask the Dots-owned sync implementation for a read-only final inventory:

```bash
fenrir-wallpaper sync-library --dry-run --json
```

Acceptance requires all of the following from that report:

- `dry_run` is `true`.
- All three registered public volumes are active.
- `planned_downloads` is `0`.
- `already_present` equals `unique_images`.
- `remaining_after_limit` is `0`.
- The installer log recorded the complete manifest scan, storage preflight, image verification and final zero-missing check.

Do not hard-code a wallpaper target into the test. The public registry and active manifests define the current inventory; the acceptance condition is that every unique manifest-listed image is present and verified.

## Failure and recovery coverage

CI's installer-gate tests exercise the actual `scripts/sync-wallpaper-library.sh` with a temporary fake `fenrir-wallpaper` executable. They prove that:

1. An insufficient destination/cache storage report stops before the transfer command.
2. Declining the interactive wallpaper prompt does not start a transfer.
3. A failed/interrupted transfer exits nonzero and gives the same-installer resume instruction.
4. An incomplete final inventory cannot be reported as success.
5. A malformed storage preflight report fails closed.
6. The full installer gate never passes a transfer limit to the Dots command.

Fenrir-Dots' wallpaper-library tests separately exercise actual manifest parsing, global SHA-256 deduplication across volumes, storage-space refusal before downloads, byte verification, existing-file conflict protection, attribution, interrupted partial downloads and HTTP Range resume. Run them from the pinned Dots checkout when investigating a failure.

The real-VM run is for the positive clean-install path and end-to-end compatibility. Do not deliberately exhaust the VM filesystem or corrupt downloaded images on the only clean-install snapshot; destructive failure injection belongs in disposable snapshots or the deterministic test suite.

## Pass criteria

The release candidate passes only when the standard CI suite is green and the disposable VM completes the one-command installation with the exact component versions above and a final zero-missing public-library report. Record the VM image/date, Arch ISO version, installer commit, Dots/Catalog pins, final inventory report and CI run URL with the release evidence.

A successful source-level or mocked test is not a substitute for this real VM result. Until the VM procedure is completed, mark clean-install acceptance as pending rather than claiming the installer has been end-to-end validated.
