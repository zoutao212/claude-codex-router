@echo off
echo ========================================
echo Starting Claude Code Router (PROD MODE)
echo ========================================
echo.

REM Check if dist/cli.js exists
echo [1/3] Checking build files...
if not exist "dist\cli.js" (
    echo Build not found, running build first...
    call build.bat
    if %errorlevel% neq 0 (
        echo [ERROR] Build failed
        pause
        exit /b 1
    )
) else (
    echo [OK] Build files found
)

REM Check if config exists
echo.
echo [2/3] Checking configuration...
if not exist "C:\Users\zouta\.claude-code-router\config.json" (
    echo [ERROR] Config file not found at C:\Users\zouta\.claude-code-router\config.json
    echo Please ensure the config file exists before starting
    pause
    exit /b 1
) else (
    echo [OK] Configuration file found
)

echo.
echo [3/3] Starting production server...
echo ========================================
echo Mode: Production (optimized build)
echo Config: C:\Users\zouta\.claude-code-router\config.json
echo Provider: novacode (GPT-5.4)
echo Upstream Retry: 15s window, max 5 attempts, exponential backoff
echo ========================================
echo.
echo Server will be available at:
echo   - API Endpoint: http://127.0.0.1:8080/v1/messages
echo   - Web UI: http://127.0.0.1:8080
echo   - Config API: http://127.0.0.1:8080/api/config
echo.
echo Press Ctrl+C to stop the server
echo ========================================
echo.

REM Set default port if not specified
set PORT=3456

REM Check if custom port is provided
if not "%1"=="" (
    set PORT=%1
    echo Using custom port: %PORT%
)

REM Set upstream retry configuration for production
set CCR_UPSTREAM_RETRY_TOTAL_MS=15000
set CCR_UPSTREAM_RETRY_MAX=5
set CCR_UPSTREAM_RETRY_BASE_MS=300

node dist\cli.js --port %PORT%

pause
