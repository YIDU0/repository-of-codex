#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname -- "${BASH_SOURCE[0]}")/.."
source scripts/env.sh
mkdir -p artifacts
exec 8>"$WORKTIME_TOOLCHAINS/android-avd-session.lock"
if ! flock -n 8; then
  echo 'Another owned emulator session is active.' >&2
  exit 1
fi
if [[ ! -f "$ANDROID_AVD_HOME/worktime_api36_aosp.ini" ]]; then
  printf 'no\n' | avdmanager create avd --name worktime_api36_aosp \
    --package 'system-images;android-36;default;x86_64' --device pixel_2
fi
# A previous container can leave a PID-only lock whose numeric PID is recycled
# in a fresh namespace. The session lease above serializes our owned AVD.
_worktime_avd_lock="$ANDROID_AVD_HOME/worktime_api36_aosp.avd/hardware-qemu.ini.lock"
if [[ -f "$_worktime_avd_lock" ]]; then
  _worktime_old_pid="$(tr -d '\000' < "$_worktime_avd_lock")"
  if [[ "$_worktime_old_pid" =~ ^[0-9]+$ && -f "/proc/$_worktime_old_pid/comm" ]] \
      && grep -Eq 'qemu|emulator' "/proc/$_worktime_old_pid/comm"; then
    echo 'The owned AVD still has an active emulator process.' >&2
    exit 1
  fi
  rm -- "$_worktime_avd_lock"
fi
"$ANDROID_HOME/emulator/emulator" -avd worktime_api36_aosp \
  -no-window -no-audio -no-boot-anim -no-snapshot -no-accel \
  -gpu swiftshader -memory 2048 -cores 1 -skin 480x800 -dpi-device 160 \
  -port 5554 -show-kernel \
  >artifacts/emulator.log 2>&1 &
_worktime_emulator_pid=$!
_worktime_cleanup() {
  timeout 10 adb -s emulator-5554 emu kill >/dev/null 2>&1 || true
  kill "$_worktime_emulator_pid" 2>/dev/null || true
  for _worktime_stop_attempt in {1..30}; do
    kill -0 "$_worktime_emulator_pid" 2>/dev/null || break
    sleep 1
  done
  kill -KILL "$_worktime_emulator_pid" 2>/dev/null || true
  wait "$_worktime_emulator_pid" 2>/dev/null || true
}
trap '_worktime_result=$?; _worktime_cleanup; exit "$_worktime_result"' EXIT
adb start-server
_worktime_deadline=$((SECONDS + 900))
_worktime_watchdog_set=false
while [[ "$(timeout 10 adb -s emulator-5554 shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != 1 ]]; do
  if ! kill -0 "$_worktime_emulator_pid" 2>/dev/null; then
    tail -40 artifacts/emulator.log >&2
    exit 1
  fi
  if (( SECONDS > _worktime_deadline )); then
    echo 'Android emulator boot timed out; see artifacts/emulator.log' >&2
    exit 1
  fi
  if [[ "$_worktime_watchdog_set" == false ]]; then
    timeout 10 adb -s emulator-5554 shell settings put global watchdog_timeout_millis 300000 >/dev/null 2>&1 || true
    if [[ "$(timeout 10 adb -s emulator-5554 shell settings get global watchdog_timeout_millis 2>/dev/null | tr -d '\r')" == 300000 ]]; then
      _worktime_watchdog_set=true
      echo 'Software emulator Watchdog timeout: 300000 ms (Android supported setting)'
    fi
  fi
  sleep 2
done
adb -s emulator-5554 shell settings put global window_animation_scale 0
adb -s emulator-5554 shell settings put global transition_animation_scale 0
adb -s emulator-5554 shell settings put global animator_duration_scale 0
adb -s emulator-5554 shell wm density 160
adb -s emulator-5554 shell wm dismiss-keyguard
adb -s emulator-5554 shell input keyevent 82
(
  flock 9
  if [[ "${1:-}" == --profile-smoke ]]; then
    adb -s emulator-5554 install --no-streaming -r -t artifacts/worktime-journal-stage1-x64-profile.apk
    python3 scripts/android_ui_smoke.py
    exit
  fi
  python3 scripts/native_dialog_driver.py >artifacts/native-dialog-driver.log 2>&1 &
  _worktime_dialog_driver_pid=$!
  trap 'kill "$_worktime_dialog_driver_pid" 2>/dev/null || true' EXIT
  flutter test integration_test/platform_probe_test.dart -d emulator-5554 --reporter expanded
  wait "$_worktime_dialog_driver_pid"
) 9>"$WORKTIME_TOOLCHAINS/android-build.lock"
