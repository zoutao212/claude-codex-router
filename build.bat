@echo off
echo ========================================
echo Building Claude Code Router Project...
echo ========================================
echo.

REM Check if pnpm is installed
echo [0/5] Checking pnpm installation...
pnpm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] pnpm is not installed or not in PATH
    echo Please install pnpm first: npm install -g pnpm
    pause
    exit /b 1
)
echo [OK] pnpm is available

echo.
echo [1/5] Installing dependencies...
call pnpm install
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install dependencies
    pause
    exit /b 1
)
echo [OK] Dependencies installed

echo.
echo [2/5] Building shared package...
call pnpm build:shared
if %errorlevel% neq 0 (
    echo [ERROR] Failed to build shared package
    pause
    exit /b 1
)
echo [OK] Shared package built

echo.
echo [3/5] Building core package...
call pnpm build:core
if %errorlevel% neq 0 (
    echo [ERROR] Failed to build core package
    pause
    exit /b 1
)
echo [OK] Core package built

echo.
echo [4/5] Building server package...
call pnpm build:server
if %errorlevel% neq 0 (
    echo [ERROR] Failed to build server package
    pause
    exit /b 1
)
echo [OK] Server package built

echo.
echo [5/5] Building CLI and UI packages...
call pnpm build:cli
if %errorlevel% neq 0 (
    echo [ERROR] Failed to build CLI/UI packages
    pause
    exit /b 1
)
echo [OK] CLI and UI packages built

echo.
echo ========================================
echo Build completed successfully!
echo ========================================
echo.
echo You can now run:
echo   - start-dev.bat     (Development mode)
echo   - start-prod.bat    (Production mode)
echo.
pause
