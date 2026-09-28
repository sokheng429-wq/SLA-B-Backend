Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host " Starting B-Groceries SLA Tracker Backend (Spring Boot + PostgreSQL)" -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Cyan

if (Test-Path "C:\Java-SDK\jdk-26.0.2.1") {
    $env:JAVA_HOME = "C:\Java-SDK\jdk-26.0.2.1"
    $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
}

Write-Host "`nActive Java Environment:" -ForegroundColor Yellow
& java -version

Write-Host "`nStarting Spring Boot on port 8080..." -ForegroundColor Green
Write-Host "  Health Endpoint: http://localhost:8080/api/auth/health" -ForegroundColor White
Write-Host "  Login Endpoint : POST http://localhost:8080/api/auth/login" -ForegroundColor White
Write-Host "  Register       : POST http://localhost:8080/api/auth/register" -ForegroundColor White
Write-Host "  Current User   : GET http://localhost:8080/api/auth/me (Bearer Token)`n" -ForegroundColor White

& mvn spring-boot:run
