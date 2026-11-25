import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class SystemSetupTests(unittest.TestCase):
    def test_multilib_helper_only_uncomments_standard_multilib_block(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "pacman.conf"
            path.write_text(
                "[options]\nColor\n\n# [multilib]\n#Include = /etc/pacman.d/mirrorlist\n\n[custom]\nServer = https://example.invalid/$repo/os/$arch\n",
                encoding="utf-8",
            )
            result = subprocess.run([sys.executable, str(ROOT / "scripts/enable_multilib.py"), str(path)], text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            changed = path.read_text(encoding="utf-8")
            self.assertIn("[multilib]\nInclude = /etc/pacman.d/mirrorlist", changed)
            self.assertIn("[custom]\nServer = https://example.invalid/$repo/os/$arch", changed)

    def test_multilib_helper_refuses_missing_section(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "pacman.conf"
            path.write_text("[options]\nColor\n", encoding="utf-8")
            result = subprocess.run([sys.executable, str(ROOT / "scripts/enable_multilib.py"), str(path)], text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("No [multilib] section", result.stderr)



if __name__ == "__main__":
    unittest.main()
