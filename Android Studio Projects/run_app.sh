#!/usr/bin/env bash
# Android Dev Portfolio - App Runner (Linux/macOS). Usage: ./run_app.sh [u3-u10|up_exN|1-10|exnoN]
set -e
cd "$(dirname "$0")"
chmod +x gradlew 2>/dev/null || true

# Find a JDK 17-25 (same finder as setup.sh: JAVA_HOME, PATH, Android Studio's JDK, installed JDKs)
source ./setup.sh --find-java || { echo "[ERROR] No usable Java. Run ./setup.sh (it can download one)."; exit 1; }

CHOICE="${1:-}"
if [ -z "$CHOICE" ]; then
  cat <<'EOF'
Select an exercise app to build and install:
 Updated manual (up_ex):
  [u3] Visiting card            [u7]  Multithreading - load images
  [u4] Graphical primitives     [u8]  Wallpaper changer (30 s)
  [u5] SQLite student database  [u9]  Write/read SD card (external)
  [u6] Notification manager     [u10] Send an email
 Old versions (exno):
  [1] exno1   [2] exno2   [3] exno3   [4] exno4   [5] exno5
  [6] exno6   [7] exno7   [8] exno8   [9] exno9  [10] exno10
EOF
  read -rp "Enter choice (u3-u10 or 1-10): " CHOICE
fi
[[ "$CHOICE" =~ ^[uU]([0-9]+)$ ]] && CHOICE="up_ex${BASH_REMATCH[1]}"
[[ "$CHOICE" =~ ^[0-9]+$ ]] && CHOICE="exno$CHOICE"
[ -f "$CHOICE/app/build.gradle.kts" ] || { echo "[ERROR] Unknown app \"$CHOICE\". Use u3-u10 or 1-10."; exit 1; }

echo "[*] Building and installing :$CHOICE ..."
./gradlew ":$CHOICE:installDebug"

# Find adb from local.properties (written by gradle/sdk-autodetect.gradle.kts) or PATH
SDK=$(grep -E '^sdk.dir=' local.properties 2>/dev/null | cut -d= -f2- | sed 's/\\:/:/g')
ADB="$SDK/platform-tools/adb"; [ -x "$ADB" ] || ADB=adb
PKG="com.example.$CHOICE"; [ "$CHOICE" = "exno2" ] && PKG="com.example.myapplication"
"$ADB" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 \
  && echo "[SUCCESS] $CHOICE launched." || echo "[!] Installed, but could not auto-launch (is a device connected?)"
