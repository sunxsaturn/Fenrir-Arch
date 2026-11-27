#!/usr/bin/env python3
"""GTK4 guided installer for the Fenrir Arch workstation deployment."""
from __future__ import annotations

import json
import subprocess
import sys
import threading
from pathlib import Path

import gi

gi.require_version("Gtk", "4.0")
from gi.repository import GLib, Gtk  # noqa: E402


class FenrirInstaller(Gtk.Application):
    def __init__(self, root: Path) -> None:
        super().__init__(application_id="org.fenrir.desktop.installer")
        self.root = root
        self.window: Gtk.ApplicationWindow | None = None
        self.output: Gtk.TextBuffer | None = None
        self.install_button: Gtk.Button | None = None
        self.ai_toggle: Gtk.CheckButton | None = None
        self.wol_toggle: Gtk.CheckButton | None = None

    def do_activate(self) -> None:
        if self.window is not None:
            self.window.present()
            return

        self.window = Gtk.ApplicationWindow(application=self)
        self.window.set_title("Fenrir Desktop Installer")
        self.window.set_default_size(760, 640)

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        outer.set_margin_top(24)
        outer.set_margin_bottom(24)
        outer.set_margin_start(28)
        outer.set_margin_end(28)
        self.window.set_child(outer)

        title = Gtk.Label()
        title.set_markup("<span size='xx-large' weight='bold'>FENRIR DESKTOP</span>")
        title.set_xalign(0)
        outer.append(title)

        subtitle = Gtk.Label(label="Arch Linux · Hyprland · Fimbulwinter")
        subtitle.set_xalign(0)
        subtitle.add_css_class("dim-label")
        outer.append(subtitle)

        contract = Gtk.Label(
            label=(
                "This deploys Fenrir onto an existing Arch installation. "
                "It does not partition, format, erase or resize drives; "
                "does not alter /mnt/storage or the secondary SATA SSD; "
                "and does not install a bootloader or reboot."
            )
        )
        contract.set_wrap(True)
        contract.set_xalign(0)
        outer.append(contract)

        profile = Gtk.Frame(label="Installation profile")
        profile_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        profile_box.set_margin_top(10)
        profile_box.set_margin_bottom(10)
        profile_box.set_margin_start(12)
        profile_box.set_margin_end(12)

        self.ai_toggle = Gtk.CheckButton(label="Install Ollama Vulkan and benchmark local models")
        self.ai_toggle.set_active(True)
        profile_box.append(self.ai_toggle)

        self.wol_toggle = Gtk.CheckButton(label="Enable Wake-on-LAN on supported wired interfaces")
        self.wol_toggle.set_active(True)
        profile_box.append(self.wol_toggle)

        storage = Gtk.Label(
            label="Personal data disks: untouched. Automatic fstab changes are disabled."
        )
        storage.set_xalign(0)
        storage.add_css_class("dim-label")
        profile_box.append(storage)
        profile.set_child(profile_box)
        outer.append(profile)

        self.output = Gtk.TextBuffer()
        output_view = Gtk.TextView(buffer=self.output)
        output_view.set_editable(False)
        output_view.set_cursor_visible(False)
        output_view.set_monospace(True)
        output_view.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_child(output_view)
        outer.append(scroll)

        actions = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        self.install_button = Gtk.Button(label="Install Fenrir Desktop")
        self.install_button.add_css_class("suggested-action")
        self.install_button.connect("clicked", self.on_install)
        actions.append(self.install_button)

        close_button = Gtk.Button(label="Close")
        close_button.connect("clicked", lambda _button: self.quit())
        actions.append(close_button)
        outer.append(actions)

        state = self.read_release_state()
        if not state.get("release_ready", False):
            self.install_button.set_sensitive(False)
            self.append_log(
                "The rebuild is not yet release-ready. Installation is disabled.\n"
                "The final component pins, populated 5,000-image gallery and clean "
                "Arch VM acceptance must pass first.\n"
            )
        else:
            self.append_log("Release acceptance passed. Review the profile, then install.\n")

        self.window.present()

    def read_release_state(self) -> dict:
        return json.loads((self.root / "installer/release-state.json").read_text(encoding="utf-8"))

    def append_log(self, message: str) -> None:
        if self.output is None:
            return
        end = self.output.get_end_iter()
        self.output.insert(end, message)

    def on_install(self, _button: Gtk.Button) -> None:
        if self.install_button is not None:
            self.install_button.set_sensitive(False)
        args = ["/usr/bin/bash", str(self.root / "scripts/install-transaction.sh"), "--yes"]
        args.append("--with-ai" if self.ai_toggle and self.ai_toggle.get_active() else "--without-ai")
        args.append("--wol" if self.wol_toggle and self.wol_toggle.get_active() else "--no-wol")
        self.append_log("\nStarting Fenrir installation...\n")
        threading.Thread(target=self.run_install, args=(args,), daemon=True).start()

    def run_install(self, args: list[str]) -> None:
        try:
            process = subprocess.Popen(
                args, cwd=self.root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                text=True, bufsize=1,
            )
            assert process.stdout is not None
            for line in process.stdout:
                GLib.idle_add(self.append_log, line)
            code = process.wait()
        except OSError as exc:
            code = 127
            GLib.idle_add(self.append_log, f"Could not start installer: {exc}\n")
        GLib.idle_add(self.install_finished, code)

    def install_finished(self, code: int) -> bool:
        self.append_log(
            "\nInstallation finished successfully. No reboot was performed.\n"
            if code == 0 else
            f"Installation stopped with exit code {code}. Review the log; no success was reported.\n"
        )
        if self.install_button is not None and code != 0:
            self.install_button.set_sensitive(True)
        return GLib.SOURCE_REMOVE


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: gtk_installer.py /path/to/Fenrir-Arch", file=sys.stderr)
        return 2
    root = Path(sys.argv[1]).resolve()
    application = FenrirInstaller(root)
    return application.run([])


if __name__ == "__main__":
    raise SystemExit(main())
