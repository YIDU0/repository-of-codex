#!/usr/bin/env python3
"""Shared Android UI helpers and file-dialog driver for isolated test fixtures."""

import os
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET

ADB = str(Path(os.environ.get("ANDROID_HOME", "/workspace/.toolchains/android-sdk"))
          / "platform-tools/adb")


def adb(*args):
    return subprocess.check_output(
        [ADB, "-s", "emulator-5554", *args], text=True,
        stderr=subprocess.DEVNULL, timeout=45,
    )


def click(node):
    left, top, right, bottom = map(int, re.findall(r"\d+", node.get("bounds", "")))
    if right <= left or bottom <= top:
        raise ValueError("Empty native control bounds")
    adb("shell", "input", "tap", str((left + right) // 2), str((top + bottom) // 2))


def main():
    phase = "save"
    deadline = time.monotonic() + 1200
    while time.monotonic() < deadline:
        try:
            activities = adb("shell", "dumpsys", "activity", "activities")
            top = "\n".join(line for line in activities.splitlines()
                            if "ResumedActivity" in line)
            if "documentsui" not in top:
                time.sleep(2)
                continue
            adb("shell", "uiautomator", "dump", "/sdcard/worktime-dialog.xml")
            root = ET.fromstring(adb("shell", "cat", "/sdcard/worktime-dialog.xml"))
            nodes = [n for n in root.iter("node") if n.get("enabled") == "true"]
            replacements = [n for n in nodes
                            if n.get("text", "").casefold() in {"replace", "overwrite", "替换", "覆盖"}]
            if replacements:
                click(replacements[0])
                time.sleep(2)
                continue
            save = [n for n in nodes if n.get("text", "").casefold() in {"save", "保存"}
                    and n.get("class", "").endswith("Button")]
            if phase == "save" and save:
                click(save[0])
                print("Native save dialog: confirmed", flush=True)
                phase = "open"
            elif phase == "open" and not save:
                files = [n for n in nodes
                         if n.get("text") == "worktime-platform-probe.json"
                         and "EditText" not in n.get("class", "")]
                if files:
                    click(files[0])
                    print("Native open dialog: selected exported JSON", flush=True)
                    return
                # A fresh device can open in Recents before the provider has
                # indexed the newly created document. Navigate to Downloads.
                downloads = [n for n in nodes if n.get("text", "").casefold()
                             in {"downloads", "下载"}]
                roots = [n for n in nodes if n.get("content-desc", "").casefold()
                         in {"show roots", "show navigation menu", "显示根目录"}]
                if downloads:
                    click(downloads[0])
                elif roots:
                    click(roots[0])
            time.sleep(2)
        except (subprocess.SubprocessError, ValueError, ET.ParseError):
            time.sleep(2)
    raise SystemExit("Native file dialog automation timed out; no success is assumed")


if __name__ == "__main__":
    main()
