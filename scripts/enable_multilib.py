#!/usr/bin/env python3
"""Enable the standard Arch multilib section without rewriting other repos."""
from __future__ import annotations
import re
import sys
from pathlib import Path

path = Path(sys.argv[1] if len(sys.argv) > 1 else "/etc/pacman.conf")
lines = path.read_text(encoding="utf-8").splitlines()
section = re.compile(r"^\s*#?\s*\[multilib\]\s*(?:#.*)?$")
header = None
for index, line in enumerate(lines):
    if section.match(line):
        if header is not None:
            raise SystemExit("Refusing ambiguous pacman.conf: duplicate multilib sections")
        header = index
if header is None:
    raise SystemExit("No [multilib] section found in pacman.conf; refusing to invent a repository block")

changed = False
if lines[header].lstrip().startswith("#"):
    lines[header] = re.sub(r"^\s*#\s*", "", lines[header], count=1)
    changed = True
end = next((i for i in range(header + 1, len(lines)) if re.match(r"^\s*\[", lines[i])), len(lines))
includes = [i for i in range(header + 1, end) if re.match(r"^\s*#?\s*Include\s*=\s*/etc/pacman\.d/mirrorlist\s*(?:#.*)?$", lines[i])]
if len(includes) != 1:
    raise SystemExit("Expected exactly one standard Include = /etc/pacman.d/mirrorlist in [multilib]; refusing to guess")
line = lines[includes[0]]
if line.lstrip().startswith("#"):
    lines[includes[0]] = re.sub(r"^\s*#\s*", "", line, count=1)
    changed = True
if not re.match(r"^\s*Include\s*=\s*/etc/pacman\.d/mirrorlist\s*(?:#.*)?$", lines[includes[0]]):
    raise SystemExit("Could not activate the standard multilib Include")
if changed:
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("enabled")
else:
    print("already-enabled")
