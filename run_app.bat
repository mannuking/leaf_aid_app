@echo off
echo Starting Leaf Aid application...

:: Check if Python is installed
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo Python is not installed or not in the PATH. Please install Python and try again.
    exit /b 1
)

:: Start the backend server in a new window
echo Starting the backend server...
start cmd /k "cd backend && python run_server.py"

:: Wait for the server to start
echo Waiting for server to start...
timeout /t 5 /nobreak

:: Run the health check to verify the server is working
echo Running health check...
cd backend && python health_check.py

:: Go back to the root directory
cd ..

:: Check if Flutter is installed
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo Flutter is not installed or not in the PATH. Please install Flutter and try again.
    exit /b 1
)

:: Start the Flutter app
echo Starting the Flutter app...
flutter run
