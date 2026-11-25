#!/usr/bin/python
"""GTK4 guided installer frontend for Fenrir Arch."""
from __future__ import annotations
import os
import subprocess
import sys
from pathlib import Path
import gi

gi.require_version("Gtk", "4.0")
from gi.repository import Gio, GLib, Gtk

class FenrirInstaller(Gtk.Application):
    def __init__(self, installer: Path):
        super().__init__(application_id="dev.fenrir.Installer", flags=Gio.ApplicationFlags.DEFAULT_FLAGS)
        self.installer = installer
        self.process = None
        self.log_path = Path.home() / ".local/state/fenrir/installer.log"
        self.log_offset = 0

    def do_activate(self):
        self.window = Gtk.ApplicationWindow(application=self)
        self.window.set_title("Fenrir Setup")
        self.window.set_default_size(800, 760)
        self.window.connect("close-request", self.on_close)
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        root.set_margin_top(24); root.set_margin_bottom(22); root.set_margin_start(26); root.set_margin_end(26)

        heading = Gtk.Label(label="Set up your Fenrir desktop")
        heading.set_xalign(0); heading.add_css_class("title-1")
        root.append(heading)
        intro = Gtk.Label(label="This guided installer configures Arch Linux with Hyprland, the Fenrir visual environment, gaming and audio production tools. Review the options, then start the installation.")
        intro.set_wrap(True); intro.set_xalign(0); intro.add_css_class("dim-label")
        root.append(intro)

        features = Gtk.Frame()
        feature_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        feature_box.set_margin_top(14); feature_box.set_margin_bottom(14); feature_box.set_margin_start(16); feature_box.set_margin_end(16)
        title = Gtk.Label(label="Included in the full profile")
        title.set_xalign(0); title.add_css_class("heading")
        feature_box.append(title)
        feature_box.append(Gtk.Label(label="Hyprland · Waybar · Fenrir Dots · Firefox Nightly · Steam · GameMode · MangoHud · Gamescope · Heroic · RPCS3 · Prism Launcher · Discord · Spotify · Whatsie · PipeWire · EasyEffects · QPWgraph · Guitarix · Calf · REAPER · Sun AI", wrap=True, xalign=0))
        features.set_child(feature_box); root.append(features)

        ai_row, self.ai = self.option("Install Sun AI and Ollama Vulkan", "No language model is downloaded automatically.", True)
        storage_row, self.storage = self.option("Mount eligible fixed data disks at boot", "Uses filesystem UUIDs and nofail; excludes root, boot and removable devices. No formatting.", True)
        wol_row, self.wol = self.option("Enable Ethernet Wake-on-LAN", "Applies magic-packet mode where the network adapter advertises support; firmware settings may also be required.", True)
        for widget in (ai_row, storage_row, wol_row): root.append(widget)

        advanced = Gtk.Expander(label="Advanced customization")
        advanced.set_expanded(False)
        advanced_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        advanced_box.set_margin_top(10); advanced_box.set_margin_bottom(10)
        advanced_box.set_margin_start(14); advanced_box.set_margin_end(14)
        advanced_note = Gtk.Label(
            label="Optional components are verified separately. The default profile uses official Arch packages and Flathub; it does not use an AUR helper or download AI models.",
            wrap=True,
            xalign=0,
        )
        advanced_note.add_css_class("dim-label")
        advanced_box.append(advanced_note)
        reapack_row, self.reapack = self.option(
            "Install ReaPack for REAPER",
            "Installs the signed ReaPack package from official Arch Extra; no AUR helper or custom binary download is used.",
            True,
        )
        advanced_box.append(reapack_row)
        advanced.set_child(advanced_box)
        root.append(advanced)

        root.append(Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL))
        status = Gtk.Label(label="The installer will keep the screen awake and disable automatic idle locking. Monitor target: 2560×1440 @ 155 Hz (only if supported by the connected display).")
        status.set_wrap(True); status.set_xalign(0)
        root.append(status)

        self.progress = Gtk.ProgressBar(show_text=True)
        self.progress.set_text("Ready")
        root.append(self.progress)
        self.log_view = Gtk.TextView(editable=False, cursor_visible=False, monospace=True, wrap_mode=Gtk.WrapMode.WORD_CHAR)
        self.log_view.set_size_request(-1, 190)
        scroll = Gtk.ScrolledWindow(min_content_height=190, vexpand=True)
        scroll.set_child(self.log_view)
        root.append(scroll)

        actions = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        actions.append(Gtk.Box(hexpand=True))
        self.start_button = Gtk.Button(label="Start full installation")
        self.start_button.add_css_class("suggested-action")
        self.start_button.connect("clicked", self.start_install)
        actions.append(self.start_button)
        root.append(actions)
        self.window.set_child(root)
        self.window.present()

    def option(self, title: str, description: str, active: bool):
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        labels = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3)
        labels.set_hexpand(True)
        name = Gtk.Label(label=title); name.set_xalign(0); name.add_css_class("heading")
        detail = Gtk.Label(label=description, wrap=True); detail.set_xalign(0); detail.add_css_class("dim-label")
        labels.append(name); labels.append(detail); row.append(labels)
        check = Gtk.CheckButton(active=active, valign=Gtk.Align.CENTER)
        row.append(check)
        return row, check

    def start_install(self, *_):
        if self.process:
            return
        args = ["bash", str(self.installer), "--cli", "--yes"]
        if not self.ai.get_active(): args.append("--no-ai")
        if not self.reapack.get_active(): args.append("--no-reapack")
        if not self.storage.get_active(): args.append("--no-storage")
        if not self.wol.get_active(): args.append("--no-wol")
        self.log_path.parent.mkdir(parents=True, exist_ok=True)
        self.log_offset = 0
        log = open(self.log_path, "w", encoding="utf-8")
        self.process = subprocess.Popen(args, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        log.close()
        self.start_button.set_sensitive(False)
        self.progress.set_fraction(0.05)
        self.progress.set_text("Installing — pacman may ask you to review packages")
        GLib.timeout_add(400, self.poll_install)

    def poll_install(self):
        try:
            with open(self.log_path, "r", encoding="utf-8", errors="replace") as stream:
                stream.seek(self.log_offset)
                chunk = stream.read()
                self.log_offset = stream.tell()
            if chunk:
                buffer = self.log_view.get_buffer()
                buffer.insert(buffer.get_end_iter(), chunk)
                mark = buffer.create_mark(None, buffer.get_end_iter(), False)
                self.log_view.scroll_mark_onscreen(mark)
        except OSError:
            pass
        code = self.process.poll()
        if code is None:
            return GLib.SOURCE_CONTINUE
        self.process = None
        self.start_button.set_sensitive(True)
        if code == 0:
            self.progress.set_fraction(1.0)
            self.progress.set_text("Installation completed")
            self.message("Fenrir is installed", "Log out, choose Hyprland in SDDM, and open Fenrir Control Center for the post-install guide and customization settings.")
        else:
            self.progress.set_fraction(0.0)
            self.progress.set_text(f"Installation stopped with exit code {code}")
            self.message("Installation needs attention", f"Review the log at {self.log_path}. Fix the reported issue and rerun ./install.sh.")
        return GLib.SOURCE_REMOVE

    def on_close(self, *_):
        if self.process and self.process.poll() is None:
            self.message("Installation is running", "Do not close this window while pacman or system configuration is running. Wait for the installer to finish.")
            return True
        return False

    def message(self, title: str, body: str):
        dialog = Gtk.MessageDialog(transient_for=self.window, modal=True, message_type=Gtk.MessageType.INFO, buttons=Gtk.ButtonsType.OK, text=title)
        dialog.set_secondary_text(body)
        dialog.connect("response", lambda d, _r: d.destroy())
        dialog.present()


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit("usage: fenrir-installer.py /path/to/install.sh")
    app = FenrirInstaller(Path(sys.argv[1]).resolve())
    return app.run(sys.argv[:1])

if __name__ == "__main__":
    raise SystemExit(main())
