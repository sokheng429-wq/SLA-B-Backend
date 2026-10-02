@echo off
setlocal
echo ====================================================================
echo Starting B-Groceries SLA Tracker Backend (Spring Boot + PostgreSQL)
echo ====================================================================

if exist "C:\Java-SDK\jdk-26.0.2.1" (
    set "JAVA_HOME=C:\Java-SDK\jdk-26.0.2.1"
    set "PATH=%JAVA_HOME%\bin;%PATH%"
)

echo Java Version:
java -version

echo.
echo Starting application on port 8082...
echo API Health: http://localhost:8082/api/auth/health
echo Login API : POST http://localhost:8082/api/auth/login
echo.

call mvn spring-boot:run
pause
