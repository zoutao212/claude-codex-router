@echo off
echo Testing pnpm installation...
pnpm --version
if %errorlevel% equ 0 (
    echo pnpm is working correctly!
) else (
    echo pnpm not found or not working
)
pause
