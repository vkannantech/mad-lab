# Android Dev Portfolio — MAD Lab (10 Apps)

Ten Android lab exercises (Java, XML layouts) in **one Gradle project**.
Open it once in Android Studio, pick an app from the Run dropdown, press ▶.

Works on **Windows, macOS and Linux**. The SDK path and Java version are detected for you, so you don't have to edit any paths.

---

## Quick start (30 seconds)

### Option A — Android Studio (recommended)
1. Install **[Android Studio](https://developer.android.com/studio)** (Narwhal 2025.1.3 or newer). It includes Java and the Android SDK.
2. **File → Open** → select this folder (`Android Studio Projects`) → **Trust Project**.
3. Wait for **Gradle Sync** to finish. The first time, it downloads about 300 MB, so you need internet.
4. Choose an app (`exno1` … `exno10`) from the run-configuration dropdown → pick an emulator/phone → **▶ Run**.

### Option B — Command line

| | Windows | Linux / macOS |
|---|---|---|
| Check environment + build all | `setup.bat` | `./setup.sh` |
| Only check, no build | `setup.bat --check` | `./setup.sh --check` |
| Build + install + launch one app | `run_app.bat 3` | `./run_app.sh 3` |
| Interactive menu | `run_app.bat` | `./run_app.sh` |
| Build all APKs | `gradlew assembleDebug` | `./gradlew assembleDebug` |
| Build one APK | `gradlew :exno3:assembleDebug` | `./gradlew :exno3:assembleDebug` |

APK output: `exnoN/app/build/outputs/apk/debug/exnoN-debug.apk`

---

## The 10 apps

| Module | Topic | What it does | Package |
|---|---|---|---|
| `exno1`  | GUI components | Change text font size and color with buttons | `com.example.exno1` |
| `exno2`  | Layouts & Intents | Details form (Name, Reg. No, Dept spinner) → shows data in a second activity | `com.example.myapplication` |
| `exno3`  | Graphical primitives | Draws shapes on a `Canvas` (Bitmap + Paint) | `com.example.exno3` |
| `exno4`  | SQLite database | Student records (roll no, name, marks): insert / view / update / delete | `com.example.exno4` |
| `exno5`  | Notifications | Type a message → shows a notification → tap opens a second activity | `com.example.exno5` |
| `exno6`  | Images | Load and switch between two images (BitmapFactory) | `com.example.exno6` |
| `exno7`  | GPS location | Shows current latitude / longitude from GPS | `com.example.exno7` |
| `exno8`  | File storage | Write / read / clear text in a file in app external storage | `com.example.exno8` |
| `exno9`  | Notifications + Fragments | Fragment navigation + notification with runtime permission | `com.example.exno9` |
| `exno10` | Networking / RSS | Fetches an RSS feed in the background (AsyncTask), opens articles in browser | `com.example.exno10` |

Each `exnoN/` folder is **also** a standalone project. You can open `exno3/` on its own in Android Studio, but opening the root folder is simpler.

---

## Requirements (installed automatically where possible)

| Item | Version | How you get it |
|---|---|---|
| JDK | 17, 21 or 25 | Bundled with Android Studio (scripts auto-find it) |
| Gradle | 9.2.1 | Auto-downloaded by `gradlew` (wrapper) |
| Android Gradle Plugin | 8.13.2 | Auto-downloaded |
| Android SDK Platform | 34 (compileSdk / targetSdk) | Android Studio SDK Manager, or `setup` script, or auto-download by Gradle |
| Min Android version | 7.0 (API 24) — exno9 needs 8.1 (API 27) | Any emulator/phone at or above this |

### What makes it "run anywhere"
- **`gradle/sdk-autodetect.gradle.kts`** runs on every sync/build. If `local.properties` is missing, or points to a path that doesn't exist (for example `C:\Users\someone-else\...` copied from another PC), it finds the SDK automatically and rewrites the file. It searches `ANDROID_HOME`, `ANDROID_SDK_ROOT`, and the default SDK locations on Windows, macOS and Linux.
- **Gradle wrapper** is committed, so there's no need to install Gradle.
- **`setup.sh` / `setup.bat`** find Java (falling back to Android Studio's bundled JBR), find the SDK, accept SDK licenses, install `platforms;android-34` / build-tools if missing, then build everything.
- **`local.properties` is git-ignored**, because it is machine-specific.
- **`.gitattributes`** keeps `.bat` files with CRLF line endings and `gradlew`/`.sh` with LF, so the scripts work after cloning on any OS.

---

## Running on a device

**Emulator:** Android Studio → **Device Manager** → **Create Device** → e.g. *Pixel 8, API 34* → ▶.

**Real phone:** Settings → About phone → tap *Build number* 7× → Developer options → enable **USB debugging** → connect USB → allow the prompt.

Permissions the apps ask for at runtime — tap **Allow**:
- `exno5`, `exno9` → Notifications (Android 13+)
- `exno7` → Location. On an emulator, set a location in **⋮ Extended controls → Location** and press *Set location*, otherwise lat/long stay empty.
- `exno10` → needs internet on the device/emulator.

---

## Troubleshooting

| Error | Fix |
|---|---|
| `SDK location not found` | Run `setup.sh` / `setup.bat`, or set `ANDROID_HOME`, or create `local.properties` with `sdk.dir=/path/to/Android/Sdk` (Windows: `sdk.dir=C:/Users/YOU/AppData/Local/Android/Sdk`). |
| `Unsupported class file major version` / build fails right away with only a Java version number (e.g. `25.0.1`) | Gradle is running on the wrong Java. In Android Studio: **Settings → Build, Execution, Deployment → Build Tools → Gradle → Gradle JDK** → choose *jbr-21* / *Embedded JDK* (17+). CLI: set `JAVA_HOME` to a JDK 17–25. |
| `The project is using an incompatible version (AGP 8.13.2)` | Your Android Studio is too old → update to Narwhal 2025.1.3+. |
| `Failed to install the following SDK components ... licences not accepted` | `setup.sh`/`setup.bat` accepts them, or Android Studio → SDK Manager → install *Android 14 (API 34)*. |
| `./gradlew: Permission denied` | `chmod +x gradlew` (the setup script does this). |
| Gradle download times out (slow college Wi-Fi) | Retry; the timeout is already 120 s. Behind a proxy, add to `~/.gradle/gradle.properties`: `systemProp.https.proxyHost=...` and `systemProp.https.proxyPort=...` |
| `No connected devices` | Start an emulator or plug in a phone with USB debugging, then `adb devices`. |
| Sync fails with strange cache errors | **File → Invalidate Caches → Restart**, or delete the `.gradle/` and `build/` folders and sync again. |
| Opened `exnoN/` alone and it can't find `sdk-autodetect` | Clone/copy the **whole** folder — the sub-projects share `gradle/sdk-autodetect.gradle.kts` from the root. |

---

## Project layout

```
Android Studio Projects/
├── settings.gradle.kts         # includes :exno1 … :exno10 (each → exnoN/app)
├── build.gradle.kts            # root plugin declarations
├── gradle/
│   ├── libs.versions.toml      # all library + AGP versions in one place
│   ├── sdk-autodetect.gradle.kts
│   └── wrapper/                # Gradle 9.2.1 wrapper
├── gradlew / gradlew.bat
├── setup.sh / setup.bat        # environment doctor + build all
├── run_app.sh / run_app.bat    # build + install + launch one app
├── .idea/runConfigurations/    # ready-made Run configs exno1 … exno10
└── exno1 … exno10/
    └── app/src/main/           # Java sources, layouts, manifest
```

To change a library version, edit `gradle/libs.versions.toml` (root), then re-sync.
