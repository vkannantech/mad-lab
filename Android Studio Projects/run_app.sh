#!/usr/bin/env bash
# Android Dev Portfolio - App Runner (Linux/macOS). Usage: ./run_app.sh [1-10|exnoN]
set -e
cd "$(dirname "$0")"
chmod +x gradlew 2>/dev/null || true

# Gradle 9 needs JDK 17+. If system java is missing/too old, fall back to Android Studio's bundled JBR.
java_major() { "$1" -version 2>&1 | head -1 | sed -E 's/.*version "([0-9]+).*/\1/'; }
if [ -z "$JAVA_HOME" ] && { ! command -v java >/dev/null || [ "$(java_major java)" -lt 17 ] 2>/dev/null; }; then
  for j in "$HOME"/Apps/AndroidStudio/jbr /opt/android-studio/jbr "$HOME"/android-studio/jbr \
           /snap/android-studio/current/jbr "/Applications/Android Studio.app/Contents/jbr/Contents/Home"; do
    [ -x "$j/bin/java" ] && export JAVA_HOME="$j" && echo "[*] Using JDK: $j" && break
  done
fi

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
