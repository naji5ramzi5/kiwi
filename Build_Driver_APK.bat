@echo off
echo ===================================================
echo Building Fresh Driver App (Android APK)...
echo ===================================================
cd /d "%~dp0driver_app"

echo Running flutter clean...
call flutter clean

echo Running flutter pub get...
call flutter pub get

echo Building Release APK...
call flutter build apk --release

if errorlevel 1 (
    echo.
    echo [ERROR] Build failed!
    pause
    exit /b 1
)

echo.
echo Copying APK to Desktop...
copy "build\app\outputs\flutter-apk\app-release.apk" "%USERPROFILE%\Desktop\Fresh-Driver.apk" /y

echo.
echo ===================================================
echo [SUCCESS] Fresh-Driver.apk is now on your Desktop!
echo ===================================================
pause
