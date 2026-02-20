@echo off
setlocal enabledelayedexpansion

:: Check args
if "%~1"=="" (
    echo Usage: %~n0 oldprefix newprefix
    exit /b 1
)
if "%~2"=="" (
    echo Usage: %~n0 oldprefix newprefix
    exit /b 1
)

set "oldprefix=%~1"
set "newprefix=%~2"

for %%f in ("%oldprefix%*") do (
    set "filename=%%~nxf"
    set "newname=!filename:%oldprefix%=%newprefix%!"
    echo Renaming "%%f" to "!newname!"
    ren "%%f" "!newname!"
)

echo Done.
