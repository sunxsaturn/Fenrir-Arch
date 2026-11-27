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
            "bin/fenrir-wallpaper",
            "bin/fenrir_wallpaper_library.py",
            "tests/test_theme_wallpaper.py",
            "tests/test_wallpaper_library_sync.py",
            "apps/fenrir-doctor/server.py",
            "apps/fenrir-doctor/index.html",
            "apps/fenrir-doctor/assets/app.js",
            "apps/fenrir-doctor/assets/style.css",
            "bin/fenrir-doctor",
            "bin/fenrir-upgrade",
            "bin/fenrir-wallpaper",
            "tests/test_theme_wallpaper.py",
            "systemd/user/fenrir-doctor.service",
            "applications/fenrir-doctor.desktop",
            "config/icons/Fenrir-Obsidian/scalable/apps/fenrir-doctor.svg",
            "tests/test_fenrir_doctor.py",
        )
        self.assertIn('DOTS_VERSION="$(cat "$DOTS_DIR/VERSION" 2>/dev/null || true)"', installer)
        self.assertIn('[[ "$DOTS_VERSION" == "0.14.1" ]]', installer)
        self.assertIn('apps/fenrir-doctor/assets/app.js', installer)
        self.assertIn('apps/fenrir-doctor/server.py', installer)
        self.assertIn('DOTS_COMMIT="${FENRIR_DOTS_COMMIT:-9b9e85c084e397141389c28778988bf009280fcf}"', installer)
        self.assertIn('CATALOG_COMMIT="${FENRIR_CATALOG_COMMIT:-d8742dde2c7540cc2d18eef8ed1cc58a2a12de04}"', installer)
        self.assertIn('git -C "$DOTS_DIR" checkout --detach "$DOTS_COMMIT"', installer)
        self.assertIn('[[ "$DOTS_HEAD" == "$DOTS_COMMIT" ]]', installer)
        self.assertIn("write_installed_versions", installer)
        self.assertIn("installed-versions.json", installer)
        self.assertIn('chmod 0600 "$temporary"', installer)
        self.assertIn('mv -f -- "$temporary" "$manifest"', installer)
        self.assertIn('"Fenrir-Arch": "%s"', installer)
        self.assertIn('"Fenrir-Dots": "%s"', installer)
        self.assertIn('"Fenrir-Wallpaper-Catalog": "%s"', installer)
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
        expected_commit = "9b9e85c084e397141389c28778988bf009280fcf"
        actual_commit = subprocess.run(
            ["git", "-C", str(dots), "rev-parse", "HEAD"],
            check=True, capture_output=True, text=True,
        ).stdout.strip()
        self.assertEqual(actual_commit, expected_commit)
        self.assertEqual((dots / "VERSION").read_text(encoding="utf-8").strip(), "0.14.1")

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
        expected_commit = "d8742dde2c7540cc2d18eef8ed1cc58a2a12de04"
        self.assertIn(expected_commit, installer)
        self.assertIn(expected_commit, setup)
        self.assertIn('git -C "$CATALOG_SOURCE" checkout --detach "$CATALOG_COMMIT"', setup)
        self.assertIn('[[ "$actual" == "$CATALOG_COMMIT" ]]', setup)
        self.assertIn('[[ "$version" == "0.35.0" ]]', setup)
        required = (
            "pyproject.toml",
            "src/fenrir_catalog/__init__.py",
            "src/fenrir_catalog/cli.py",
            "src/fenrir_catalog/desktop_sync.py",
            "src/fenrir_catalog/acquisition_queue.py",
            "src/fenrir_catalog/rights_review.py",
            "src/fenrir_catalog/rights_assignments.py",
            "src/fenrir_catalog/rights_review_board.py",
            "src/fenrir_catalog/quarantine_review.py",
            "src/fenrir_catalog/deduplication.py",
            "tests/test_deduplication.py",
            "tests/test_acceptance.py",
            "src/fenrir_catalog/rights_board_assets/index.html",
            "src/fenrir_catalog/rights_board_assets/app.js",
            "src/fenrir_catalog/rights_board_assets/style.css",
            "tests/test_rights_review.py",
            "tests/test_rights_assignments.py",
            "tests/test_rights_review_board.py",
            "src/fenrir_catalog/consumer.py",
            "src/fenrir_catalog/library.py",
            "src/fenrir_catalog/picker.py",
            "src/fenrir_catalog/picker_assets/index.html",
            "src/fenrir_catalog/picker_assets/app.js",
            "src/fenrir_catalog/picker_assets/style.css",
            "tests/test_picker.py",
            "src/fenrir_catalog/schemas/wallpaper-library-manifest-v1.schema.json",
            "tests/test_desktop_sync.py",
            "src/fenrir_catalog/campaign.py",
            "src/fenrir_catalog/campaign_profiles.py",
            "src/fenrir_catalog/adapters/commons.py",
            "src/fenrir_catalog/adapters/cleveland.py",
            "src/fenrir_catalog/migrations/0015_cleveland_open_access.sql",
            "tests/test_cleveland.py",
            "src/fenrir_catalog/palette_policy.py",
            "src/fenrir_catalog/palette_index.py",
            "src/fenrir_catalog/collection_portability.py",
            "src/fenrir_catalog/quality_dashboard.py",
            "src/fenrir_catalog/migrations/0014_discovery_campaigns.sql",
            "tests/test_workbench.py",
            "tests/test_campaign.py",
            "tests/test_acquisition_queue.py",
            "tests/test_palette_policy.py",
            "tests/test_palette_index.py",
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
