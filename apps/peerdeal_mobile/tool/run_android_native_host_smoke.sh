#!/usr/bin/env bash
set -euo pipefail

apk="${1:-build/app/outputs/flutter-apk/app-debug.apk}"
timeout_seconds="${PEERDEAL_ANDROID_SMOKE_TIMEOUT_SECONDS:-180}"

if [[ ! -f "$apk" ]]; then
  echo "Android native host smoke APK was not found: $apk" >&2
  exit 1
fi

if ! [[ "$timeout_seconds" =~ ^[1-9][0-9]*$ ]]; then
  echo "PEERDEAL_ANDROID_SMOKE_TIMEOUT_SECONDS must be a positive integer." >&2
  exit 1
fi

adb wait-for-device
adb install -r "$apk"
adb logcat -c
adb shell am force-stop com.peerdeal.peerdeal_mobile
adb shell monkey -p com.peerdeal.peerdeal_mobile 1 >/dev/null

for ((attempt = 1; attempt <= timeout_seconds; attempt++)); do
  log="$(adb logcat -d -v brief)"
  if grep -Fq 'PEERDEAL_NATIVE_HOST_SMOKE_PASS' <<<"$log"; then
    grep -F 'PEERDEAL_NATIVE_HOST_SMOKE_' <<<"$log"
    exit 0
  fi
  if grep -Fq 'PEERDEAL_NATIVE_HOST_SMOKE_FAIL' <<<"$log"; then
    printf '%s\n' "$log"
    exit 1
  fi
  sleep 1
done

adb logcat -d -v brief
echo "Android native host smoke timed out after $timeout_seconds seconds." >&2
exit 1
