#!/usr/bin/env python3
"""Download an explicitly rights-cleared Fenrir wallpaper pack from a manifest."""
from __future__ import annotations
import argparse
import hashlib
import ipaddress
import json
import os
import re
import socket
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ALLOWED_LICENSES = {"CC0-1.0", "CC-BY-3.0", "CC-BY-4.0", "CC-BY-SA-3.0", "CC-BY-SA-4.0"}
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
MAX_MANIFEST_BYTES = 25 * 1024 * 1024
MAX_IMAGE_BYTES = 100 * 1024 * 1024
USER_AGENT = "Fenrir-Desktop-Wallpaper-Pack/1.0 (+rights-reviewed local wallpaper installer)"
THEME_TAGS = {
    "nordic", "nordic-mythology", "viking", "viking-fantasy", "mythology",
    "dark-fantasy", "medieval-fantasy", "medieval", "warrior", "warriors",
    "battle", "battles", "armor", "fortress", "fortresses", "dragon",
    "dragons", "mythological-creatures", "creatures", "cinematic-game",
    "game-environment", "concept-art", "mountain", "mountains", "forest",
    "forests", "ocean", "oceans", "dramatic-landscape", "landscape",
}


class PackError(RuntimeError):
    pass


def https_url(value: object, label: str) -> urllib.parse.ParseResult:
    if not isinstance(value, str):
        raise PackError(f"{label} must be a URL string")
    parsed = urllib.parse.urlparse(value)
    if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password:
        raise PackError(f"{label} must be an HTTPS URL without embedded credentials")
    try:
        address = ipaddress.ip_address(parsed.hostname)
    except ValueError:
        address = None
    if address is not None and (address.is_private or address.is_loopback or address.is_link_local or address.is_reserved):
        raise PackError(f"{label} may not target a private or reserved IP address")
    return parsed


def safe_filename(value: object) -> str:
    if not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,150}", value):
        raise PackError("Every item needs a simple filename (letters, digits, dot, underscore or dash)")
    path = Path(value)
    if path.name != value or path.suffix.lower() not in IMAGE_EXTENSIONS or value in {".", ".."}:
        raise PackError(f"Unsafe or unsupported wallpaper filename: {value!r}")
    return value


def fetch_manifest(source: str) -> dict:
    parsed = urllib.parse.urlparse(source)
    if parsed.scheme in {"http", "https"}:
        url = https_url(source, "manifest URL")
        require_public_dns(url.hostname)
        opener = urllib.request.build_opener(SameHostManifestRedirectHandler(url.hostname))
        with opener.open(urllib.request.Request(source, headers={"User-Agent": USER_AGENT}), timeout=60) as response:
            data = response.read(MAX_MANIFEST_BYTES + 1)
        if len(data) > MAX_MANIFEST_BYTES:
            raise PackError("Manifest exceeds 25 MiB")
    else:
        path = Path(source).expanduser().resolve(strict=True)
        data = path.read_bytes()
        if len(data) > MAX_MANIFEST_BYTES:
            raise PackError("Manifest exceeds 25 MiB")
    try:
        obj = json.loads(data)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise PackError(f"Invalid JSON manifest: {exc}") from exc
    if not isinstance(obj, dict):
        raise PackError("Manifest root must be an object")
    return obj


def require_public_dns(host: str) -> None:
    """Reject names that resolve to loopback, private, link-local or reserved IPs."""
    try:
        addresses = {entry[4][0] for entry in socket.getaddrinfo(host, 443, type=socket.SOCK_STREAM)}
    except OSError as exc:
        raise PackError(f"Could not resolve download host {host}: {exc}") from exc
    if not addresses:
        raise PackError(f"Download host has no address records: {host}")
    for value in addresses:
        address = ipaddress.ip_address(value)
        if not address.is_global:
            raise PackError(f"Download host resolves to a non-public address: {host} -> {address}")


class AllowlistedRedirectHandler(urllib.request.HTTPRedirectHandler):
    def __init__(self, allowed_hosts: set[str]):
        super().__init__()
        self.allowed_hosts = allowed_hosts

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        parsed = https_url(newurl, "redirect URL")
        if parsed.hostname.lower() not in self.allowed_hosts:
            raise PackError(f"Redirect host is not allowlisted: {parsed.hostname}")
        require_public_dns(parsed.hostname)
        return super().redirect_request(req, fp, code, msg, headers, newurl)


class SameHostManifestRedirectHandler(urllib.request.HTTPRedirectHandler):
    def __init__(self, original_host: str):
        super().__init__()
        self.original_host = original_host.lower()

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        parsed = https_url(newurl, "manifest redirect URL")
        if parsed.hostname.lower() != self.original_host:
            raise PackError("Manifest redirects must remain on the original manifest host")
        require_public_dns(parsed.hostname)
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def validate_pack(manifest: dict, minimum_count: int) -> tuple[list[dict], set[str], int, int]:
    if manifest.get("schema") != "org.fenrir.wallpaper-pack" or manifest.get("version") != 1:
        raise PackError("Unsupported pack schema; expected org.fenrir.wallpaper-pack version 1")
    criteria = manifest.get("criteria")
    if not isinstance(criteria, dict):
        raise PackError("Manifest must declare image criteria")
    min_width = int(criteria.get("minimum_width", 0))
    min_height = int(criteria.get("minimum_height", 0))
    if min_width < 2560 or min_height < 1440 or criteria.get("orientation") != "landscape":
        raise PackError("Manifest criteria must enforce landscape images of at least 2560x1440")
    if int(criteria.get("preferred_width", 0)) < 3840 or int(criteria.get("preferred_height", 0)) < 2160:
        raise PackError("Manifest must record 3840x2160 or higher as the preferred resolution")
    preferred_palette = {"obsidian", "arctic-blue", "violet", "emerald", "deep-green", "dramatic-red"}
    if set(criteria.get("preferred_palette", [])) != preferred_palette:
        raise PackError("Manifest must preserve Fenrir's complete preferred palette: obsidian, arctic blue, violet, emerald, deep green and dramatic red")
    minimum_delay = float(manifest.get("minimum_transfer_interval_seconds", 1.0))
    if not 0.25 <= minimum_delay <= 60:
        raise PackError("minimum_transfer_interval_seconds must be between 0.25 and 60")
    hosts_raw = manifest.get("allowed_hosts")
    if not isinstance(hosts_raw, list) or not hosts_raw:
        raise PackError("Manifest must declare exact allowed_hosts for image transfers")
    allowed_hosts = {str(host).strip().lower() for host in hosts_raw if isinstance(host, str) and host.strip()}
    if len(allowed_hosts) != len(hosts_raw) or any("/" in host or ":" in host for host in allowed_hosts):
        raise PackError("allowed_hosts must contain exact hostnames only")
    items = manifest.get("items")
    if not isinstance(items, list) or len(items) < minimum_count:
        raise PackError(f"Wallpaper pack has {len(items) if isinstance(items, list) else 0} entries; at least {minimum_count} are required")
    ids: set[str] = set()
    hashes: set[str] = set()
    names: set[str] = set()
    for number, item in enumerate(items, 1):
        if not isinstance(item, dict):
            raise PackError(f"Item {number} is not an object")
        ident = item.get("id")
        if not isinstance(ident, str) or not re.fullmatch(r"[A-Za-z0-9._-]{1,100}", ident) or ident in ids:
            raise PackError(f"Item {number} has a missing or duplicate ID")
        ids.add(ident)
        filename = safe_filename(item.get("filename"))
        if filename in names:
            raise PackError(f"Duplicate filename in manifest: {filename}")
        names.add(filename)
        digest = item.get("sha256")
        if not isinstance(digest, str) or not re.fullmatch(r"[a-fA-F0-9]{64}", digest) or digest.lower() in hashes:
            raise PackError(f"Item {ident} has a missing, invalid or duplicate SHA-256")
        hashes.add(digest.lower())
        image_url = https_url(item.get("url"), f"image URL for {ident}")
        if image_url.hostname.lower() not in allowed_hosts:
            raise PackError(f"Image host is not allowlisted for {ident}: {image_url.hostname}")
        for field in ("source_url", "license_url", "provider_terms_url"):
            https_url(item.get(field), f"{field} for {ident}")
        for field in ("rights_decision_id", "acquisition_authorization_id", "acceptance_decision_id", "duplicate_review_id", "provider_terms_evidence_id"):
            value = item.get(field)
            if not isinstance(value, str) or not value.strip():
                raise PackError(f"Item {ident} is missing auditable evidence reference: {field}")
        if item.get("license") not in ALLOWED_LICENSES:
            raise PackError(f"Item {ident} has a license outside Fenrir's eligible-license policy")
        if not isinstance(item.get("creator"), str) or not item["creator"].strip():
            raise PackError(f"Item {ident} is missing creator/uploader attribution")
        if item.get("rights_decision") != "human_approved":
            raise PackError(f"Item {ident} lacks an explicit human-approved rights decision")
        for flag in ("automated_download_permitted", "acquisition_authorized", "human_accepted", "duplicate_cleared", "personal_use_permitted"):
            if item.get(flag) is not True:
                raise PackError(f"Item {ident} is missing required explicit flag: {flag}")
        width, height = int(item.get("width", 0)), int(item.get("height", 0))
        if width < min_width or height < min_height or width <= height:
            raise PackError(f"Item {ident} does not meet the advertised landscape resolution")
        tags = item.get("tags")
        if not isinstance(tags, list) or not tags:
            raise PackError(f"Item {ident} is missing curated theme tags")
        normalized_tags = {str(tag).strip().lower().replace("_", "-").replace(" ", "-") for tag in tags}
        if not normalized_tags.intersection(THEME_TAGS):
            raise PackError(f"Item {ident} is outside Fenrir's Nordic/fantasy/cinematic/landscape theme scope")
        item["filename"] = filename
    return items, allowed_hosts, min_width, min_height


def make_opener(hosts: set[str]):
    return urllib.request.build_opener(AllowlistedRedirectHandler(hosts))


def download_one(opener, item: dict, destination: Path, min_width: int, min_height: int) -> dict:
    filename = item["filename"]
    final_path = destination / filename
    expected = item["sha256"].lower()
    if final_path.exists():
        if not final_path.is_file() or final_path.stat().st_size > MAX_IMAGE_BYTES:
            raise PackError(f"Existing wallpaper is not a regular file within the 100 MiB limit: {final_path}")
        digest = hashlib.sha256(final_path.read_bytes()).hexdigest()
        if digest != expected:
            raise PackError(f"Refusing to overwrite existing wallpaper with different bytes: {final_path}")
        existing = True
    else:
        existing = False
        request_host = urllib.parse.urlparse(item["url"]).hostname
        require_public_dns(request_host)
        request = urllib.request.Request(item["url"], headers={"User-Agent": USER_AGENT})
        fd, temp_name = tempfile.mkstemp(prefix=".fenrir-wallpaper-", suffix=Path(filename).suffix, dir=destination)
        os.close(fd)
        temp_path = Path(temp_name)
        digest_obj = hashlib.sha256()
        total = 0
        try:
            with opener.open(request, timeout=90) as response, temp_path.open("wb") as output:
                while True:
                    chunk = response.read(1024 * 1024)
                    if not chunk:
                        break
                    total += len(chunk)
                    if total > MAX_IMAGE_BYTES:
                        raise PackError(f"Image exceeds 100 MiB: {item['id']}")
                    digest_obj.update(chunk)
                    output.write(chunk)
                output.flush()
                os.fsync(output.fileno())
            if digest_obj.hexdigest() != expected:
                raise PackError(f"SHA-256 mismatch for {item['id']}")
            temp_path.replace(final_path)
        except Exception:
            temp_path.unlink(missing_ok=True)
            raise
    try:
        from PIL import Image, ImageOps
        with Image.open(final_path) as image:
            image.verify()
        with Image.open(final_path) as image:
            orientation = image.getexif().get(274, 1)
            width, height = image.size
            if orientation in {5, 6, 7, 8}:
                width, height = height, width
    except Exception as exc:
        if not existing:
            final_path.unlink(missing_ok=True)
        raise PackError(f"Image validation failed for {item['id']}: {exc}") from exc
    if width < min_width or height < min_height or width <= height:
        if not existing:
            final_path.unlink(missing_ok=True)
        raise PackError(f"Decoded dimensions for {item['id']} are {width}x{height}; required {min_width}x{min_height} landscape")
    if int(item["width"]) != width or int(item["height"]) != height:
        raise PackError(f"Manifest dimensions disagree with downloaded bytes for {item['id']}")
    return {
        "id": item["id"], "file": filename, "sha256": expected,
        "width": width, "height": height, "creator": item["creator"],
        "source_url": item["source_url"], "license": item["license"],
        "license_url": item["license_url"], "provider_terms_url": item["provider_terms_url"],
        "rights_decision_id": item["rights_decision_id"],
        "acquisition_authorization_id": item["acquisition_authorization_id"],
        "acceptance_decision_id": item["acceptance_decision_id"],
        "duplicate_review_id": item["duplicate_review_id"],
        "provider_terms_evidence_id": item["provider_terms_evidence_id"],
        "tags": item["tags"],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True, help="local JSON file or HTTPS URL to a signed-off pack manifest")
    parser.add_argument("--destination", type=Path, required=True)
    parser.add_argument("--minimum-count", type=int, default=5000)
    parser.add_argument("--delay", type=float, default=1.0, help="Minimum delay in seconds between image transfers (default: 1.0)")
    args = parser.parse_args()
    try:
        if args.minimum_count < 5000:
            raise PackError("The production installer cannot lower the 5000-wallpaper minimum")
        if not 0.25 <= args.delay <= 60:
            raise PackError("Transfer delay must be between 0.25 and 60 seconds")
        manifest = fetch_manifest(args.manifest)
        items, hosts, min_width, min_height = validate_pack(manifest, args.minimum_count)
        effective_delay = max(args.delay, float(manifest.get("minimum_transfer_interval_seconds", 1.0)))
        print(f"Fenrir wallpaper downloader: sequential transfers, minimum {effective_delay:.2f}s between image requests", flush=True)
        destination = args.destination.expanduser()
        destination.mkdir(parents=True, exist_ok=True)
        if destination.is_symlink() or not destination.is_dir():
            raise PackError("Wallpaper destination must be a real directory, not a symlink")
        opener = make_opener(hosts)
        records = []
        for index, item in enumerate(items, 1):
            try:
                record = download_one(opener, item, destination, min_width, min_height)
            except Exception as exc:
                raise PackError(f"Stopped at item {index}/{len(items)} ({item.get('id','?')}): {exc}") from exc
            records.append(record)
            if index < len(items):
                time.sleep(effective_delay)
            if index % 100 == 0 or index == len(items):
                print(f"Fenrir wallpapers: verified {index}/{len(items)}", flush=True)
        attribution = destination / "fenrir-attribution.json"
        temp = attribution.with_suffix(".json.tmp")
        temp.write_text(json.dumps({"schema": "org.fenrir.wallpaper-attribution", "version": 1, "items": records}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        os.chmod(temp, 0o600)
        temp.replace(attribution)
        print(f"Downloaded and verified {len(records)} wallpapers into {destination}")
        print(f"Attribution metadata: {attribution}")
        return 0
    except (PackError, OSError, urllib.error.URLError, ValueError) as exc:
        print(f"Fenrir wallpaper pack: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
