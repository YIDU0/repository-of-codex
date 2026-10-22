#!/usr/bin/env python3
"""Install or verify pinned Linux Android SDK packages without changing HOME."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import tempfile
import urllib.parse
import urllib.request
import zipfile

REPO = Path(__file__).resolve().parents[1]
LOCK = json.loads((REPO / "toolchains.lock.json").read_text())
ROOT = Path(os.environ.get("WORKTIME_TOOLCHAINS", REPO.parent / ".toolchains"))
SDK = Path(os.environ.get("ANDROID_HOME", ROOT / "android-sdk"))


def properties(path):
    return dict(
        line.strip().split("=", 1)
        for line in path.read_text().splitlines()
        if "=" in line and not line.lstrip().startswith("#")
    )


def verify_packages(include_emulator=False):
    expected = dict(LOCK["android"]["packages"])
    if include_emulator:
        expected.update(LOCK["android"]["emulator_packages"])
    expected["cmdline-tools;19.0"] = "19.0"
    for package, revision in expected.items():
        path = SDK.joinpath(*package.split(";"), "source.properties")
        if not path.is_file():
            raise RuntimeError(f"Missing SDK package: {package}")
        actual = {k.strip(): v.strip() for k, v in properties(path).items()}
        if actual.get("Pkg.Revision") != revision:
            raise RuntimeError(
                f"SDK revision mismatch for {package}: "
                f"expected {revision}, found {actual.get('Pkg.Revision')}; "
                "review the official repository and lock before updating"
            )
        print(f"Verified {package}: {revision}", flush=True)


def install_command_line_tools():
    cfg = LOCK["android"]["command_line_tools"]
    destination = SDK / "cmdline-tools" / cfg["version"]
    if destination.exists():
        return destination / "bin" / "sdkmanager"
    cache = ROOT / "downloads"
    cache.mkdir(parents=True, exist_ok=True)
    archive = cache / "android-commandlinetools-19.zip"
    if not archive.exists():
        partial = archive.with_suffix(".part")
        with urllib.request.urlopen(cfg["url"], timeout=120) as response:
            with partial.open("wb") as output:
                while chunk := response.read(1024 * 1024):
                    output.write(chunk)
        partial.rename(archive)
    with archive.open("rb") as source:
        sha1 = hashlib.file_digest(source, "sha1").hexdigest()
    with archive.open("rb") as source:
        sha256 = hashlib.file_digest(source, "sha256").hexdigest()
    if sha1 != cfg["official_sha1"] or sha256 != cfg["verified_sha256"]:
        raise RuntimeError("Android CLI archive checksum mismatch; refusing extraction")
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=destination.parent) as temporary:
        temporary = Path(temporary)
        with zipfile.ZipFile(archive) as source:
            for member in source.namelist():
                if not (temporary / member).resolve().is_relative_to(temporary.resolve()):
                    raise RuntimeError("Unsafe archive member")
            source.extractall(temporary)
        for executable in (temporary / "cmdline-tools" / "bin").iterdir():
            executable.chmod(0o755)
        (temporary / "cmdline-tools").rename(destination)
    return destination / "bin" / "sdkmanager"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify-only", action="store_true")
    parser.add_argument("--with-emulator", action="store_true")
    args = parser.parse_args()
    if platform.system() != "Linux" or platform.machine() != "x86_64":
        parser.error("This installer is pinned for Linux x86_64; use the documented Mac SDK setup")
    if args.verify_only:
        verify_packages(args.with_emulator)
        return
    sdkmanager = install_command_line_tools()
    (ROOT / "logs").mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env["ANDROID_USER_HOME"] = str(ROOT / "android-user")
    (ROOT / "android-user").mkdir(exist_ok=True)
    env["JAVA_TOOL_OPTIONS"] = (
        env.get("JAVA_TOOL_OPTIONS", "")
        + " -Djava.util.prefs.userRoot=" + str(ROOT / "java-prefs")
    ).strip()
    command = [str(sdkmanager), "--sdk_root=" + str(SDK)]
    proxy_url = env.get("HTTPS_PROXY") or env.get("https_proxy")
    if proxy_url:
        proxy = urllib.parse.urlsplit(proxy_url)
        if proxy.scheme != "http" or not proxy.hostname:
            raise RuntimeError("An HTTP SDK proxy is required; keep the platform proxy configured")
        command += ["--proxy=http", "--proxy_host=" + proxy.hostname,
                    "--proxy_port=" + str(proxy.port or 80)]
    packages = dict(LOCK["android"]["packages"])
    if args.with_emulator:
        packages.update(LOCK["android"]["emulator_packages"])
    for name, arguments in [
        ("licenses", ["--licenses"]),
        ("install", list(packages)),
    ]:
        log = ROOT / "logs" / f"android-{name}.log"
        with log.open("w") as output:
            result = subprocess.run(
                command + arguments, input="y\n" * 100, text=True,
                stdout=output, stderr=subprocess.STDOUT, env=env, check=False,
            )
        if result.returncode:
            raise RuntimeError(f"Android {name} failed ({result.returncode}); see {log}")
    verify_packages(args.with_emulator)


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
