@echo off
echo ===================================================
echo Building Fresh Branch POS App (Windows EXE)...
echo ===================================================
cd /d "%~dp0branch_pos"

echo Running flutter clean...
call flutter clean

echo Running flutter pub get...
call flutter pub get

echo Building Release Windows Application...
call flutter build windows --release

if errorlevel 1 (
    echo.
    echo [ERROR] Build failed!
    pause
    exit /b 1
)

echo.
echo Creating Fresh-Branch-POS folder on Desktop...
if not exist "%USERPROFILE%\Desktop\Fresh-Branch-POS" mkdir "%USERPROFILE%\Desktop\Fresh-Branch-POS"

echo Copying build files to Desktop...
xcopy "build\windows\x64\runner\Release\*.*" "%USERPROFILE%\Desktop\Fresh-Branch-POS\" /s /e /y

echo.
echo ===================================================
echo [SUCCESS] Fresh-Branch-POS folder is now on your Desktop!
echo Open the folder and run branch_pos.exe
echo ===================================================
pause
