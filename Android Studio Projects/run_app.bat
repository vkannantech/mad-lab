@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo ===================================================
echo     Android Dev Portfolio - App Runner / Switcher
echo ===================================================

set "APP_CHOICE=%~1"

if "%APP_CHOICE%"=="" (
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
    echo  [10] exno10 - RSS Feed Reader - AsyncTask
    echo.
    set /p "CHOICE=Enter exercise number (1-10) or name (e.g. exno3): "
) else (
    set "CHOICE=%APP_CHOICE%"
)

rem Normalize choice
if "%CHOICE%"=="1" set "CHOICE=exno1"
if "%CHOICE%"=="2" set "CHOICE=exno2"
if "%CHOICE%"=="3" set "CHOICE=exno3"
if "%CHOICE%"=="4" set "CHOICE=exno4"
if "%CHOICE%"=="5" set "CHOICE=exno5"
if "%CHOICE%"=="6" set "CHOICE=exno6"
if "%CHOICE%"=="7" set "CHOICE=exno7"
if "%CHOICE%"=="8" set "CHOICE=exno8"
if "%CHOICE%"=="9" set "CHOICE=exno9"
if "%CHOICE%"=="10" set "CHOICE=exno10"

echo.
echo [*] Selected Module: :%CHOICE%
echo [*] Building and installing on connected Android device/emulator...
echo.

call gradlew.bat :%CHOICE%:installDebug
set "BUILD_RC=%ERRORLEVEL%"
set "ADB=adb"
for /f "tokens=1,* delims==" %%a in ('findstr /b "sdk.dir=" local.properties 2^>nul') do set "SDKDIR=%%b"
if defined SDKDIR set "SDKDIR=!SDKDIR:\:=:!"
if defined SDKDIR if exist "!SDKDIR!\platform-tools\adb.exe" set "ADB=!SDKDIR!\platform-tools\adb.exe"

if %BUILD_RC% equ 0 (
    echo.
    echo ===================================================
    echo [SUCCESS] %CHOICE% built and installed successfully!
    echo Launching app on device...
    echo ===================================================
    call "!ADB!" shell monkey -p com.example.%CHOICE% -c android.intent.category.LAUNCHER 1 >nul 2>&1
    if not %ERRORLEVEL% equ 0 (
        if "%CHOICE%"=="exno2" (
            call "!ADB!" shell monkey -p com.example.myapplication -c android.intent.category.LAUNCHER 1 >nul 2>&1
        )
    )
) else (
    echo.
    echo [ERROR] Build or installation failed for %CHOICE%.
)

echo.
pause
