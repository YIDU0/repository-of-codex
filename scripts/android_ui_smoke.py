#!/usr/bin/env python3
"""Check actual app UI and platform operations on the owned Android emulator."""

import json
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET

import native_dialog_driver as ui

PACKAGE = "dev.worktime.worktime_journal"
ARTIFACTS = Path("artifacts")
RESULTS = []


def snapshot():
    ui.adb("shell", "uiautomator", "dump", "/sdcard/worktime-ui.xml")
    content = ui.adb("shell", "cat", "/sdcard/worktime-ui.xml")
    (ARTIFACTS / "last-ui.xml").write_text(content)
    return ET.fromstring(content)


def labels(root):
    return "\n".join(
        n.get("text", "") + " " + n.get("content-desc", "")
        for n in root.iter("node")
    )


def nodes_named(root, text):
    return [n for n in root.iter("node")
            if n.get("enabled") == "true"
            and any(text in value.splitlines()
                    for value in [n.get("text", ""), n.get("content-desc", "")])]


def wait_for(text, timeout=120):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            root = snapshot()
            current = labels(root)
            if "验证失败：" in current:
                raise RuntimeError("App reported a platform-probe error: " + current[:900])
            if text in current:
                return root
        except (subprocess.SubprocessError, ET.ParseError):
            pass
        time.sleep(2)
    raise RuntimeError("Expected app UI did not appear: " + text)


def tap(text):
    for attempt in range(12):
        root = snapshot()
        for node in nodes_named(root, text):
            try:
                ui.click(node)
                return
            except ValueError:
                pass
        if attempt > 3:
            ui.adb("shell", "input", "swipe", "240", "670", "240", "260", "400")
        time.sleep(2)
    raise RuntimeError("Control not found: " + text)


def start_app():
    ui.adb("shell", "am", "start", "-n", PACKAGE + "/.MainActivity")
    wait_for("工时手账")


def save_dialog():
    root = wait_for("worktime-platform-probe.json")
    # Save to a known local provider root, then re-open the same file.
    roots = [n for n in root.iter("node")
             if n.get("content-desc", "").casefold() in {"show roots", "show navigation menu"}]
    if roots:
        ui.click(roots[0])
        root = wait_for("Downloads")
        downloads = nodes_named(root, "Downloads")
        if downloads:
            ui.click(downloads[0])
    deadline = time.monotonic() + 90
    while time.monotonic() < deadline:
        root = snapshot()
        for node in root.iter("node"):
            if (node.get("enabled") == "true"
                    and node.get("text", "").casefold() in {"save", "保存"}
                    and node.get("class", "").endswith("Button")):
                ui.click(node)
                time.sleep(2)
                current = snapshot()
                replacements = [n for n in current.iter("node")
                                if n.get("text", "").casefold() in {"replace", "overwrite", "替换"}]
                if replacements:
                    ui.click(replacements[0])
                wait_for("系统文件保存成功。")
                return
        time.sleep(2)
    raise RuntimeError("System save dialog could not be confirmed")


def open_dialog():
    deadline = time.monotonic() + 120
    while time.monotonic() < deadline:
        root = snapshot()
        matches = nodes_named(root, "worktime-platform-probe.json")
        if matches:
            ui.click(matches[0])
            return
        downloads = nodes_named(root, "Downloads")
        roots = [n for n in root.iter("node")
                 if n.get("content-desc", "").casefold() in {"show roots", "show navigation menu"}]
        if downloads:
            ui.click(downloads[0])
        elif roots:
            ui.click(roots[0])
        time.sleep(2)
    raise RuntimeError("Exported file did not appear in the system open dialog")


def passed(name):
    RESULTS.append({"check": name, "status": "passed"})
    print("PASS:", name, flush=True)


def main():
    start_app()
    tap("月历")
    wait_for("把努力留在日历里")
    tap("首页")
    tap("开发版平台验证")
    wait_for("平台验证（开发版）")
    passed("app startup and navigation")

    tap("写入并读取 SQLite")
    root = wait_for("SQLite 写入及回读成功：")
    match = re.search(r"SQLite 写入及回读成功：(\d+) 次", labels(root))
    if not match:
        raise RuntimeError("Missing actual SQLite counter result")
    counter = int(match.group(1))
    ui.adb("shell", "am", "force-stop", PACKAGE)
    start_app()
    tap("开发版平台验证")
    tap("只读取已保存数据")
    wait_for(f"已持久保存的次数：{counter}")
    passed("SQLite persists across app process restart")

    tap("验证本地文件往返")
    wait_for(f"本地 JSON 写入及回读成功：{counter}")
    passed("local JSON file round trip")

    tap("打开系统保存对话框")
    save_dialog()
    tap("选择验证文件并读取")
    open_dialog()
    wait_for(f"系统文件选择及读取成功：{counter}")
    passed("native save/open dialogs preserve exported content")

    tap("请求通知权限并安排验证提醒")
    deadline = time.monotonic() + 120
    while time.monotonic() < deadline:
        root = snapshot()
        current = labels(root)
        if "通知未授权" in current or "验证失败：" in current:
            raise RuntimeError("Notification permission or scheduling failed")
        allow = [n for n in root.iter("node")
                 if n.get("text", "").casefold() in {"allow", "允许"}]
        if allow:
            ui.click(allow[0])
        if "待处理验证通知：true" in current:
            break
        time.sleep(2)
    else:
        raise RuntimeError("Scheduled notification was not confirmed as pending")
    tap("取消验证提醒并查询")
    wait_for("取消后待处理验证通知：false")
    passed("permission, notification queue and cancellation")
    ui.adb("shell", "input", "keyevent", "4")
    wait_for("工时手账")


if __name__ == "__main__":
    ARTIFACTS.mkdir(exist_ok=True)
    failure = None
    try:
        main()
    except Exception as error:
        failure = str(error)
        raise
    finally:
        report = {"mode": "profile-software-emulator", "checks": RESULTS, "failure": failure}
        (ARTIFACTS / "android-ui-smoke.json").write_text(
            json.dumps(report, ensure_ascii=False, indent=2) + "\n",
        )
        try:
            image = subprocess.check_output(
                [ui.ADB, "-s", "emulator-5554", "exec-out", "screencap", "-p"], timeout=30,
            )
            (ARTIFACTS / "stage1-screen.png").write_bytes(image)
        except subprocess.SubprocessError:
            pass
