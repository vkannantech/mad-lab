@echo off
rem One-time setup / environment doctor for Windows.
rem Finds Java + Android SDK, accepts SDK licenses, installs missing SDK parts, then builds all apps.
rem Usage: setup.bat           (check + build all)
rem        setup.bat --check   (only check, no build)
setlocal enabledelayedexpansion
cd /d "%~dp0"
set "FAILED=0"
echo === Android Dev Portfolio - setup check ===

rem ---------- 1. Java (Gradle 9 needs JDK 17+) ----------
set "JAVA_EXE="
if defined JAVA_HOME if exist "%JAVA_HOME%\bin\java.exe" set "JAVA_EXE=%JAVA_HOME%\bin\java.exe"
if not defined JAVA_EXE for %%J in (java.exe) do if not "%%~$PATH:J"=="" set "JAVA_EXE=%%~$PATH:J"
call :javaver
if !JMAJOR! LSS 17 (
    for %%D in ("%ProgramFiles%\Android\Android Studio\jbr" "%LOCALAPPDATA%\Programs\Android Studio\jbr" "%ProgramFiles%\Android\Android Studio\jre" "C:\Android\Android Studio\jbr") do (
        if exist "%%~D\bin\java.exe" if !JMAJOR! LSS 17 (
            set "JAVA_HOME=%%~D"
            set "JAVA_EXE=%%~D\bin\java.exe"
            call :javaver
        )
    )
)
if !JMAJOR! GEQ 17 (
    echo   [OK]   Java !JMAJOR!  ^(!JAVA_EXE!^)
) else (
    echo   [FAIL] JDK 17+ not found. Install Android Studio ^(it bundles one^) or JDK 17/21, or set JAVA_HOME.
    set "FAILED=1"
)

rem ---------- 2. Android SDK ----------
set "SDK="
for %%S in ("%ANDROID_HOME%" "%ANDROID_SDK_ROOT%" "%LOCALAPPDATA%\Android\Sdk" "%USERPROFILE%\AppData\Local\Android\Sdk" "C:\Android\Sdk") do (
    if not defined SDK if not "%%~S"=="" (
        if exist "%%~S\platforms" set "SDK=%%~S"
        if exist "%%~S\platform-tools" set "SDK=%%~S"
    )
)
if defined SDK (
    echo   [OK]   Android SDK  ^(!SDK!^)
    set "SDKFWD=!SDK:\=/!"
    > local.properties echo sdk.dir=!SDKFWD!
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
    if not exist "!SDK!\build-tools\34.0.0" if not exist "!SDK!\build-tools\35.0.0" if not exist "!SDK!\build-tools\36.0.0" set "NEED=!NEED! build-tools;34.0.0"
    if not exist "!SDK!\platform-tools" set "NEED=!NEED! platform-tools"
    if defined SDKM (
        (for /l %%i in (1,1,30) do @echo y) | call "!SDKM!" --licenses >nul 2>&1
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

rem ---------- 4. Build everything ----------
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

:javaver
set "JMAJOR=0"
if not defined JAVA_EXE goto :eof
for /f "tokens=3" %%V in ('"!JAVA_EXE!" -version 2^>^&1 ^| findstr /i "version"') do set "JV=%%~V"
for /f "tokens=1,2 delims=." %%a in ("!JV!") do (
    set "JMAJOR=%%a"
    if "%%a"=="1" set "JMAJOR=%%b"
)
goto :eof
