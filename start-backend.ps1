Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host " Starting B-Groceries SLA Tracker Backend (Spring Boot + PostgreSQL)" -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Cyan

if (Test-Path "C:\Java-SDK\jdk-26.0.2.1") {
    $env:JAVA_HOME = "C:\Java-SDK\jdk-26.0.2.1"
    $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
}

Write-Host "`nActive Java Environment:" -ForegroundColor Yellow
& java -version

Write-Host "`nStarting Spring Boot on port 8082..." -ForegroundColor Green
Write-Host "  Health Endpoint: http://localhost:8082/api/auth/health" -ForegroundColor White
Write-Host "  Login Endpoint : POST http://localhost:8082/api/auth/login" -ForegroundColor White
Write-Host "  Register       : POST http://localhost:8082/api/auth/register" -ForegroundColor White
Write-Host "  Current User   : GET http://localhost:8082/api/auth/me (Bearer Token)`n" -ForegroundColor White

# Pre-flight PostgreSQL connection check
$pgCheck = & "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U root -h localhost -d postgres -c "SELECT 1;" 2>&1
if ($pgCheck -match "in recovery mode") {
    Write-Host "[WARNING] PostgreSQL is stuck in recovery mode!" -ForegroundColor Red
    Write-Host "Please restart the PostgreSQL service with Administrator privileges:" -ForegroundColor Yellow
    Write-Host "  Option 1: Double-click 'restart-postgres.bat' in this folder" -ForegroundColor Cyan
    Write-Host "  Option 2: Run in an Administrator terminal: Restart-Service postgresql-x64-18`n" -ForegroundColor Cyan
}

& mvn spring-boot:run
