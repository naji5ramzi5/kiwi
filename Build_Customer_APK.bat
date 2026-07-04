@echo off
echo ===================================================
echo Building Fresh Customer App (Android APK)...
echo ===================================================
cd /d "%~dp0customer_app"

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
copy "build\app\outputs\flutter-apk\app-release.apk" "%USERPROFILE%\Desktop\Fresh-Customer.apk" /y

echo.
echo ===================================================
echo [SUCCESS] Fresh-Customer.apk is now on your Desktop!
echo ===================================================
pause
