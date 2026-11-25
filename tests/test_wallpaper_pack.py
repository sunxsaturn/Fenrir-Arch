import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
loader = importlib.util.spec_from_file_location("fenrir_wallpaper_pack", ROOT / "scripts/download_wallpaper_pack.py")
pack = importlib.util.module_from_spec(loader)
loader.loader.exec_module(pack)


def valid_item():
    return {
        "id": "asset-001", "filename": "asset-001.jpg",
        "url": "https://images.example.org/asset-001.jpg",
        "sha256": "a" * 64, "width": 3840, "height": 2160,
        "creator": "Artist", "source_url": "https://source.example.org/asset-001",
        "license": "CC-BY-4.0", "license_url": "https://creativecommons.org/licenses/by/4.0/",
        "provider_terms_url": "https://source.example.org/terms",
        "rights_decision": "human_approved",
        "rights_decision_id": "rights-001", "acquisition_authorization_id": "acq-001",
        "acceptance_decision_id": "accept-001", "duplicate_review_id": "dupe-001",
        "provider_terms_evidence_id": "terms-001",
        "automated_download_permitted": True,
        "acquisition_authorized": True, "human_accepted": True,
        "duplicate_cleared": True, "personal_use_permitted": True,
        "tags": ["nordic-mythology", "dark-fantasy"],
    }


def valid_manifest():
    return {
        "schema": "org.fenrir.wallpaper-pack", "version": 1,
        "criteria": {"minimum_width": 2560, "minimum_height": 1440,
                     "preferred_width": 3840, "preferred_height": 2160,
                     "orientation": "landscape",
                     "preferred_palette": ["obsidian", "arctic-blue", "violet", "emerald", "deep-green", "dramatic-red"]},
        "allowed_hosts": ["images.example.org"], "items": [valid_item()],
    }


class WallpaperPackTests(unittest.TestCase):
    def test_manifest_is_rejected_below_5000_entries(self):
        with self.assertRaisesRegex(pack.PackError, "at least 5000"):
            pack.validate_pack(valid_manifest(), 5000)

    def test_manifest_accepts_rights_cleared_single_fixture_with_test_threshold(self):
        items, hosts, width, height = pack.validate_pack(valid_manifest(), 1)
        self.assertEqual(len(items), 1)
        self.assertEqual(hosts, {"images.example.org"})
        self.assertEqual((width, height), (2560, 1440))

    def test_manifest_rejects_unapproved_automated_download(self):
        manifest = valid_manifest()
        manifest["items"][0]["automated_download_permitted"] = False
        with self.assertRaisesRegex(pack.PackError, "automated_download_permitted"):
            pack.validate_pack(manifest, 1)

    def test_manifest_rejects_noncompliant_resolution(self):
        manifest = valid_manifest()
        manifest["criteria"]["minimum_width"] = 1920
        with self.assertRaisesRegex(pack.PackError, "2560x1440"):
            pack.validate_pack(manifest, 1)

    def test_manifest_rejects_unallowlisted_host(self):
        manifest = valid_manifest()
        manifest["items"][0]["url"] = "https://unlisted.example.org/image.jpg"
        with self.assertRaisesRegex(pack.PackError, "not allowlisted"):
            pack.validate_pack(manifest, 1)


if __name__ == "__main__":
    unittest.main()
