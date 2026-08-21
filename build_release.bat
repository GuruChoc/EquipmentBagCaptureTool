@echo off
setlocal EnableExtensions

cd /d "%~dp0"

if not exist VERSION (
    echo ERROR: VERSION file not found.
    pause
    exit /b 1
)

set /p VERSION=<VERSION
set "ZIP=EquipmentBagCaptureTool_%VERSION%.zip"
set "STAGE=%TEMP%\EquipmentBagCaptureTool_%RANDOM%_%RANDOM%"

if exist "%STAGE%" rmdir /s /q "%STAGE%"
mkdir "%STAGE%" || exit /b 1

for %%F in (
    EquipmentBagCaptureTool.ahk
    EquipmentBagCaptureCalibration.ahk
    Check_Screenshot_Folder_CRC.bat
    README.md
    CHANGELOG.md
    LICENSE
    VERSION
) do (
    if not exist "%%F" (
        echo ERROR: Required release file missing: %%F
        rmdir /s /q "%STAGE%"
        pause
        exit /b 1
    )
    copy /y "%%F" "%STAGE%\%%F" >nul
)

if exist "%ZIP%" del /q "%ZIP%"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Compress-Archive -Path '%STAGE%\*' -DestinationPath '%CD%\%ZIP%' -Force"

if errorlevel 1 (
    echo ERROR: Could not create %ZIP%.
    rmdir /s /q "%STAGE%"
    pause
    exit /b 1
)

rmdir /s /q "%STAGE%"

echo.
echo Release package created successfully:
echo %CD%\%ZIP%
echo.
echo EquipmentBagCapture.ini is intentionally NOT included.
echo.
pause
