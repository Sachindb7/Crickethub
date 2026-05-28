@echo off
color 0A
echo Starting CricketHub Publisher...
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0publish.ps1"
echo.
pause
