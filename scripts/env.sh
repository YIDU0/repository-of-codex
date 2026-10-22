#!/usr/bin/env bash
# Source this file. Do not change HOME to work around a platform restriction.
_worktime_repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export WORKTIME_TOOLCHAINS="${WORKTIME_TOOLCHAINS:-$(dirname -- "$_worktime_repo")/.toolchains}"
export FLUTTER_ROOT="$WORKTIME_TOOLCHAINS/flutter"
export ANDROID_HOME="${ANDROID_HOME:-$WORKTIME_TOOLCHAINS/android-sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_USER_HOME="${ANDROID_USER_HOME:-$WORKTIME_TOOLCHAINS/android-user}"
export ANDROID_AVD_HOME="${ANDROID_AVD_HOME:-$ANDROID_USER_HOME/avd}"
export PUB_CACHE="${PUB_CACHE:-$WORKTIME_TOOLCHAINS/pub-cache}"
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$WORKTIME_TOOLCHAINS/gradle}"
export BUILDX_CONFIG="${BUILDX_CONFIG:-$WORKTIME_TOOLCHAINS/buildx}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$WORKTIME_TOOLCHAINS/xdg/config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$WORKTIME_TOOLCHAINS/xdg/cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$WORKTIME_TOOLCHAINS/xdg/data}"
export PATH="$FLUTTER_ROOT/bin:$ANDROID_HOME/cmdline-tools/19.0/bin:$ANDROID_HOME/platform-tools:$PATH"
unset _worktime_repo
