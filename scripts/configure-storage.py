#!/usr/bin/env python3
"""Persist mounts for eligible fixed data partitions without touching their contents."""
from __future__ import annotations
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

SUPPORTED = {"ext4", "btrfs", "xfs", "f2fs", "ntfs", "ntfs3", "exfat", "vfat"}
SYSTEM_MOUNTS = {"/", "/boot", "/efi", "/boot/efi", "/usr", "/var"}
PROTECTED_MOUNT_PREFIXES = ("/mnt/storage",)


def is_protected_mountpoint(mountpoint):
    """Return true for the protected data mount and anything below it."""
    if not mountpoint:
        return False
    normalized = os.path.normpath(str(mountpoint))
    return any(
        normalized == prefix or normalized.startswith(prefix.rstrip("/") + "/")
        for prefix in PROTECTED_MOUNT_PREFIXES
    )



def run(*args: str) -> str:
    return subprocess.check_output(args, text=True, stderr=subprocess.DEVNULL).strip()


def safe_label(value: str) -> str:
    value = re.sub(r"[^A-Za-z0-9._-]+", "-", value.strip()).strip("-.")
    return value[:48] or "volume"


def walk_nodes(tree):
    for node in tree:
        yield node
        yield from walk_nodes(node.get("children") or [])


def children(tree, parent_disk=None, inherited_rm=False, inherited_ro=False):
    for node in tree:
        name = node.get("name", "")
        device = name if name.startswith("/dev/") else f"/dev/{name}"
        disk = device if node.get("type") == "disk" else parent_disk
        removable = inherited_rm or str(node.get("rm", "0")) == "1"
        read_only = inherited_ro or str(node.get("ro", "0")) == "1"
        yield node, device, disk, removable, read_only
        yield from children(node.get("children") or [], disk, removable, read_only)


def main() -> int:
    if os.geteuid() != 0:
        print("Run this helper through sudo.", file=sys.stderr)
        return 2
    apply = "--apply" in sys.argv[1:]
    if not apply and "--dry-run" not in sys.argv[1:]:
        print("Usage: configure-storage.py --dry-run|--apply", file=sys.stderr)
        return 2
    try:
        root_uuid = run("findmnt", "-nro", "UUID", "/")
        root_source = run("findmnt", "-nro", "SOURCE", "/")
        root_disks = set()
        root_tree = json.loads(run("lsblk", "--json", "-s", "-o", "NAME,TYPE", root_source)).get("blockdevices", [])
        for node in walk_nodes(root_tree):
            if node.get("type") == "disk":
                root_disks.add(node.get("name", ""))
        tree = json.loads(run("lsblk", "--json", "-o", "NAME,TYPE,FSTYPE,UUID,LABEL,MOUNTPOINTS,RM,RO"))
    except (subprocess.CalledProcessError, json.JSONDecodeError) as exc:
        print(f"Could not inspect block devices safely: {exc}", file=sys.stderr)
        return 1

    fstab = Path("/etc/fstab")
    original = fstab.read_text(encoding="utf-8")
    existing_uuids = set(re.findall(r"(?m)^\s*UUID=([^\s#]+)", original))
    existing_targets = set()
    for line in original.splitlines():
        line = line.split("#", 1)[0].strip()
        fields = line.split()
        if len(fields) >= 2:
            existing_targets.add(fields[1].replace("\\040", " "))

    plans = []
    for node, device, disk, removable, read_only in children(tree.get("blockdevices", [])):
        if node.get("type") not in {"disk", "part", "lvm", "crypt"} or removable or read_only:
            continue
        fstype = (node.get("fstype") or "").lower()
        uuid = node.get("uuid") or ""
        if fstype not in SUPPORTED or not uuid or uuid == root_uuid:
            continue
        if disk and Path(disk).name in root_disks:
            continue
        if uuid in existing_uuids:
            continue
        mounts = node.get("mountpoints") or []
        if any(is_protected_mountpoint(item) for item in mounts):
            continue
        mounts = [p for p in mounts if p]
        if any(mount in existing_targets for mount in mounts):
            continue
        current = next((p for p in mounts if p not in SYSTEM_MOUNTS), None)
        label = safe_label(node.get("label") or f"volume-{uuid[:8]}")
        target = current or f"/mnt/fenrir/{label}"
        if target in SYSTEM_MOUNTS or target in existing_targets:
            target = f"/mnt/fenrir/{label}-{uuid[:8]}"
        if fstype in {"ntfs", "ntfs3", "exfat", "vfat"}:
            mount_type = "ntfs3" if fstype == "ntfs" else fstype
            uid = os.environ.get("SUDO_UID", "1000")
            gid = os.environ.get("SUDO_GID", "1000")
            options = f"defaults,uid={uid},gid={gid},umask=0022,nofail,x-systemd.device-timeout=5"
            passno = "0"
        else:
            mount_type = fstype
            options = "defaults,noatime,nofail,x-systemd.device-timeout=5"
            passno = "2" if fstype in {"ext4", "f2fs"} else "0"
        escaped_target = target.replace("\\", "\\134").replace(" ", "\\040").replace("\t", "\\011")
        entry = f"UUID={uuid}\t{escaped_target}\t{mount_type}\t{options}\t0\t{passno}"
        plans.append((device, fstype, uuid, target, entry))
        existing_uuids.add(uuid)
        existing_targets.add(target)

    if not plans:
        print("[Fenrir] No new eligible fixed data filesystems found; existing fstab entries were left unchanged.")
        return 0
    for device, fstype, uuid, target, _ in plans:
        print(f"[Fenrir] {device} ({fstype}, UUID={uuid}) -> {target}")
    if not apply:
        print("Dry run: no mount point or fstab changes were made.")
        return 0

    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup = fstab.with_name(f"fstab.fenrir-backup-{stamp}")
    shutil.copy2(fstab, backup)
    try:
        for _, _, _, target, _ in plans:
            Path(target).mkdir(parents=True, exist_ok=True)
        with fstab.open("a", encoding="utf-8") as stream:
            stream.write("\n# Fenrir-managed fixed data volumes\n")
            for *_, entry in plans:
                stream.write(entry + "\n")
        subprocess.run(["findmnt", "--verify", "--verbose"], check=True)
        subprocess.run(["systemctl", "daemon-reload"], check=True)
    except Exception as exc:
        shutil.copy2(backup, fstab)
        subprocess.run(["systemctl", "daemon-reload"], check=False)
        print(f"Storage configuration failed; /etc/fstab restored from {backup}: {exc}", file=sys.stderr)
        return 1
    print(f"[Fenrir] Added {len(plans)} UUID-based boot mounts. Original fstab: {backup}")
    print("[Fenrir] Partitions were not formatted and no files on the data volumes were changed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
