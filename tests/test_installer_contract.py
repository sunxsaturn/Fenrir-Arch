import re
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class InstallerContractTests(unittest.TestCase):
    def test_component_versions_and_immutable_pins_are_valid(self):
        lock = tomllib.loads((ROOT / "components.lock").read_text())
        self.assertEqual(lock["arch_version"], "1.2.3")
        self.assertEqual(lock["dots_version"], "0.19.0")
        self.assertEqual(lock["catalog_version"], "0.39.2")
        for key in ("dots_commit", "catalog_commit"):
            self.assertRegex(lock[key], re.compile(r"^[0-9a-f]{40}$"))

    def test_installer_fails_closed_outside_arch(self):
        source = (ROOT / "install.sh").read_text()
        self.assertIn("require_arch", source)
        helper = (ROOT / "scripts/lib.sh").read_text()
        self.assertIn("/etc/arch-release", helper)
        self.assertIn("Arch Linux only", helper)
        self.assertIn("check-wallpaper-ready.py", source)

    def test_installer_does_not_partition_format_or_reboot(self):
        source = "\n".join(
            path.read_text(errors="replace")
            for path in [ROOT / "install.sh", *(ROOT / "scripts").glob("*.sh")]
        )
        lowered = source.lower()
        forbidden_command = re.compile(
            r"(?m)^\\s*(?:sudo\\s+)?(?:mkfs\\.\\w+|wipefs|sgdisk|parted|fdisk|reboot|shutdown)\\b"
        )
        self.assertIsNone(forbidden_command.search(lowered))

    def test_protected_storage_is_rejected(self):
        source = (ROOT / "scripts/lib.sh").read_text()
        self.assertIn("/mnt/storage", source)
        self.assertIn("Protected path rejected", source)

    def test_public_gallery_gate_requires_five_thousand(self):
        gate = (ROOT / "scripts/check-wallpaper-ready.py").read_text()
        self.assertIn('"published_unique_images") != 5000', gate)
        self.assertIn("total_records != 5000", gate)
        self.assertIn("legacy_images_reused", gate)

    def test_installer_uses_blueprint_glass_default(self):
        source = (ROOT / "install.sh").read_text()
        wizard = (ROOT / "installer" / "gtk_installer.py").read_text()
        self.assertIn("fenrir-glass enable --opacity 0.60", source)
        self.assertIn("60% opacity with compositor blur", wizard)
        self.assertNotIn("0.80", source)
        self.assertNotIn("80% opacity", wizard)

    def test_no_aur_dependency_is_declared(self):
        combined = "\n".join(p.read_text() for p in ROOT.rglob("*") if p.is_file() and p.suffix in {".sh", ".toml"})
        self.assertNotIn("paru ", combined)
        self.assertNotIn("yay ", combined)


if __name__ == "__main__":
    unittest.main()
