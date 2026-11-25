import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class InstallerIntegrationTests(unittest.TestCase):
    def test_reapack_is_installed_as_a_verified_extension_not_a_pacman_package(self):
        packages = (ROOT / "scripts" / "packages.sh").read_text(encoding="utf-8")
        installer = (ROOT / "install.sh").read_text(encoding="utf-8")
        reapack = (ROOT / "scripts" / "install-reapack.sh").read_text(encoding="utf-8")
        self.assertIn("reaper realtime-privileges", packages)
        self.assertNotIn("reapack", packages.split("BASE_PACKAGES=(", 1)[1].split(")", 1)[0])
        self.assertIn('bash "$ROOT/scripts/install-reapack.sh"', installer)
        self.assertIn("sha256sum --check", reapack)
        self.assertIn("35d80f63d8174c964af589c7d87c4728aa18f06899dce873e33f8d552d1bc7e0", reapack)

    def test_deployer_installs_the_apps_used_by_the_launchers(self):
        deploy = (ROOT / "scripts" / "deploy.sh").read_text(encoding="utf-8")
        dots_guard = (ROOT / "install.sh").read_text(encoding="utf-8")
        self.assertIn('"$DOTS_ROOT/apps/$app"', deploy)
        self.assertIn('"$HOME/.local/share/fenrir/apps/$app"', deploy)
        self.assertIn('"$HOME/.local/share/fenrir/apps/fenrir-settings/app.py"', deploy)
        self.assertIn('"$HOME/.local/share/fenrir/apps/fenrir-welcome/app.py"', deploy)
        self.assertIn('"$DOTS_DIR/apps/fenrir-settings/app.py"', dots_guard)
        self.assertIn('"$DOTS_DIR/apps/fenrir-welcome/app.py"', dots_guard)

    def test_installer_contract_preserves_non_destructive_storage_and_no_reboot(self):
        installer = (ROOT / "install.sh").read_text(encoding="utf-8")
        storage = (ROOT / "scripts" / "configure-storage.py").read_text(encoding="utf-8")
        self.assertIn('PROTECTED_MOUNT_PREFIXES = ("/mnt/storage",)', storage)
        self.assertIn("UUID={uuid}", storage)
        self.assertIn("nofail", storage)
        self.assertNotIn("mkfs.", installer)
        self.assertNotIn("parted ", installer)
        import re
        destructive_commands = re.compile(r"(?m)^\s*(?:sudo\s+)?(?:mkfs(?:\.[\w]+)?|parted|fdisk|sfdisk|sgdisk|reboot|shutdown)\b")
        self.assertIsNone(destructive_commands.search(installer))


if __name__ == "__main__":
    unittest.main()
