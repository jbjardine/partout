@echo off
setlocal

if "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "MINGW_PREFIX=aarch64-w64-mingw32"
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "MINGW_PREFIX=x86_64-w64-mingw32"
if not defined MINGW_PREFIX (
    echo Unsupported PROCESSOR_ARCHITECTURE=%PROCESSOR_ARCHITECTURE%
    exit /b 1
)

if not defined CC set "CC=%MINGW_PREFIX%-gcc"
if not defined CXX set "CXX=%MINGW_PREFIX%-g++"

nmake /f Makefile.windows "DESTDIR=%~1" "MINGW_PREFIX=%MINGW_PREFIX%" "CC=%CC%" "CXX=%CXX%"
exit /b %ERRORLEVEL%
