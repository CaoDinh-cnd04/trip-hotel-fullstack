@echo off
echo ============================================
echo   Starting Hotel Booking Backend Server
echo ============================================
echo.

cd /d "%~dp0hotel-booking-backend"

echo Checking if node_modules exists...
if not exist "node_modules\" (
    echo Installing dependencies...
    call npm install
    echo.
)

echo Starting server...
echo Server will run at: http://localhost:5000
echo API V2 available at: http://localhost:5000/api/v2
echo.
echo Press Ctrl+C to stop the server
echo ============================================
echo.

call npm start

pause

