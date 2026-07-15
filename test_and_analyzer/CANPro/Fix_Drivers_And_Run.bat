@echo off
echo Installing Drivers...
cd Driver_Install
start /wait DriverSetup.exe
if %errorlevel% neq 0 (
    echo Driver setup might have failed or was cancelled.
)
cd ..
echo Starting CANPro...
start CANPro.exe
