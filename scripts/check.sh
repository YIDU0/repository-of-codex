#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname -- "${BASH_SOURCE[0]}")/.."
source scripts/env.sh
if [[ $# -gt 1 || ( $# -eq 1 && "$1" != --android ) ]]; then
  echo 'Usage: bash scripts/check.sh [--android]' >&2
  exit 2
fi
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze --fatal-infos
flutter test --reporter expanded
if [[ "${1:-}" == --android ]]; then
  flock "$WORKTIME_TOOLCHAINS/android-build.lock" flutter build apk --debug
fi
