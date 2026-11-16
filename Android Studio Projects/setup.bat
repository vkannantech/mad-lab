@echo off
rem One-time setup / environment doctor for Windows.
rem Finds Java + Android SDK, accepts SDK licenses, installs missing SDK parts, then builds all apps.
rem Usage: setup.bat               check + build all
rem        setup.bat --check       only check, no build
rem        setup.bat --find-java   (used by run_app.bat) only find Java and set JAVA_HOME
if /i "%~1"=="--find-java" goto :findjava
setlocal enabledelayedexpansion
cd /d "%~dp0"
set "FAILED=0"
echo === Android Dev Portfolio - setup check ===

rem ---------- 1. Java (Gradle 9 runs on JDK 17-25) - see :findjava at the bottom ----------
set "JAVA_MAJOR="
set "FJ_DOWNLOAD="
call :findjava
if errorlevel 1 (
    echo.
    choice /c YN /n /t 60 /d Y /m "  No usable Java found. Download a portable JDK 21 (~200 MB) now? [Y/N] "
    if !errorlevel! equ 1 (
        set "FJ_DOWNLOAD=1"
        call :findjava
    )
)
if defined JAVA_MAJOR (
    echo   [OK]   Java !JAVA_MAJOR!  ^(!JAVA_HOME!^)
) else (
    echo   [FAIL] No JDK 17-25. Install Android Studio ^(it bundles one^) or a JDK 17/21, or set JAVA_HOME.
    set "FAILED=1"
)

rem ---------- 2. Android SDK ----------
rem Detected by gradle\sdk-autodetect.gradle.kts - the same logic Android Studio sync uses
rem (local.properties, ANDROID_HOME, Android Studio's saved SDK path, registry, default folders).
call :readsdk
if not defined SDK if "%FAILED%"=="0" (
    echo   [..]   Detecting Android SDK ^(first run downloads Gradle - needs internet^) ...
    call gradlew.bat -q help >nul 2>&1
    call :readsdk
)
if defined SDK (
    echo   [OK]   Android SDK  ^(!SDK!^)
) else (
    echo   [FAIL] Android SDK not found. Open Android Studio once ^(it installs the SDK^), or set ANDROID_HOME.
    set "FAILED=1"
)

rem ---------- 3. Licenses + required SDK packages ----------
if defined SDK (
    set "SDKM="
    if exist "!SDK!\cmdline-tools\latest\bin\sdkmanager.bat" set "SDKM=!SDK!\cmdline-tools\latest\bin\sdkmanager.bat"
    if not defined SDKM for /d %%C in ("!SDK!\cmdline-tools\*") do if exist "%%~C\bin\sdkmanager.bat" set "SDKM=%%~C\bin\sdkmanager.bat"
    set "NEED="
    if not exist "!SDK!\platforms\android-34" set "NEED=!NEED! platforms;android-34"
    set "HAVEBT="
    for /d %%B in ("!SDK!\build-tools\*") do set "HAVEBT=1"
    if not defined HAVEBT set "NEED=!NEED! build-tools;34.0.0"
    if not exist "!SDK!\platform-tools\adb.exe" set "NEED=!NEED! platform-tools"
    if defined SDKM (
        call :licenses
        echo   [OK]   SDK licenses accepted
        if defined NEED (
            echo   [..]   Installing:!NEED!
            call "!SDKM!" !NEED!
        ) else (
            echo   [OK]   SDK platform 34, build-tools, platform-tools present
        )
    ) else (
        if defined NEED (
            echo   [WARN] Missing:!NEED! and no sdkmanager. Install via Android Studio ^> SDK Manager if the build fails.
        ) else (
            echo   [OK]   SDK platform 34, build-tools, platform-tools present
        )
    )
)

rem ---------- 4. Device (optional) ----------
set "DEVOK="
if defined SDK if exist "!SDK!\platform-tools\adb.exe" (
    for /f "skip=1 tokens=2" %%s in ('call "!SDK!\platform-tools\adb.exe" devices 2^>nul') do if "%%s"=="device" set "DEVOK=1"
)
if defined DEVOK (
    echo   [OK]   Device/emulator connected
) else (
    echo   [WARN] No device/emulator connected ^(only needed for run_app.bat / Run button^)
)

if "%FAILED%"=="1" (
    echo.
    echo Fix the [FAIL] items above, then run setup.bat again.
    pause
    exit /b 1
)
if /i "%~1"=="--check" (
    echo.
    echo All checks passed.
    exit /b 0
)

rem ---------- 5. Build everything ----------
echo.
echo === Building all 10 apps (first run downloads Gradle + libraries, needs internet) ===
call gradlew.bat assembleDebug
if %ERRORLEVEL% equ 0 (
    echo.
    echo SUCCESS. APKs: exnoN\app\build\outputs\apk\debug\
    echo Install + launch one with:  run_app.bat 3
) else (
    echo.
    echo [ERROR] Build failed. See README.md - Troubleshooting.
)
pause
exit /b 0


rem ---------- :licenses -> answer "y" to every SDK license (runs at top level so %SDKM% expands inside the pipe) ----------
:licenses
(for /l %%i in (1,1,30) do @echo y) | "%SDKM%" --licenses >nul 2>&1
goto :eof

rem ---------- :readsdk -> SDK = sdk.dir from local.properties, if that folder is a real SDK ----------
:readsdk
set "SDK="
if not exist local.properties goto :eof
for /f "usebackq tokens=1,* delims==" %%a in ("local.properties") do (
    if /i "%%a"=="sdk.dir" set "SDK=%%b"
)
if not defined SDK goto :eof
set "SDK=!SDK:\:=:!"
set "SDK=!SDK:\\=\!"
set "SDK=!SDK:/=\!"
if "!SDK:~-1!"=="\" set "SDK=!SDK:~0,-1!"
if exist "!SDK!\platforms\" goto :eof
if exist "!SDK!\platform-tools\" goto :eof
set "SDK="
goto :eof

rem ============================================================================
rem  :findjava - find a JDK that can run Gradle 9 (Java 17-25), set JAVA_HOME
rem  and JAVA_MAJOR for the caller. errorlevel 1 if none found.
rem  If FJ_DOWNLOAD=1 and none found, downloads a portable JDK 21 into %USERPROFILE%\.jdks
rem  Search order: JAVA_HOME (quotes / trailing \ removed), java on PATH,
rem  Android Studio's bundled JDK (registry, normal install, JetBrains Toolbox),
rem  JDK registry entries (Oracle, Temurin, Microsoft, Zulu, Corretto, Liberica, Semeru),
rem  common JDK folders, %USERPROFILE%\.jdks, Gradle/IntelliJ/scoop downloads.
rem ============================================================================
:findjava
setlocal enabledelayedexpansion
set "MINJ=17"
set "MAXJ=25"
set "FOUND="
set "FOUNDV=0"
set "FOUNDSRC="
set "SKIPPED="
set "PF=%ProgramFiles%"
set "PF86=%ProgramFiles(x86)%"
set "PFW=%ProgramW6432%"
if not defined PFW set "PFW=%ProgramFiles%"

rem ---------- 1. JAVA_HOME (quotes and trailing backslash removed) ----------
set "JH="
if defined JAVA_HOME set "JH=!JAVA_HOME:"=!"
if defined JH call :fj_try "!JH!" JAVA_HOME
if defined FOUND goto :fj_done

rem ---------- 2. java.exe on PATH ----------
for /f "delims=" %%J in ('where java.exe 2^>nul') do call :fj_try "%%~dpJ.." PATH
if defined FOUND goto :fj_done

rem ---------- 3. Android Studio bundled JDK ----------
for %%K in ("HKLM\SOFTWARE\Android Studio" "HKCU\SOFTWARE\Android Studio" "HKLM\SOFTWARE\WOW6432Node\Android Studio") do (
    for /f "tokens=2,*" %%a in ('reg query %%K /v Path 2^>nul ^| findstr /i "REG_SZ"') do (
        call :fj_try "%%b\jbr" AndroidStudio
        call :fj_try "%%b\jre" AndroidStudio
    )
)
for /d %%D in ("%PFW%\Android\Android Studio*" "%PF%\Android\Android Studio*" "%PF86%\Android\Android Studio*" "%LOCALAPPDATA%\Programs\Android Studio*" "%LOCALAPPDATA%\Android\Android Studio*" "%USERPROFILE%\Android Studio*" "C:\Android\Android Studio*" "D:\Android\Android Studio*" "C:\Android Studio*" "D:\Android Studio*") do (
    call :fj_try "%%~D\jbr" AndroidStudio
    call :fj_try "%%~D\jre" AndroidStudio
)
for /d %%C in ("%LOCALAPPDATA%\JetBrains\Toolbox\apps\AndroidStudio\ch-*") do (
    for /d %%D in ("%%~C\*") do call :fj_try "%%~D\jbr" AndroidStudio-Toolbox
)
if defined FOUND goto :fj_done

rem ---------- 4. JDK registry entries (any vendor that registers itself) ----------
for %%K in ("HKLM\SOFTWARE\JavaSoft\JDK" "HKLM\SOFTWARE\JavaSoft\Java Development Kit" "HKLM\SOFTWARE\Eclipse Adoptium" "HKLM\SOFTWARE\Eclipse Foundation" "HKLM\SOFTWARE\AdoptOpenJDK" "HKLM\SOFTWARE\Microsoft\JDK" "HKLM\SOFTWARE\Azul Systems\Zulu" "HKLM\SOFTWARE\Amazon Corretto" "HKLM\SOFTWARE\BellSoft\Liberica" "HKLM\SOFTWARE\Semeru" "HKCU\SOFTWARE\Eclipse Adoptium") do (
    for /f "tokens=1,2,*" %%a in ('reg query %%K /s 2^>nul ^| findstr /i /r /c:"JavaHome  *REG_SZ" /c:"Path  *REG_SZ" /c:"InstallationPath  *REG_SZ"') do call :fj_try "%%c" registry
)
if defined FOUND goto :fj_done

rem ---------- 5. Common JDK install folders ----------
for %%B in ("%PFW%" "%PF86%") do (
    for %%V in (Java "Eclipse Adoptium" "Eclipse Foundation" AdoptOpenJDK Microsoft Zulu "Azul Systems\Zulu" "Amazon Corretto" BellSoft "BellSoft\LibericaJDK" Semeru "IBM\Semeru" OpenJDK RedHat ojdkbuild) do (
        for /d %%D in ("%%~B\%%~V\*") do call :fj_try "%%~D" "%%~V"
    )
)
for %%R in ("%USERPROFILE%\.jdks" "%USERPROFILE%\.gradle\jdks" "%LOCALAPPDATA%\Programs\Eclipse Adoptium" "%LOCALAPPDATA%\Programs\Microsoft" "%USERPROFILE%\scoop\apps" "C:\Java" "D:\Java" "C:\jdk" "C:\Program Files\Java") do (
    for /d %%D in ("%%~R\*") do (
        call :fj_try "%%~D" user-folder
        call :fj_try "%%~D\current" scoop
    )
)

:fj_done
if not defined FOUND if defined FJ_DOWNLOAD call :fj_download

if not defined FOUND (
    echo   [java] No JDK %MINJ%-%MAXJ% found.
    if defined SKIPPED echo   [java] Found but not usable:!SKIPPED!
    endlocal
    exit /b 1
)
echo   [java] Java !FOUNDV! from !FOUNDSRC!: !FOUND!
if defined SKIPPED echo   [java] Skipped:!SKIPPED!
endlocal & set "JAVA_HOME=%FOUND%" & set "JAVA_MAJOR=%FOUNDV%"
exit /b 0


rem ============================================================================
rem  :fj_try <jdk-home> <source-label>   accept it if bin\java.exe exists and the
rem                                   version is between MINJ and MAXJ
rem ============================================================================
:fj_try
if defined FOUND goto :eof
set "C=%~1"
if not defined C goto :eof
for %%F in ("!C!") do set "C=%%~fF"
if "!C:~-1!"=="\" set "C=!C:~0,-1!"
if not exist "!C!\bin\java.exe" goto :eof
call :fj_version "!C!"
if !V! GEQ %MINJ% if !V! LEQ %MAXJ% (
    set "FOUND=!C!"
    set "FOUNDV=!V!"
    set "FOUNDSRC=%~2"
    goto :eof
)
set "SKIPPED=!SKIPPED! [Java !V!: !C!]"
goto :eof

rem ============================================================================
rem  :fj_version <jdk-home>  -> V = major version (0 if unknown)
rem  Reads <jdk-home>\release (no need to run java, no quoting problems);
rem  falls back to "java -version" written to a temp file.
rem ============================================================================
:fj_version
set "V=0"
set "JV="
if exist "%~1\release" (
    for /f "usebackq tokens=1,* delims==" %%a in ("%~1\release") do (
        if /i "%%a"=="JAVA_VERSION" set "JV=%%~b"
    )
)
if not defined JV (
    set "TMPF=%TEMP%\find-java-%RANDOM%.txt"
    "%~1\bin\java.exe" -version > "!TMPF!" 2>&1
    for /f "usebackq tokens=3" %%v in (`findstr /i /c:" version " "!TMPF!"`) do (
        if not defined JV set "JV=%%~v"
    )
    del "!TMPF!" >nul 2>&1
)
if not defined JV goto :eof
for /f "tokens=1,2 delims=.-_+" %%a in ("!JV!") do (
    set "V=%%a"
    if "%%a"=="1" set "V=%%b"
)
set /a V=V+0 >nul 2>&1 || set "V=0"
goto :eof

rem ============================================================================
rem  :fj_download - portable Eclipse Temurin JDK 21 into %USERPROFILE%\.jdks
rem  (the same folder Android Studio / IntelliJ use for downloaded JDKs)
rem ============================================================================
:fj_download
set "ARCH=x64"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH=aarch64"
if /i "%PROCESSOR_ARCHITEW6432%"=="ARM64" set "ARCH=aarch64"
set "DEST=%USERPROFILE%\.jdks"
set "ZIP=%TEMP%\temurin21-%RANDOM%.zip"
set "URL=https://api.adoptium.net/v3/binary/latest/21/ga/windows/%ARCH%/jdk/hotspot/normal/eclipse"
echo   [java] Downloading portable JDK 21 - Eclipse Temurin, about 200 MB - into %DEST% ...
if not exist "%DEST%" mkdir "%DEST%"
where curl.exe >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -UseBasicParsing -Uri '%URL%' -OutFile '%ZIP%'"
) else (
    curl.exe -fL --retry 3 -o "%ZIP%" "%URL%"
)
if not exist "%ZIP%" (
    echo   [java] Download failed - check internet connection.
    goto :eof
)
set "TAR=%SystemRoot%\System32\tar.exe"
if not exist "%TAR%" set "TAR=tar"
"%TAR%" -xf "%ZIP%" -C "%DEST%" >nul 2>&1
if errorlevel 1 powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Force -LiteralPath '%ZIP%' -DestinationPath '%DEST%'"
del "%ZIP%" >nul 2>&1
for /d %%D in ("%DEST%\jdk-21*") do call :fj_try "%%~D" downloaded
goto :eof
