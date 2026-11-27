import shlex
import subprocess
import tomllib
import unittest
from pathlib import Path


INSTALLER = Path(__file__).resolve().parents[1] / "install.sh"
PREFLIGHT = 'if ! python3 "$ROOT/scripts/check-wallpaper-ready.py"; then'


class InstallerPreflightTests(unittest.TestCase):

    def test_catalog_only_repository_pin_command_extracts_the_locked_url(self):
        source = INSTALLER.read_text(encoding="utf-8")
        assignment = next(
            line.strip() for line in source.splitlines()
            if line.strip().startswith("CATALOG_REPO=")
            and "catalog_repository" in line
            and "components.lock" in line
        )
        command = (
            f"ROOT={shlex.quote(str(INSTALLER.parent))}; "
            f"{assignment}; printf '%s' \"$CATALOG_REPO\""
        )
        result = subprocess.run(
            ["bash", "-c", command], check=True, capture_output=True, text=True
        )
        lock = tomllib.loads((INSTALLER.parent / "components.lock").read_text())
        self.assertEqual(result.stdout, lock["catalog_repository"])

    def test_gallery_preflight_precedes_every_install_mutation(self):
        source = INSTALLER.read_text(encoding="utf-8")
        preflight = source.index(PREFLIGHT)
        mutation_markers = (
            "sudo pacman -Syu",
            "sudo cp -a /etc/pacman.conf",
            "sudo flatpak remote-add",
            'bash "$DOTS_DIR/scripts/install-dots.sh"',
        )
        for marker in mutation_markers:
            with self.subTest(marker=marker):
                self.assertGreater(source.index(marker), preflight)

    def test_catalog_only_mode_prepares_discovery_without_full_install(self):
        source = INSTALLER.read_text(encoding="utf-8")
        mode = source.index("if (( CATALOG_ONLY )); then")
        catalog = source.index('bash "$ROOT/scripts/install-catalog.sh"', mode)
        gate = source.index(PREFLIGHT)
        packages = source.index("sudo pacman -Syu")
        self.assertLess(mode, catalog)
        self.assertLess(catalog, gate)
        self.assertLess(gate, packages)
        self.assertIn("No desktop packages or desktop configuration were changed", source)

    def test_catalog_only_checks_private_access_before_python_pip_install(self):
        source = INSTALLER.read_text(encoding="utf-8")
        mode = source.index("if (( CATALOG_ONLY )); then")
        access = source.index('git ls-remote "$CATALOG_REPO"', mode)
        pip_install = source.index("sudo pacman -S --needed python-pip", mode)
        catalog_install = source.index('bash "$ROOT/scripts/install-catalog.sh"', mode)
        self.assertLess(access, pip_install)
        self.assertLess(pip_install, catalog_install)

    def test_catalog_user_timer_is_enabled_for_next_login(self):
        catalog_script = INSTALLER.parent / "scripts" / "install-catalog.sh"
        source = catalog_script.read_text(encoding="utf-8")
        self.assertIn("timers.target.wants", source)
        self.assertIn("ln -sfn ../fenrir-catalog-discovery.timer", source)

    def test_catalog_only_is_portable_but_full_installer_remains_arch_only(self):
        source = INSTALLER.read_text(encoding="utf-8")
        catalog_mode = source.index("if (( CATALOG_ONLY )); then")
        arch_guard = source.index("require_arch")
        self.assertLess(catalog_mode, arch_guard)
        self.assertIn("arch|debian|ubuntu", source)
        self.assertIn("sudo apt-get install -y python3-venv", source)
        self.assertIn("require_arch", source)

    def test_catalog_only_debian_prerequisite_is_scoped_and_access_checked_first(self):
        source = INSTALLER.read_text(encoding="utf-8")
        mode = source.index("if (( CATALOG_ONLY )); then")
        access = source.index('git ls-remote "$CATALOG_REPO"', mode)
        apt_install = source.index("sudo apt-get install -y python3-venv", mode)
        catalog_install = source.index('bash "$ROOT/scripts/install-catalog.sh"', mode)
        self.assertLess(access, apt_install)
        self.assertLess(apt_install, catalog_install)
        self.assertNotIn("sudo apt-get upgrade", source)

    def test_gallery_preflight_runs_exactly_once(self):
        source = INSTALLER.read_text(encoding="utf-8")
        self.assertEqual(source.count(PREFLIGHT), 1)

    def test_incomplete_gallery_error_promises_no_partial_install(self):
        source = INSTALLER.read_text(encoding="utf-8")
        preflight = source.index(PREFLIGHT)
        following = source[preflight:source.index("\nfi\n", preflight)]
        self.assertIn("No system packages, services or configuration were changed", following)


if __name__ == "__main__":
    unittest.main()
