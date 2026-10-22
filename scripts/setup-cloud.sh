#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname -- "${BASH_SOURCE[0]}")/.."
source scripts/env.sh
python3 scripts/bootstrap_android.py --with-emulator
python3 scripts/bootstrap_flutter.py
bash scripts/cloud-container.sh build
bash scripts/cloud-container.sh flutter pub get --enforce-lockfile
