@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo     Android Dev Portfolio - App Runner / Switcher
echo ===================================================

set "APP_CHOICE=%~1"

if "%APP_CHOICE%"=="" (
    echo.
    echo Select an exercise app to build and install:
    echo   [1] exno1  - Graphical Primitives / Canvas
    echo   [2] exno2  - Basic Layouts and Views
    echo   [3] exno3  - Calculator Application
    echo   [4] exno4  - Form Controls / GUI Components
    echo   [5] exno5  - Database (SQLite) Application
    echo   [6] exno6  - Alert Dialogs and Notifications
    echo   [7] exno7  - Canvas / Drawing Application
    echo   [8] exno8  - Alarm Clock / Broadcast Receiver
    echo   [9] exno9  - Location / GPS Tracker
    echo  [10] exno10 - SD Card / File Storage Operations
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

if %ERRORLEVEL% equ 0 (
    echo.
    echo ===================================================
    echo [SUCCESS] %CHOICE% built and installed successfully!
    echo Launching app on device...
    echo ===================================================
    call adb shell monkey -p com.example.%CHOICE% -c android.intent.category.LAUNCHER 1 >nul 2>&1
    if not %ERRORLEVEL% equ 0 (
        if "%CHOICE%"=="exno2" (
            call adb shell monkey -p com.example.myapplication -c android.intent.category.LAUNCHER 1 >nul 2>&1
        )
    )
) else (
    echo.
    echo [ERROR] Build or installation failed for %CHOICE%.
)

echo.
pause
