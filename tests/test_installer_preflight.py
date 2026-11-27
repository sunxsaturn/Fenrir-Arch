import unittest
from pathlib import Path


INSTALLER = Path(__file__).resolve().parents[1] / "install.sh"
PREFLIGHT = 'if ! python3 "$ROOT/scripts/check-wallpaper-ready.py"; then'


class InstallerPreflightTests(unittest.TestCase):
    def test_gallery_preflight_precedes_every_install_mutation(self):
        source = INSTALLER.read_text(encoding="utf-8")
        preflight = source.index(PREFLIGHT)
        mutation_markers = (
            "sudo pacman -Syu",
            "sudo cp -a /etc/pacman.conf",
            "sudo flatpak remote-add",
            'bash "$DOTS_DIR/scripts/install-dots.sh"',
            'bash "$ROOT/scripts/install-catalog.sh"',
        )
        for marker in mutation_markers:
            with self.subTest(marker=marker):
                self.assertGreater(source.index(marker), preflight)

    def test_gallery_preflight_runs_exactly_once(self):
        source = INSTALLER.read_text(encoding="utf-8")
        self.assertEqual(source.count(PREFLIGHT), 1)

    def test_incomplete_gallery_error_promises_no_partial_install(self):
        source = INSTALLER.read_text(encoding="utf-8")
        preflight = source.index(PREFLIGHT)
        following = source[preflight:source.index("fi", preflight) + 2]
        self.assertIn("No system packages, services or configuration were changed", following)


if __name__ == "__main__":
    unittest.main()
