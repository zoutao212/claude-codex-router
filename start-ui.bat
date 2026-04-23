@echo off
echo ========================================
echo Starting Claude Code Router Web UI
echo ========================================
echo.

REM Set UTF-8 encoding for console
chcp 65001 >nul

REM Configuration
set SERVER_PORT=8082
set UI_PORT=5173
set CONFIG_DIR=%USERPROFILE%\.claude-code-router

echo Checking prerequisites...
echo.

REM Check if Node.js is available
where node >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js is not installed or not in PATH
    pause
    exit /b 1
)

REM Check if pnpm is available
where pnpm >nul 2>&1
if errorlevel 1 (
    echo [ERROR] pnpm is not installed or not in PATH
    pause
    exit /b 1
)

REM Kill residual processes on server port
echo Checking for residual processes on port %SERVER_PORT%...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr "LISTENING" ^| findstr ":%SERVER_PORT% "') do (
    echo   Found process %%a on port %SERVER_PORT%, killing...
    taskkill /F /PID %%a >nul 2>&1
)
echo.

REM Kill residual processes on UI dev port
echo Checking for residual processes on port %UI_PORT%...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr "LISTENING" ^| findstr ":%UI_PORT% "') do (
    echo   Found process %%a on port %UI_PORT%, killing...
    taskkill /F /PID %%a >nul 2>&1
)
echo.

REM Build core and server if needed
if not exist "packages\core\dist" (
    echo Building core package...
    pnpm.cmd build:core
    if errorlevel 1 (
        echo [ERROR] Failed to build core package
        pause
        exit /b 1
    )
)

if not exist "packages\server\dist" (
    echo Building server package...
    pnpm.cmd build:server
    if errorlevel 1 (
        echo [ERROR] Failed to build server package
        pause
        exit /b 1
    )
)

echo.
echo ========================================
echo Starting backend server (port %SERVER_PORT%)...
echo ========================================
echo.

set CCR_TRACE=1
set SERVICE_PORT=%SERVER_PORT%
set CCR_UPSTREAM_RETRY_TOTAL_MS=15000
set CCR_UPSTREAM_RETRY_MAX=5
set CCR_UPSTREAM_RETRY_BASE_MS=300

start "CCR-Server" /min cmd /c "cd /d %~dp0 && pnpm.cmd dev:server"

REM Wait for server to start
echo Waiting for backend server to be ready...
set MAX_WAIT=30
set WAIT_COUNT=0

:wait_server
timeout /t 1 /nobreak >nul
set /a WAIT_COUNT+=1

REM Try to connect to the server
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:%SERVER_PORT%/health' -UseBasicParsing -TimeoutSec 2; exit 0 } catch { exit 1 }" >nul 2>&1
if errorlevel 1 (
    if %WAIT_COUNT% LSS %MAX_WAIT% (
        echo   Waiting... (%WAIT_COUNT%/%MAX_WAIT%s)
        goto wait_server
    ) else (
        echo [WARN] Server did not respond within %MAX_WAIT% seconds, continuing anyway...
    )
) else (
    echo   [OK] Backend server is ready!
)

echo.
echo ========================================
echo Starting UI dev server (port %UI_PORT%)...
echo ========================================
echo.

REM Start UI dev server in a new window
start "CCR-UI" cmd /c "cd /d %~dp0 && pnpm.cmd dev:ui"

REM Wait for UI server to start
echo Waiting for UI dev server to be ready...
set WAIT_COUNT=0

:wait_ui
timeout /t 1 /nobreak >nul
set /a WAIT_COUNT+=1

powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:%UI_PORT%/' -UseBasicParsing -TimeoutSec 2; exit 0 } catch { exit 1 }" >nul 2>&1
if errorlevel 1 (
    if %WAIT_COUNT% LSS %MAX_WAIT% (
        echo   Waiting... (%WAIT_COUNT%/%MAX_WAIT%s)
        goto wait_ui
    ) else (
        echo [WARN] UI server did not respond within %MAX_WAIT% seconds
    )
) else (
    echo   [OK] UI dev server is ready!
)

echo.
echo ========================================
echo Services are running!
echo ========================================
echo.
echo   Web UI:        http://127.0.0.1:%UI_PORT%
echo   API Endpoint:  http://127.0.0.1:%SERVER_PORT%/v1/messages
echo   OpenAI:        http://127.0.0.1:%SERVER_PORT%/v1/chat/completions
echo   Config API:    http://127.0.0.1:%SERVER_PORT%/api/config
echo   Health:        http://127.0.0.1:%SERVER_PORT%/health
echo.
echo   Config file:   %CONFIG_DIR%\config.json
echo.
echo Opening Web UI in browser...
echo.

REM Open browser
start http://127.0.0.1:%UI_PORT%

echo Press any key to stop all services...
pause >nul

REM Cleanup: kill both server processes
echo.
echo Stopping services...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr "LISTENING" ^| findstr ":%SERVER_PORT% "') do (
    taskkill /F /PID %%a >nul 2>&1
)
for /f "tokens=5" %%a in ('netstat -ano ^| findstr "LISTENING" ^| findstr ":%UI_PORT% "') do (
    taskkill /F /PID %%a >nul 2>&1
)
echo Services stopped.
