@echo off
echo ===================================================
echo Building Fresh Customer App (Android APK)...
echo ===================================================
cd /d "C:\Users\IRAQ SOFT\Desktop\fresh-app\customer_app"

echo Running flutter clean...
call flutter clean

echo Running flutter pub get...
call flutter pub get

echo Building Release APK...
call flutter build apk --release

if errorlevel 1 (
    echo.
    echo [ERROR] Build failed!
    exit /b 1
)

echo.
echo Copying APK to Desktop...
if not exist "C:\Users\IRAQ SOFT\Desktop\fresh-app\APK" mkdir "C:\Users\IRAQ SOFT\Desktop\fresh-app\APK"
copy /y "build\app\outputs\flutter-apk\app-release.apk" "C:\Users\IRAQ SOFT\Desktop\fresh-app\APK\Fresh-Customer-v2.apk"

echo.
echo ===================================================
echo [SUCCESS] Fresh-Customer-v2.apk is now ready!
echo ===================================================
