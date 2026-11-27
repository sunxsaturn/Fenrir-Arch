import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SYNC_SCRIPT = ROOT / "scripts" / "sync-wallpaper-library.sh"


def preflight(*, planned=2, present=1, unique=3, sufficient=True):
    return {
        "dry_run": True,
        "active_volumes": ["volume-01", "volume-02", "volume-03"],
        "manifest_records": 4,
        "unique_images": unique,
        "planned_downloads": planned,
        "selected_downloads": planned,
        "selected_download_bytes": planned * 4096,
        "remaining_after_limit": 0,
        "already_present": present,
        "storage_preflight": {
            "destination_available_bytes": 10**9 if sufficient else 1,
            "destination_required_bytes": planned * 4096,
            "state_available_bytes": 10**9 if sufficient else 1,
            "state_required_bytes": planned * 4096,
            "sufficient": sufficient,
        },
    }


def sync_result(*, downloaded=2, present=1, unique=3):
    return {
        "dry_run": False,
        "downloaded": downloaded,
        "already_present": present,
        "failed": 0,
        "unique_images": unique,
        "remaining_after_limit": 0,
    }


class WallpaperInstallGateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.cli = self.home / ".local" / "bin" / "fenrir-wallpaper"
        self.cli.parent.mkdir(parents=True)
        self.calls = self.root / "calls.jsonl"
        self.config = self.root / "responses.json"
        self.cli.write_text(
            """#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path

config = json.loads(Path(os.environ["FENRIR_TEST_CONFIG"]).read_text())
calls_path = Path(os.environ["FENRIR_TEST_CALLS"])
args = sys.argv[1:]
with calls_path.open("a", encoding="utf-8") as stream:
    stream.write(json.dumps(args) + "\\n")
calls = [json.loads(line) for line in calls_path.read_text().splitlines()]
if args == ["sync-library", "--dry-run", "--json"]:
    count = sum(call == args for call in calls)
    payload = config["preflight_before"] if count == 1 else config["preflight_after"]
elif args == ["sync-library", "--json"]:
    payload = config["sync"]
    print(json.dumps(payload))
    raise SystemExit(config.get("sync_exit", 0))
else:
    print("Unexpected wallpaper CLI arguments: " + repr(args), file=sys.stderr)
    raise SystemExit(97)
print(json.dumps(payload))
""",
            encoding="utf-8",
        )
        self.cli.chmod(0o755)
        self.env = os.environ.copy()
        self.env.update({
            "HOME": str(self.home),
            "FENRIR_TEST_CONFIG": str(self.config),
            "FENRIR_TEST_CALLS": str(self.calls),
        })

    def tearDown(self):
        self.temp.cleanup()

    def configure(self, *, before=None, sync=None, after=None, sync_exit=0):
        payload = {
            "preflight_before": before or preflight(),
            "sync": sync or sync_result(),
            "preflight_after": after or preflight(planned=0, present=3),
            "sync_exit": sync_exit,
        }
        self.config.write_text(json.dumps(payload), encoding="utf-8")

    def run_gate(self, *, confirmation="1", stdin=""):
        return subprocess.run(
            ["bash", str(SYNC_SCRIPT), confirmation],
            cwd=ROOT,
            env=self.env,
            input=stdin,
            text=True,
            capture_output=True,
            check=False,
        )

    def recorded_calls(self):
        if not self.calls.exists():
            return []
        return [json.loads(line) for line in self.calls.read_text().splitlines()]

    def test_success_runs_preflight_sync_and_final_zero_missing_check(self):
        self.configure()
        result = self.run_gate()

        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        self.assertIn("all 3 images are present", result.stdout)
        self.assertEqual(self.recorded_calls(), [
            ["sync-library", "--dry-run", "--json"],
            ["sync-library", "--json"],
            ["sync-library", "--dry-run", "--json"],
        ])
        self.assertFalse(any("--limit" in call for call in self.recorded_calls()))

    def test_insufficient_storage_stops_before_any_image_transfer(self):
        self.configure(before=preflight(sufficient=False))

        result = self.run_gate()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Insufficient free space", result.stderr)
        self.assertEqual(self.recorded_calls(), [
            ["sync-library", "--dry-run", "--json"],
        ])

    def test_declined_interactive_download_does_not_start_sync(self):
        self.configure()

        result = self.run_gate(confirmation="0", stdin="n\n")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Wallpaper synchronization was declined", result.stderr)
        self.assertEqual(self.recorded_calls(), [
            ["sync-library", "--dry-run", "--json"],
        ])

    def test_interrupted_sync_fails_closed_and_explains_resume_path(self):
        self.configure(sync_exit=7)

        result = self.run_gate()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("rerun ./install.sh to resume verified partial transfers", result.stderr)
        self.assertEqual(self.recorded_calls(), [
            ["sync-library", "--dry-run", "--json"],
            ["sync-library", "--json"],
        ])

    def test_incomplete_final_inventory_prevents_success(self):
        self.configure(after=preflight(planned=1, present=2))

        result = self.run_gate()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("final inventory still has 1 missing images", result.stderr)
        self.assertEqual(self.recorded_calls(), [
            ["sync-library", "--dry-run", "--json"],
            ["sync-library", "--json"],
            ["sync-library", "--dry-run", "--json"],
        ])

    def test_invalid_preflight_report_stops_before_sync(self):
        invalid = preflight()
        invalid["storage_preflight"].pop("state_required_bytes")
        self.configure(before=invalid)

        result = self.run_gate()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("preflight report was invalid", result.stderr)
        self.assertEqual(self.recorded_calls(), [
            ["sync-library", "--dry-run", "--json"],
        ])


if __name__ == "__main__":
    unittest.main()
