#!/usr/bin/env python3
"""Verify the pinned Flutter source, then bootstrap only through official routes."""

import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import urllib.error
import urllib.request

REPO = Path(__file__).resolve().parents[1]
CONFIG = json.loads((REPO / "toolchains.lock.json").read_text())["flutter"]
ROOT = Path(os.environ.get("WORKTIME_TOOLCHAINS", REPO.parent / ".toolchains"))
FLUTTER = ROOT / "flutter"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-only", action="store_true")
    args = parser.parse_args()
    if (REPO / ".flutter-version").read_text().strip() != CONFIG["version"]:
        raise RuntimeError("Flutter version files disagree")
    ROOT.mkdir(parents=True, exist_ok=True)
    if not FLUTTER.exists():
        subprocess.run([
            "git", "clone", "--depth", "1", "--branch", CONFIG["version"],
            CONFIG["repository"], str(FLUTTER),
        ], check=True)
    commit = subprocess.check_output(
        ["git", "-C", str(FLUTTER), "rev-parse", "HEAD"], text=True,
    ).strip()
    if commit != CONFIG["commit"]:
        raise RuntimeError("Existing Flutter checkout differs from lock; refusing reset")
    print(f"Verified Flutter {CONFIG['version']} source: {commit}", flush=True)
    if args.source_only:
        return
    # The release-list object is not a prerequisite of Flutter's source install.
    # Follow the engine revision in the verified source, as update_dart_sdk.sh does.
    engine = (FLUTTER / "bin/internal/engine.version").read_text().strip()
    if len(engine) != 40 or any(c not in "0123456789abcdef" for c in engine):
        raise RuntimeError("Invalid engine revision in pinned Flutter source")
    artifact_url = (
        "https://storage.googleapis.com/flutter_infra_release/flutter/"
        + engine + "/dart-sdk-linux-x64.zip"
    )
    try:
        request = urllib.request.Request(artifact_url, method="HEAD")
        with urllib.request.urlopen(request, timeout=30) as response:
            if response.status != 200:
                raise RuntimeError("Flutter engine artifact is unavailable")
    except urllib.error.URLError as error:
        raise RuntimeError(
            "Flutter official artifact access failed: " + str(error)
            + ". Required host: storage.googleapis.com. "
            "Check the response and network setting before retrying; keep TLS verification enabled."
        ) from error
    subprocess.run([str(FLUTTER / "bin/flutter"), "--disable-analytics"], check=True)
    subprocess.run([str(FLUTTER / "bin/flutter"), "--version"], check=True)
    subprocess.run([str(FLUTTER / "bin/flutter"), "precache", "--android"], check=True)


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
