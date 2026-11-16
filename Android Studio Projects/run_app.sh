#!/usr/bin/env bash
# Android Dev Portfolio - App Runner (Linux/macOS). Usage: ./run_app.sh [1-10|exnoN]
set -e
cd "$(dirname "$0")"
chmod +x gradlew 2>/dev/null || true

# Find a JDK 17-25 (same finder as setup.sh: JAVA_HOME, PATH, Android Studio's JDK, installed JDKs)
source ./setup.sh --find-java || { echo "[ERROR] No usable Java. Run ./setup.sh (it can download one)."; exit 1; }

CHOICE="${1:-}"
if [ -z "$CHOICE" ]; then
  cat <<'EOF'
Select an exercise app to build and install:
  [1] exno1   [2] exno2   [3] exno3   [4] exno4   [5] exno5
  [6] exno6   [7] exno7   [8] exno8   [9] exno9  [10] exno10
EOF
  read -rp "Enter exercise number (1-10): " CHOICE
fi
[[ "$CHOICE" =~ ^[0-9]+$ ]] && CHOICE="exno$CHOICE"

echo "[*] Building and installing :$CHOICE ..."
./gradlew ":$CHOICE:installDebug"

# Find adb from local.properties (written by gradle/sdk-autodetect.gradle.kts) or PATH
SDK=$(grep -E '^sdk.dir=' local.properties 2>/dev/null | cut -d= -f2- | sed 's/\\:/:/g')
ADB="$SDK/platform-tools/adb"; [ -x "$ADB" ] || ADB=adb
PKG="com.example.$CHOICE"; [ "$CHOICE" = "exno2" ] && PKG="com.example.myapplication"
"$ADB" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 \
  && echo "[SUCCESS] $CHOICE launched." || echo "[!] Installed, but could not auto-launch (is a device connected?)"
