@echo off
echo ====================================================================
echo  Restarting PostgreSQL Service (postgresql-x64-18)
echo ====================================================================
echo.
echo Requesting administrator privileges...
powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -Command Write-Host Restarting PostgreSQL service... -ForegroundColor Cyan; Restart-Service postgresql-x64-18; Write-Host PostgreSQL service restarted successfully! -ForegroundColor Green; Start-Sleep -Seconds 3'"
echo Done! Please check the elevated PowerShell window.
pause
