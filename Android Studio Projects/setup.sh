#!/usr/bin/env bash
# One-time setup / environment doctor for Linux & macOS.
# Finds Java + Android SDK, accepts SDK licenses, installs missing SDK parts, then builds all apps.
# Usage: ./setup.sh            (check + build all)
#        ./setup.sh --check    (only check, no build)
cd "$(dirname "$0")"
chmod +x gradlew run_app.sh exno*/gradlew 2>/dev/null
ok()   { echo "  [OK]   $*"; }
warn() { echo "  [WARN] $*"; }
fail() { echo "  [FAIL] $*"; FAILED=1; }
FAILED=0
echo "=== Android Dev Portfolio - setup check ==="

# ---------- 1. Java (Gradle 9 needs JDK 17+) ----------
java_major() { "$1" -version 2>&1 | head -1 | sed -E 's/.*version "(1\.)?([0-9]+).*/\2/'; }
JAVA_BIN=""
[ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ] && JAVA_BIN="$JAVA_HOME/bin/java"
[ -z "$JAVA_BIN" ] && command -v java >/dev/null && JAVA_BIN=$(command -v java)
if [ -z "$JAVA_BIN" ] || [ "$(java_major "$JAVA_BIN")" -lt 17 ] 2>/dev/null; then
  for j in "$HOME"/Apps/AndroidStudio/jbr /opt/android-studio/jbr "$HOME"/android-studio/jbr \
           /snap/android-studio/current/jbr /usr/local/android-studio/jbr \
           "/Applications/Android Studio.app/Contents/jbr/Contents/Home"; do
    if [ -x "$j/bin/java" ]; then export JAVA_HOME="$j"; JAVA_BIN="$j/bin/java"; break; fi
  done
fi
if [ -n "$JAVA_BIN" ] && [ "$(java_major "$JAVA_BIN")" -ge 17 ] 2>/dev/null; then
  ok "Java $(java_major "$JAVA_BIN")  ($JAVA_BIN)"
else
  fail "JDK 17+ not found. Install Android Studio (it bundles one) or a JDK 17/21, or set JAVA_HOME."
fi

# ---------- 2. Android SDK ----------
SDK=""
for c in "$ANDROID_HOME" "$ANDROID_SDK_ROOT" \
         "$(grep -E '^sdk.dir=' local.properties 2>/dev/null | cut -d= -f2- | sed 's/\\:/:/g')" \
         "$HOME/Android/Sdk" "$HOME/Library/Android/sdk" "$HOME/Apps/sdk-android" /opt/android-sdk /usr/lib/android-sdk; do
  if [ -n "$c" ] && { [ -d "$c/platforms" ] || [ -d "$c/platform-tools" ]; }; then SDK="$c"; break; fi
done
if [ -n "$SDK" ]; then
  ok "Android SDK  ($SDK)"
  printf 'sdk.dir=%s\n' "$SDK" > local.properties
else
  fail "Android SDK not found. Open Android Studio once (it installs the SDK), or set ANDROID_HOME."
fi

# ---------- 3. Licenses + required SDK packages ----------
if [ -n "$SDK" ]; then
  SDKMANAGER=$(ls "$SDK"/cmdline-tools/latest/bin/sdkmanager "$SDK"/cmdline-tools/*/bin/sdkmanager "$SDK"/tools/bin/sdkmanager 2>/dev/null | head -1)
  NEED=()
  [ -d "$SDK/platforms/android-34" ] || NEED+=("platforms;android-34")
  ls -d "$SDK"/build-tools/3[4-9]* >/dev/null 2>&1 || NEED+=("build-tools;34.0.0")
  [ -d "$SDK/platform-tools" ] || NEED+=("platform-tools")
  if [ -n "$SDKMANAGER" ]; then
    yes | "$SDKMANAGER" --licenses >/dev/null 2>&1 && ok "SDK licenses accepted"
    if [ ${#NEED[@]} -gt 0 ]; then
      echo "  [..]   Installing: ${NEED[*]}"
      "$SDKMANAGER" "${NEED[@]}" && ok "SDK packages installed" || fail "sdkmanager could not install ${NEED[*]}"
    else
      ok "SDK platform 34, build-tools, platform-tools present"
    fi
  elif [ ${#NEED[@]} -gt 0 ]; then
    warn "Missing ${NEED[*]} and no sdkmanager. Gradle will try to auto-download; if it fails, install them via Android Studio > SDK Manager."
  else
    ok "SDK platform 34, build-tools, platform-tools present"
  fi
fi

# ---------- 4. Device (optional) ----------
ADB="$SDK/platform-tools/adb"; [ -x "$ADB" ] || ADB=$(command -v adb)
if [ -n "$ADB" ] && "$ADB" devices 2>/dev/null | grep -qw device$; then ok "Device/emulator connected"
else warn "No device/emulator connected (only needed for run_app.sh / Run button)"; fi

[ "$FAILED" = 1 ] && { echo; echo "Fix the [FAIL] items above, then re-run ./setup.sh"; exit 1; }
[ "$1" = "--check" ] && { echo; echo "All checks passed."; exit 0; }

# ---------- 5. Build everything ----------
echo; echo "=== Building all 10 apps (first run downloads Gradle + libraries, needs internet) ==="
./gradlew assembleDebug && {
  echo; echo "SUCCESS. APKs: exnoN/app/build/outputs/apk/debug/"
  echo "Install + launch one with:  ./run_app.sh 3"
}
