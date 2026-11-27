#!/usr/bin/env python3
"""Small GTK4 guided installer front-end for Fenrir Desktop."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import gi
gi.require_version("Gtk", "4.0")
from gi.repository import Gtk, Gio


class FenrirWizard(Gtk.Application):
    def __init__(self, installer: Path):
        super().__init__(application_id="org.fenrir.desktop.installer")
        self.installer = installer
        self.checks = {}

    def do_activate(self):
        window = Gtk.ApplicationWindow(application=self)
        window.set_title("Fenrir Desktop Installer")
        window.set_default_size(680, 620)

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=18)
        outer.set_margin_top(28)
        outer.set_margin_bottom(24)
        outer.set_margin_start(30)
        outer.set_margin_end(30)
        window.set_child(outer)

        title = Gtk.Label(label="FENRIR DESKTOP")
        title.add_css_class("title-1")
        title.set_xalign(0)
        outer.append(title)

        subtitle = Gtk.Label(label="A complete Hyprland workstation, installed in one guided run.")
        subtitle.set_xalign(0)
        subtitle.add_css_class("dim-label")
        outer.append(subtitle)

        warning = Gtk.Label(
            label="Arch Linux x86_64 only. This installer does not partition, format, "
                  "erase, mount or rewrite personal disks, install a bootloader, change "
                  "firmware or reboot. /mnt/storage remains protected."
        )
        warning.set_wrap(True)
        warning.set_xalign(0)
        warning.add_css_class("card")
        warning.set_margin_top(4)
        warning.set_margin_bottom(4)
        outer.append(warning)

        heading = Gtk.Label(label="INSTALLATION OPTIONS")
        heading.set_xalign(0)
        heading.add_css_class("heading")
        outer.append(heading)

        options = [
            ("glass", "Fimbulwinter Glass", "80% opacity with compositor blur; toggleable later.", True),
            ("ollama", "Ollama Vulkan + model benchmark", "Download Qwen 3.5 9B and Gemma 3 candidates, then benchmark.", True),
            ("wol", "Wake-on-LAN", "Enable magic-packet wake only on supported Ethernet adapters.", True),
        ]
        for key, label, description, enabled in options:
            check = Gtk.CheckButton(label=label)
            check.set_active(enabled)
            check.set_tooltip_text(description)
            self.checks[key] = check
            row = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3)
            row.append(check)
            detail = Gtk.Label(label=description)
            detail.set_xalign(0)
            detail.set_margin_start(28)
            detail.add_css_class("dim-label")
            row.append(detail)
            outer.append(row)

        disk = Gtk.Label(
            label="Personal disks are not auto-mounted by default. The existing SATA SSD "
                  "and /mnt/storage are not used by the installer."
        )
        disk.set_wrap(True)
        disk.set_xalign(0)
        disk.add_css_class("dim-label")
        outer.append(disk)

        status = Gtk.Label(label="The complete 5,000-image public gallery must be published before installation can proceed.")
        status.set_wrap(True)
        status.set_xalign(0)
        status.add_css_class("warning")
        outer.append(status)

        buttons = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        buttons.set_halign(Gtk.Align.END)
        outer.append(buttons)

        cancel = Gtk.Button(label="Cancel")
        cancel.connect("clicked", lambda *_: self.quit())
        buttons.append(cancel)

        install = Gtk.Button(label="Install Fenrir")
        install.add_css_class("suggested-action")
        install.connect("clicked", self.start_install)
        buttons.append(install)

        window.present()

    def start_install(self, _button):
        command = ["bash", str(self.installer), "--cli", "--yes"]
        if not self.checks["glass"].get_active():
            command.append("--no-glass")
        if not self.checks["ollama"].get_active():
            command.append("--no-ollama")
        if not self.checks["wol"].get_active():
            command.append("--no-wol")
        subprocess.Popen(command, cwd=self.installer.parent)
        self.quit()


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: gtk_installer.py /path/to/install.sh", file=sys.stderr)
        return 2
    installer = Path(sys.argv[1]).resolve()
    if not installer.is_file():
        print(f"Installer script not found: {installer}", file=sys.stderr)
        return 2
    app = FenrirWizard(installer)
    return app.run([])


if __name__ == "__main__":
    raise SystemExit(main())
