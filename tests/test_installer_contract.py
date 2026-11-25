import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class InstallerIntegrationTests(unittest.TestCase):
    def test_reapack_uses_official_arch_package_when_enabled(self):
        packages = (ROOT / "scripts" / "packages.sh").read_text(encoding="utf-8")
        installer = (ROOT / "install.sh").read_text(encoding="utf-8")
        deploy = (ROOT / "scripts" / "deploy.sh").read_text(encoding="utf-8")
        self.assertIn("packages+=(reapack)", packages)
        self.assertIn('install_packages "$AI" "$REAPACK"', installer)
        self.assertIn('pacman -Q reapack', deploy)
        self.assertNotIn("install-reapack.sh", installer)


    def test_sun_ai_is_a_complete_versioned_companion_repo_component(self):
        installer = (ROOT / "install.sh").read_text(encoding="utf-8")
        deploy = (ROOT / "scripts" / "deploy.sh").read_text(encoding="utf-8")
        required = (
            "apps/sun-ai/README.md",
            "apps/sun-ai/server.py",
            "apps/sun-ai/index.html",
            "apps/sun-ai/assets/app.js",
            "apps/sun-ai/assets/style.css",
            "bin/sun-ai",
            "systemd/user/sun-ai.service",
            "applications/sun-ai.desktop",
            "config/icons/Fenrir-Obsidian/scalable/apps/sun-ai.svg",
            "tests/test_sun_ai.py",
        )
        self.assertIn('DOTS_VERSION="$(cat "$DOTS_DIR/VERSION" 2>/dev/null || true)"', installer)
        self.assertIn('[[ "$DOTS_VERSION" == "0.4.0" ]]', installer)
        for path in required:
            self.assertIn(path, installer)
        self.assertIn('"$DOTS_ROOT/apps/sun-ai/."', deploy)
        self.assertIn('"$DOTS_ROOT/systemd/user/sun-ai.service"', deploy)
        self.assertIn('"$HOME/.local/bin/sun-ai"', deploy)
        self.assertIn('"$HOME/.local/share/sun-ai/assets/app.js"', deploy)
        self.assertIn('"$HOME/.config/systemd/user/sun-ai.service"', deploy)

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
