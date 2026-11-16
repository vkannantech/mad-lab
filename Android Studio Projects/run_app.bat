@echo off
rem Android Dev Portfolio - App Runner (Windows). Usage: run_app.bat [1-10 | exnoN]
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo ===================================================
echo     Android Dev Portfolio - App Runner / Switcher
echo ===================================================

rem ---------- Java: find a JDK 17-25 and set JAVA_HOME ----------
call "%~dp0setup.bat" --find-java
if errorlevel 1 (
    echo.
    echo [ERROR] No usable Java found. Run setup.bat - it can download one automatically.
    pause
    exit /b 1
)

set "CHOICE=%~1"
if "%CHOICE%"=="" (
    echo.
    echo Select an exercise app to build and install:
    echo   [1] exno1  - GUI Components - Font size and Color
    echo   [2] exno2  - Layouts, Spinner and Intent
    echo   [3] exno3  - Graphical Primitives - Canvas
    echo   [4] exno4  - SQLite Database - Student Records
    echo   [5] exno5  - Notifications
    echo   [6] exno6  - Image Loading - Bitmap
    echo   [7] exno7  - GPS Location
    echo   [8] exno8  - File Storage - Write/Read
    echo   [9] exno9  - Notifications + Fragments
    echo  [10] exno10 - RSS News Feed - AsyncTask
    echo.
    set /p "CHOICE=Enter exercise number (1-10) or name (e.g. exno3): "
)

if not defined CHOICE (
    echo [ERROR] No app selected.
    pause
    exit /b 1
)
rem Normalize: "3" -> "exno3"
set "CHOICE=%CHOICE: =%"
echo %CHOICE%| findstr /r "^[0-9][0-9]*$" >nul && set "CHOICE=exno%CHOICE%"
if not exist "%CHOICE%\app\build.gradle.kts" (
    echo [ERROR] Unknown app "%CHOICE%". Use 1-10 or exno1-exno10.
    pause
    exit /b 1
)
set "PKG=com.example.%CHOICE%"
if /i "%CHOICE%"=="exno2" set "PKG=com.example.myapplication"

echo.
echo [*] Selected Module: :%CHOICE%
echo [*] Building and installing on connected Android device/emulator...
echo.

call gradlew.bat :%CHOICE%:installDebug
set "BUILD_RC=%ERRORLEVEL%"

rem ---------- adb from the SDK in local.properties (written by gradle\sdk-autodetect.gradle.kts) ----------
set "ADB=adb"
set "SDKDIR="
if exist local.properties for /f "usebackq tokens=1,* delims==" %%a in ("local.properties") do (
    if /i "%%a"=="sdk.dir" set "SDKDIR=%%b"
)
if defined SDKDIR (
    set "SDKDIR=!SDKDIR:\:=:!"
    set "SDKDIR=!SDKDIR:\\=\!"
    set "SDKDIR=!SDKDIR:/=\!"
    if exist "!SDKDIR!\platform-tools\adb.exe" set "ADB=!SDKDIR!\platform-tools\adb.exe"
)

if not "%BUILD_RC%"=="0" (
    echo.
    echo [ERROR] Build or installation failed for %CHOICE%.
    echo         Is a phone/emulator connected? Check with: "!ADB!" devices
    echo         Environment problems? Run: setup.bat --check
    pause
    exit /b 1
)

echo.
echo ===================================================
echo [SUCCESS] %CHOICE% built and installed successfully!
echo Launching app on device...
echo ===================================================
call "!ADB!" shell monkey -p %PKG% -c android.intent.category.LAUNCHER 1 >nul 2>&1
if errorlevel 1 echo [!] Installed, but could not auto-launch. Open it from the phone's app list.
echo.
pause
