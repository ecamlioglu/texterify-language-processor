@echo off
setlocal enabledelayedexpansion

REM Texterify Language Processor v2.0.0
REM Windows Batch Script
REM Author: Texterify Language Processor Team
REM License: MIT

REM Set UTF-8 encoding for better character support
chcp 65001 >nul 2>&1

REM Get script directory and project root
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."

REM Get version info dynamically
for /f "delims=" %%i in ('python "%PROJECT_ROOT%\get_version.py" full 2^>nul') do set "VERSION_INFO=%%i"
if not defined VERSION_INFO set "VERSION_INFO=Texterify Language Processor v2.1.0"

echo.
echo ==================================================
echo   🌐 %VERSION_INFO%
echo ==================================================
echo.

REM Check for help argument
if "%~1"=="--help" goto :show_help
if "%~1"=="-h" goto :show_help
if "%~1"=="/?" goto :show_help

REM Check for version argument
if "%~1"=="--version" goto :show_version
if "%~1"=="-v" goto :show_version

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is not installed or not in PATH
        echo         Please install Python 3.7+ from https://python.org
    echo         Make sure to check 'Add Python to PATH' during installation
    echo.
    pause
    exit /b 1
)

REM Get Python version for display
for /f "tokens=2" %%v in ('python --version 2^>^&1') do set PYTHON_VERSION=%%v
echo [INFO]  🐍 Using Python !PYTHON_VERSION!

REM Check if a zip file argument was provided
if "%~1"=="" (
    echo.
    echo [ERROR] Zip file path is required
    goto :show_usage
)

REM Validate zip file exists
if not exist "%~1" (
    echo [ERROR] Zip file not found: %~1
    echo.
    pause
    exit /b 1
)

REM Check if it's a zip file
echo "%~1" | findstr /i "\.zip$" >nul
if errorlevel 1 (
    echo [ERROR] File must be a .zip archive
    echo.
    pause
    exit /b 1
)

echo [INPUT] 📁 Processing: %~nx1

REM Parse counter arguments
set "COUNTER_ARGS="
if "%~2"=="--counter" (
    if "%~3"=="" (
        set "COUNTER_ARGS=--counter"
        echo [INFO]  🔢 Counter mode enabled (auto-detect)
    ) else (
        set "COUNTER_ARGS=--counter %~3"
        echo [INFO]  🔢 Counter mode enabled (value: %~3)
    )
) else if "%~2"=="-c" (
    if "%~3"=="" (
        set "COUNTER_ARGS=--counter"
        echo [INFO]  🔢 Counter mode enabled (auto-detect)
    ) else (
        set "COUNTER_ARGS=--counter %~3"
        echo [INFO]  🔢 Counter mode enabled (value: %~3)
    )
) else if not "%~2"=="" (
    echo "%~2" | findstr /r "^[0-9][0-9]*$" >nul
    if not errorlevel 1 (
        set "COUNTER_ARGS=--counter %~2"
        echo [INFO]  🔢 Counter mode enabled (value: %~2)
    ) else (
        echo [ERROR] Unknown argument: %~2
        echo         Use --help for usage information
        pause
        exit /b 1
    )
)

REM Check if Python script exists
set "PYTHON_SCRIPT=%PROJECT_ROOT%\src\texterify_processor.py"
if not exist "!PYTHON_SCRIPT!" (
    echo [ERROR] Python script not found: !PYTHON_SCRIPT!
    echo [INFO]  Make sure you're running this script from the project directory
    echo.
    pause
    exit /b 1
)

echo.
echo [START] 🚀 Running Texterify Language Processor...
echo =================================================

REM Run the processor
if defined COUNTER_ARGS (
    python "!PYTHON_SCRIPT!" "%~1" !COUNTER_ARGS!
) else (
    python "!PYTHON_SCRIPT!" "%~1"
)
set PROCESS_RESULT=!errorlevel!

echo =================================================
if !PROCESS_RESULT! equ 0 (
    echo [SUCCESS] ✅ Processing completed successfully!
    echo [RESULT]  ✅ Your processed language files are ready!
    if defined COUNTER_ARGS (
        echo [INFO]    📁 Counter was applied to output filename
    )
) else (
    echo [FAILED]  ❌ Processing encountered an error
    echo [HELP]    💡 Check the messages above for details
)

echo.
echo Press any key to exit...
pause >nul
exit /b !PROCESS_RESULT!

:show_help
echo.
echo Usage: %~nx0 ^<zip_file_path^> [options]
echo.
echo Arguments:
echo   zip_file_path    Path to the Texterify zip export file
echo.
echo Options:
echo   --counter, -c    Enable counter mode (auto-detect next number)
echo   --counter N      Use specific counter value N
echo   --help, -h       Show this help message
echo   --version, -v    Show version information
echo.
echo Examples:
echo   %~nx0 "my_texterify_export.zip"
echo   %~nx0 "export.zip" --counter
echo   %~nx0 "export.zip" --counter 3
echo   %~nx0 "C:\Downloads\language_files.zip"
echo.
echo Features:
echo   🔧 Renames 'en' files to: 24c9b00d-d028-4e04-a1aa-f04d2dcae2c3.json
echo   🔧 Renames 'tr' files to: 26c7ace9-13fc-43b8-9988-2384fe670d03.json
echo   🔧 Creates date-stamped output: lang_files_DD_MM.zip
echo   🔧 Optional counter for multiple files per day: lang_files_DD_MM_N.zip
echo   🔧 Preserves all other files in the archive
echo.
echo 💡 Tip: You can drag and drop a zip file onto this script!
echo 🌐 Texterify Language Processor v2.0.0
echo.
pause
exit /b 0

:show_usage
echo.
echo [USAGE] %~nx0 "path_to_your_zip_file.zip" [options]
echo.
echo Examples:
echo   %~nx0 "my_texterify_export.zip"
echo   %~nx0 "export.zip" --counter
echo   %~nx0 "C:\Downloads\language_files.zip"
echo.
echo Use --help for detailed information
echo.
pause
exit /b 1

:show_version
echo.
for /f "delims=" %%i in ('python "%PROJECT_ROOT%\get_version.py" full 2^>nul') do echo %%i
for /f "delims=" %%i in ('python "%PROJECT_ROOT%\get_version.py" license 2^>nul') do echo License: %%i
for /f "delims=" %%i in ('python "%PROJECT_ROOT%\get_version.py" python 2^>nul') do echo Python required: %%i
echo Platform: Windows Batch
echo.
pause
exit /b 0
