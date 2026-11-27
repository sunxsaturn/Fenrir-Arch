#!/usr/bin/env python3
"""Enable Arch's stock multilib section without duplicating or guessing settings."""
from __future__ import annotations

import re
import shutil
import sys
from datetime import datetime
from pathlib import Path

CONFIG = Path("/etc/pacman.conf")


def is_enabled(text: str) -> bool:
    lines = text.splitlines()
    matches = 0
    for index, line in enumerate(lines):
        if re.fullmatch(r"\s*\[multilib\]\s*", line):
            matches += 1
            if index + 1 < len(lines) and re.fullmatch(
                r"\s*Include\s*=\s*/etc/pacman\.d/mirrorlist\s*", lines[index + 1]
            ):
                continue
            return False
    return matches == 1


def main() -> int:
    if Path("/etc/arch-release").is_file() is False:
        print("This helper is only for Arch Linux.", file=sys.stderr)
        return 2
    text = CONFIG.read_text(encoding="utf-8")
    if is_enabled(text):
        print("[Fenrir] multilib is already enabled.")
        return 0

    pattern = re.compile(
        r"(?ms)^\s*#\s*\[multilib\]\s*\n\s*#\s*Include\s*=\s*/etc/pacman\.d/mirrorlist\s*$"
    )
    updated, count = pattern.subn(
        "[multilib]\nInclude = /etc/pacman.d/mirrorlist", text, count=1
    )
    if count != 1:
        print(
            "The standard multilib block was not found exactly as expected. "
            "No pacman.conf changes were made.",
            file=sys.stderr,
        )
        return 1
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup = CONFIG.with_name(f"pacman.conf.fenrir-backup-{stamp}")
    shutil.copy2(CONFIG, backup)
    temporary = CONFIG.with_name(".pacman.conf.fenrir.tmp")
    temporary.write_text(updated, encoding="utf-8")
    shutil.copystat(CONFIG, temporary)
    temporary.replace(CONFIG)
    if not is_enabled(CONFIG.read_text(encoding="utf-8")):
        shutil.copy2(backup, CONFIG)
        print("Validation failed; original pacman.conf restored.", file=sys.stderr)
        return 1
    print(f"[Fenrir] multilib enabled; original saved at {backup}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
