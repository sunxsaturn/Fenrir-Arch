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
        self.assertTrue(STORAGE.is_protected_mountpoint("/mnt/storage/"))

    def test_descendants_are_excluded(self):
        self.assertTrue(STORAGE.is_protected_mountpoint("/mnt/storage/archive"))
        self.assertTrue(STORAGE.is_protected_mountpoint("/mnt/storage/games/library"))

    def test_similar_prefix_is_not_excluded(self):
        self.assertFalse(STORAGE.is_protected_mountpoint("/mnt/storage2"))
        self.assertFalse(STORAGE.is_protected_mountpoint("/mnt/storage-backup"))
        self.assertFalse(STORAGE.is_protected_mountpoint("/mnt/fenrir/data"))

    def test_empty_mountpoint_is_safe(self):
        self.assertFalse(STORAGE.is_protected_mountpoint(None))
        self.assertFalse(STORAGE.is_protected_mountpoint(""))

    def test_fstab_protects_unmounted_uuid_partuuid_and_device_entries(self):
        contents = (
            "UUID=data-uuid /mnt/storage ext4 defaults 0 2\n"
            "PARTUUID=partition-id /mnt/storage/archive\\040backup ext4 defaults 0 2\n"
            "/dev/sdb3 /mnt/storage/legacy ext4 defaults 0 2\n"
            "UUID=other-uuid /mnt/storage2 ext4 defaults 0 2\n"
        )
        uuids, partuuids, devices = STORAGE.protected_fstab_sources(contents)
        self.assertEqual(uuids, {"data-uuid"})
        self.assertEqual(partuuids, {"partition-id"})
        self.assertIn("/dev/sdb3", devices)
        self.assertNotIn("other-uuid", uuids)

    def test_fstab_target_with_escaped_space_is_protected(self):
        self.assertTrue(
            STORAGE.is_protected_mountpoint(
                STORAGE.decode_fstab_field(r"/mnt/storage/old\\040games")
            )
        )


if __name__ == "__main__":
    unittest.main()
