import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "fenrir_configure_storage", ROOT / "scripts" / "configure-storage.py"
)
STORAGE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(STORAGE)


class ProtectedStorageTests(unittest.TestCase):
    def test_protected_mount_itself_is_excluded(self):
        self.assertTrue(STORAGE.is_protected_mountpoint("/mnt/storage"))

    def test_descendants_of_protected_mount_are_excluded(self):
        self.assertTrue(STORAGE.is_protected_mountpoint("/mnt/storage/archive"))
        self.assertTrue(STORAGE.is_protected_mountpoint("/mnt/storage/games/library"))

    def test_similar_prefix_is_not_excluded(self):
        self.assertFalse(STORAGE.is_protected_mountpoint("/mnt/storage2"))
        self.assertFalse(STORAGE.is_protected_mountpoint("/mnt/fenrir/data"))

    def test_empty_mountpoint_is_not_treated_as_protected(self):
        self.assertFalse(STORAGE.is_protected_mountpoint(None))


if __name__ == "__main__":
    unittest.main()
