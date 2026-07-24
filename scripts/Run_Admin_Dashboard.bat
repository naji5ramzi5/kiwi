@echo off
title Kiwi Admin Dashboard
cd /d "%~dp0"
echo ===================================================
echo Starting Kiwi Admin Dashboard...
echo ===================================================
echo.

if exist "dist" (
    echo Opening http://localhost:3000 in your browser...
    echo Close this window to stop the server.
    echo.
    start http://localhost:3000
    npx vite preview --port 3000
) else (
    echo No production build found. Starting dev server...
    echo.
    call npm install
    start http://localhost:5173
    call npm run dev
)

pause
