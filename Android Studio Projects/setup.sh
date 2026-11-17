#!/usr/bin/env bash
# One-time setup / environment doctor for Linux & macOS.
# Finds Java + Android SDK, accepts SDK licenses, installs missing SDK parts, then builds all apps.
# Usage: ./setup.sh               check + build all
#        ./setup.sh --check       only check, no build
#        source ./setup.sh --find-java   (used by run_app.sh) only find Java and export JAVA_HOME

# ============================ Java finder ===================================
# Gradle 9 runs on JDK 17-25. Search order: JAVA_HOME -> java on PATH -> macOS java_home
# -> Android Studio's bundled JDK (normal / Toolbox / snap / flatpak) -> installed JDKs
# (/usr/lib/jvm, ~/.jdks, SDKMAN, Homebrew, asdf, mise, Gradle/IntelliJ downloads).
# If nothing usable exists, setup offers to download a portable JDK 21 into ~/.jdks.
FJ_MIN=17
FJ_MAX=25
FJ_FOUND=""; FJ_FOUNDV=""; FJ_SRC=""; FJ_SKIPPED=""

# Major version of a JDK home: read its 'release' file (fast, no quoting issues),
# fall back to running java -version.
fj_version() {
  local h="$1" v=""
  [ -f "$h/release" ] && v=$(sed -n 's/^JAVA_VERSION="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' "$h/release" | head -1)
  [ -z "$v" ] && v=$("$h/bin/java" -version 2>&1 | sed -n 's/.* version "\([^"]*\)".*/\1/p' | head -1)
  v=${v#1.}                    # 1.8.0_292 -> 8.0_292
  v=${v%%[.+_-]*}              # 17.0.2 -> 17
  case "$v" in ''|*[!0-9]*) echo 0 ;; *) echo "$v" ;; esac
}

fj_try() {  # $1 = candidate JDK home, $2 = where it came from
  [ -n "$FJ_FOUND" ] && return 0
  local h="${1%/}"
  [ -n "$h" ] && [ -x "$h/bin/java" ] || return 1
  case "$h" in */Contents) [ -d "$h/Home" ] && h="$h/Home" ;; esac
  local v; v=$(fj_version "$h")
  if [ "$v" -ge "$FJ_MIN" ] && [ "$v" -le "$FJ_MAX" ]; then
    FJ_FOUND="$h"; FJ_FOUNDV="$v"; FJ_SRC="$2"; return 0
  fi
  FJ_SKIPPED="$FJ_SKIPPED
      Java $v (not usable): $h"
  return 1
}

fj_try_glob() {  # $1 = label, rest = glob patterns of JDK homes
  local label="$1" d; shift
  for d in "$@"; do [ -d "$d" ] && fj_try "$d" "$label"; done
}

fj_search() {
  # 1. JAVA_HOME and java on PATH
  [ -n "$JAVA_HOME" ] && fj_try "$JAVA_HOME" "JAVA_HOME"
  if command -v java >/dev/null 2>&1; then
    local j; j=$(readlink -f "$(command -v java)" 2>/dev/null || command -v java)
    fj_try "$(dirname "$(dirname "$j")")" "PATH"
  fi
  # 2. macOS: the system JDK registry
  if [ -x /usr/libexec/java_home ]; then
    fj_try "$(/usr/libexec/java_home -v 21 2>/dev/null)" "java_home"
    fj_try "$(/usr/libexec/java_home -v 17 2>/dev/null)" "java_home"
    fj_try "$(/usr/libexec/java_home 2>/dev/null)" "java_home"
  fi
  # 3. Android Studio bundled JDK (normal installs, JetBrains Toolbox, snap)
  shopt -s nullglob
  fj_try_glob "Android Studio" \
    "/Applications/Android Studio"*.app/Contents/jbr/Contents/Home \
    "$HOME/Applications/Android Studio"*.app/Contents/jbr/Contents/Home \
    "$HOME/Applications/JetBrains Toolbox/Android Studio"*.app/Contents/jbr/Contents/Home \
    "$HOME/Library/Application Support/JetBrains/Toolbox/apps/AndroidStudio/"*/*/"Android Studio"*.app/Contents/jbr/Contents/Home \
    /opt/android-studio*/jbr /usr/local/android-studio*/jbr "$HOME"/android-studio*/jbr \
    "$HOME"/Apps/AndroidStudio*/jbr "$HOME"/Applications/android-studio*/jbr \
    "$HOME"/.local/share/JetBrains/Toolbox/apps/android-studio*/jbr \
    "$HOME"/.local/share/JetBrains/Toolbox/apps/AndroidStudio/ch-*/*/jbr \
    /snap/android-studio/current/jbr /snap/android-studio/current/android-studio/jbr \
    /var/lib/flatpak/app/com.google.AndroidStudio/current/active/files/extra/android-studio/jbr
  # 4. Installed JDKs (distro packages, SDKMAN, Homebrew, IntelliJ/Gradle downloads, asdf, mise)
  fj_try_glob "installed JDK" \
    /usr/lib/jvm/* /usr/java/* /opt/java/* /opt/jdk* /opt/*jdk* \
    "$HOME"/.jdks/* "$HOME"/.jdks/*/Contents/Home "$HOME"/.gradle/jdks/* "$HOME"/.gradle/jdks/*/Contents/Home \
    "$HOME"/.sdkman/candidates/java/* "$HOME"/.asdf/installs/java/* "$HOME"/.local/share/mise/installs/java/* \
    /Library/Java/JavaVirtualMachines/*/Contents/Home "$HOME"/Library/Java/JavaVirtualMachines/*/Contents/Home \
    /opt/homebrew/opt/openjdk*/libexec/openjdk.jdk/Contents/Home /usr/local/opt/openjdk*/libexec/openjdk.jdk/Contents/Home \
    /home/linuxbrew/.linuxbrew/opt/openjdk*/libexec \
    "$HOME"/Apps/Java "$HOME"/Apps/jdk*
  shopt -u nullglob
}

fj_download() {
  local os arch url dest tgz
  case "$(uname -s)" in Darwin) os=mac ;; Linux) os=linux ;; *) echo "  [java] Auto-download not supported on $(uname -s)"; return 1 ;; esac
  case "$(uname -m)" in x86_64|amd64) arch=x64 ;; arm64|aarch64) arch=aarch64 ;; *) echo "  [java] Unsupported CPU $(uname -m)"; return 1 ;; esac
  url="https://api.adoptium.net/v3/binary/latest/21/ga/$os/$arch/jdk/hotspot/normal/eclipse"
  dest="$HOME/.jdks"; tgz="${TMPDIR:-/tmp}/temurin21-$$.tar.gz"
  echo "  [java] Downloading portable JDK 21 (Eclipse Temurin, ~200 MB) into $dest ..."
  mkdir -p "$dest" || return 1
  if command -v curl >/dev/null; then curl -fL --retry 3 -o "$tgz" "$url"
  elif command -v wget >/dev/null; then wget -O "$tgz" "$url"
  else echo "  [java] Need curl or wget to download"; return 1; fi || { rm -f "$tgz"; return 1; }
  tar -xzf "$tgz" -C "$dest" && rm -f "$tgz" || return 1
  shopt -s nullglob; fj_try_glob "downloaded" "$dest"/jdk-21* "$dest"/jdk-21*/Contents/Home; shopt -u nullglob
}

# Search, optionally download ($1 = --download), then export JAVA_HOME + JAVA_MAJOR.
find_java() {
  FJ_FOUND=""; FJ_FOUNDV=""; FJ_SRC=""; FJ_SKIPPED=""
  fj_search
  if [ -z "$FJ_FOUND" ] && [ "$1" = "--download" ]; then fj_download; fi
  if [ -n "$FJ_FOUND" ]; then
    export JAVA_HOME="$FJ_FOUND" JAVA_MAJOR="$FJ_FOUNDV"
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "  [java] Java $JAVA_MAJOR from $FJ_SRC: $JAVA_HOME"
    [ -n "$FJ_SKIPPED" ] && echo "  [java] Skipped:$FJ_SKIPPED"
    return 0
  fi
  echo "  [java] No JDK $FJ_MIN-$FJ_MAX found.${FJ_SKIPPED:+ Found but not usable:$FJ_SKIPPED}"
  return 1
}

if [ "$1" = "--find-java" ]; then find_java; return $? 2>/dev/null || exit $?; fi

# ============================ Setup =========================================
cd "$(dirname "$0")"
chmod +x gradlew run_app.sh exno*/gradlew up_ex*/gradlew 2>/dev/null
ok()   { echo "  [OK]   $*"; }
warn() { echo "  [WARN] $*"; }
fail() { echo "  [FAIL] $*"; FAILED=1; }
FAILED=0
echo "=== Android Dev Portfolio - setup check ==="

# ---------- 1. Java (Gradle 9 runs on JDK 17-25) ----------
if find_java; then
  ok "Java $JAVA_MAJOR  ($JAVA_HOME)"
else
  a=y; [ -t 0 ] && read -rp "  Download a portable JDK 21 (~200 MB) into ~/.jdks now? [Y/n] " a
  case "$a" in
    [nN]*) fail "No JDK 17-25. Install Android Studio (it bundles one) or a JDK 17/21, or set JAVA_HOME." ;;
    *) if find_java --download; then ok "Java $JAVA_MAJOR  ($JAVA_HOME)"; else fail "JDK download failed - check internet, or install a JDK 17/21."; fi ;;
  esac
fi

# ---------- 2. Android SDK ----------
# Detected by gradle/sdk-autodetect.gradle.kts - the same logic Android Studio sync uses
# (local.properties, ANDROID_HOME, Android Studio's saved SDK path, default folders).
sdk_from_props() { grep -E '^sdk.dir=' local.properties 2>/dev/null | cut -d= -f2- | sed 's/\\:/:/g'; }
is_sdk() { [ -n "$1" ] && { [ -d "$1/platforms" ] || [ -d "$1/platform-tools" ]; }; }
SDK=$(sdk_from_props)
if ! is_sdk "$SDK" && [ "$FAILED" = 0 ]; then
  echo "  [..]   Detecting Android SDK (first run downloads Gradle - needs internet) ..."
  ./gradlew -q help >/dev/null 2>&1
  SDK=$(sdk_from_props)
fi
if is_sdk "$SDK"; then
  ok "Android SDK  ($SDK)"
else
  SDK=""
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
  echo; echo "SUCCESS. APKs: exnoN/app and up_exN/app/build/outputs/apk/debug/"
  echo "Install + launch one with:  ./run_app.sh 3"
}
