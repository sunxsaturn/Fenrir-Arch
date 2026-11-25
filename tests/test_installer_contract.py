import os
import subprocess
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


    def test_fenrir_doctor_is_a_complete_versioned_companion_repo_component(self):
        installer = (ROOT / "install.sh").read_text(encoding="utf-8")
        deploy = (ROOT / "scripts" / "deploy.sh").read_text(encoding="utf-8")
        catalog = (ROOT / "scripts" / "install-catalog.sh").read_text(encoding="utf-8")
        wizard = (ROOT / "scripts" / "fenrir-installer.py").read_text(encoding="utf-8")
        required = (
            "apps/fenrir-doctor/README.md",
            "apps/fenrir-doctor/server.py",
            "apps/fenrir-doctor/index.html",
            "apps/fenrir-doctor/assets/app.js",
            "apps/fenrir-doctor/assets/style.css",
            "bin/fenrir-doctor",
            "bin/fenrir-upgrade",
            "systemd/user/fenrir-doctor.service",
            "applications/fenrir-doctor.desktop",
            "config/icons/Fenrir-Obsidian/scalable/apps/fenrir-doctor.svg",
            "tests/test_fenrir_doctor.py",
        )
        self.assertIn('DOTS_VERSION="$(cat "$DOTS_DIR/VERSION" 2>/dev/null || true)"', installer)
        self.assertIn('[[ "$DOTS_VERSION" == "0.5.0" ]]', installer)
        self.assertIn('DOTS_COMMIT="${FENRIR_DOTS_COMMIT:-4c9980b8f2ec01146fd417f3cdb59170db242499}"', installer)
        self.assertIn('CATALOG_COMMIT="${FENRIR_CATALOG_COMMIT:-cd4dc6be4644042b121c515f540c563cef1b1114}"', installer)
        self.assertIn('git -C "$DOTS_DIR" checkout --detach "$DOTS_COMMIT"', installer)
        self.assertIn('[[ "$DOTS_HEAD" == "$DOTS_COMMIT" ]]', installer)
        self.assertIn('install_fenrir_doctor "$AI"', installer)
        self.assertIn('bash "$ROOT/scripts/install-catalog.sh"', installer)
        self.assertIn("AI=1", installer)
        self.assertNotIn("--no-ai", installer)
        self.assertNotIn("--no-ai", wizard)
        self.assertNotIn("self.ai", wizard)
        for path in required:
            self.assertIn(path, installer)
        self.assertIn('"$DOTS_ROOT/apps/fenrir-doctor/."', deploy)
        self.assertIn('"$DOTS_ROOT/systemd/user/fenrir-doctor.service"', deploy)
        self.assertIn('"$HOME/.local/bin/fenrir-doctor"', deploy)
        self.assertIn('"$HOME/.local/share/fenrir-doctor/assets/app.js"', deploy)
        self.assertIn('"$HOME/.config/systemd/user/fenrir-doctor.service"', deploy)
        self.assertIn("src/fenrir_catalog/desktop_sync.py", catalog)
        self.assertIn('"$VENV/bin/fenrir-catalog" init --database "$CATALOG_DB"', catalog)
        self.assertIn('pip install --disable-pip-version-check', catalog)

    def test_ci_companion_checkout_matches_the_pinned_dots_source_manifest(self):
        checkout = os.environ.get("FENRIR_DOTS_CHECKOUT")
        if not checkout:
            self.skipTest("CI supplies the pinned Fenrir-Dots checkout for integration validation.")

        dots = Path(checkout)
        expected_commit = "4c9980b8f2ec01146fd417f3cdb59170db242499"
        actual_commit = subprocess.run(
            ["git", "-C", str(dots), "rev-parse", "HEAD"],
            check=True, capture_output=True, text=True,
        ).stdout.strip()
        self.assertEqual(actual_commit, expected_commit)
        self.assertEqual((dots / "VERSION").read_text(encoding="utf-8").strip(), "0.5.0")

        required = (
            "config/hypr/hyprland.lua",
            "apps/fenrir-settings/app.py",
            "apps/fenrir-welcome/app.py",
            "apps/fenrir-settings/monitor.py",
            "apps/fenrir-doctor/README.md",
            "apps/fenrir-doctor/server.py",
            "apps/fenrir-doctor/index.html",
            "apps/fenrir-doctor/assets/app.js",
            "apps/fenrir-doctor/assets/style.css",
            "bin/fenrir-doctor",
            "bin/fenrir-upgrade",
            "systemd/user/fenrir-doctor.service",
            "applications/fenrir-doctor.desktop",
            "config/icons/Fenrir-Obsidian/scalable/apps/fenrir-doctor.svg",
            "tests/test_fenrir_doctor.py",
        )
        for relative in required:
            with self.subTest(path=relative):
                self.assertTrue((dots / relative).is_file(), f"Missing companion source: {relative}")

    def test_catalog_pin_and_runtime_source_manifest_contract(self):
        installer = (ROOT / "install.sh").read_text(encoding="utf-8")
        setup = (ROOT / "scripts" / "install-catalog.sh").read_text(encoding="utf-8")
        expected_commit = "cd4dc6be4644042b121c515f540c563cef1b1114"
        self.assertIn(expected_commit, installer)
        self.assertIn(expected_commit, setup)
        self.assertIn('git -C "$CATALOG_SOURCE" checkout --detach "$CATALOG_COMMIT"', setup)
        self.assertIn('[[ "$actual" == "$CATALOG_COMMIT" ]]', setup)
        self.assertIn('[[ "$version" == "0.19.0" ]]', setup)
        required = (
            "pyproject.toml",
            "src/fenrir_catalog/cli.py",
            "src/fenrir_catalog/desktop_sync.py",
            "src/fenrir_catalog/consumer.py",
            "src/fenrir_catalog/library.py",
            "src/fenrir_catalog/schemas/wallpaper-library-manifest-v1.schema.json",
            "tests/test_desktop_sync.py",
        )
        for relative in required:
            with self.subTest(path=relative):
                self.assertIn(relative, setup)
        self.assertIn('"$VENV/bin/fenrir-catalog" init --database "$CATALOG_DB"', setup)
        self.assertIn('chmod 0700 "$CATALOG_HOME" "$QUARANTINE_ROOT"', setup)
        self.assertIn('exec "$HOME/.local/share/fenrir/catalog-venv/bin/fenrir-catalog" "$@"', setup)
    def test_deployer_installs_the_apps_used_by_the_launchers(self):
        deploy = (ROOT / "scripts" / "deploy.sh").read_text(encoding="utf-8")
        dots_guard = (ROOT / "install.sh").read_text(encoding="utf-8")
        self.assertIn("apps/fenrir-settings/app.py", dots_guard)
        self.assertIn("apps/fenrir-welcome/app.py", dots_guard)
        self.assertIn('"$DOTS_ROOT/apps/$app"', deploy)
        self.assertIn('"$HOME/.local/share/fenrir/apps/$app"', deploy)
        self.assertIn('"$HOME/.local/share/fenrir/apps/fenrir-settings/app.py"', deploy)
        self.assertIn('"$HOME/.local/share/fenrir/apps/fenrir-welcome/app.py"', deploy)

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
