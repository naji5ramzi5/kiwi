@echo off
echo ========================================
echo  Kiwi Fresh POS - Build ^& Installer
echo ========================================
echo.

:: Step 1: Build Flutter Windows Release
echo [1/3] Building Flutter Windows Release...
cd /d "%~dp0\.."
flutter build windows --release
if %errorlevel% neq 0 (
    echo ERROR: Flutter build failed!
    pause
    exit /b 1
)
echo Flutter build completed successfully!
echo.

:: Step 2: Check if Inno Setup is installed
echo [2/3] Checking for Inno Setup...
set "ISCC="
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    set "ISCC=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
) else if exist "C:\Program Files\Inno Setup 6\ISCC.exe" (
    set "ISCC=C:\Program Files\Inno Setup 6\ISCC.exe"
) else if exist "C:\Program Files (x86)\Inno Setup 5\ISCC.exe" (
    set "ISCC=C:\Program Files (x86)\Inno Setup 5\ISCC.exe"
)

if "%ISCC%"=="" (
    echo WARNING: Inno Setup not found!
    echo Please install Inno Setup from: https://jrsoftware.org/isdl.php
    echo Then run this script again.
    echo.
    echo Build output is at: build\windows\x64\runner\Release\
    pause
    exit /b 0
)
echo Found Inno Setup: %ISCC%
echo.

:: Step 3: Compile Installer
echo [3/3] Compiling installer...
cd /d "%~dp0"
"%ISCC%" kiwi_pos_setup.iss
if %errorlevel% neq 0 (
    echo ERROR: Installer compilation failed!
    pause
    exit /b 1
)
echo.
echo ========================================
echo  Build Complete!
echo  Installer: installer\output\KiwiFreshPOS_Setup_1.0.0.exe
echo ========================================
pause
