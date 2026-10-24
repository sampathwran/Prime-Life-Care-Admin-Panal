@echo off
echo ====================================================
echo  Prime Life Care Admin - Build & Deploy to Firebase
echo ====================================================
echo [1/2] Compiling Flutter Web release bundle...
call flutter build web --release
if %errorlevel% neq 0 (
    echo [ERROR] Flutter Web compilation failed!
    exit /b %errorlevel%
)
echo.
echo [2/2] Deploying to Firebase Hosting (prime-life-care-admin.web.app)...
call firebase.cmd deploy --only hosting
if %errorlevel% equ 0 (
    echo.
    echo ====================================================
    echo  SUCCESS! Live at: https://prime-life-care-admin.web.app
    echo ====================================================
)
