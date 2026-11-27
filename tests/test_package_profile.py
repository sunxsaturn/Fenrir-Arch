import unittest
from pathlib import Path


PACKAGES = Path(__file__).resolve().parents[1] / "scripts" / "packages.sh"


class PackageProfileTests(unittest.TestCase):
    def test_theme_and_audio_runtime_dependencies_are_installed(self):
        source = PACKAGES.read_text(encoding="utf-8")
        required = ("starship", "qt6ct", "qjackctl", "python-pip")
        for package in required:
            with self.subTest(package=package):
                self.assertRegex(source, rf"(?<![A-Za-z0-9_-]){package}(?![A-Za-z0-9_-])")

    def test_requested_desktop_and_audio_stack_is_present(self):
        source = PACKAGES.read_text(encoding="utf-8")
        required = (
            "hyprland", "quickshell", "waybar", "kitty", "sddm", "steam", "gamemode",
            "mangohud", "gamescope", "pipewire-jack", "easyeffects",
            "qpwgraph", "guitarix", "calf", "reaper", "reapack",
        )
        for package in required:
            with self.subTest(package=package):
                self.assertRegex(source, rf"(?<![A-Za-z0-9_-]){package}(?![A-Za-z0-9_-])")


if __name__ == "__main__":
    unittest.main()
