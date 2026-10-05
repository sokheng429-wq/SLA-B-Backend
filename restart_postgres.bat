@echo off
echo Stopping PostgreSQL service...
net stop postgresql-x64-18
timeout /t 3 /nobreak >nul
echo Starting PostgreSQL service...
net start postgresql-x64-18
timeout /t 3 /nobreak >nul
echo Checking status...
"C:\Program Files\PostgreSQL\18\bin\pg_isready.exe" -h localhost -p 5432
pause
