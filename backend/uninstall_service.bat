@echo off
setlocal

REM HazoraspBackend xizmatini to'xtatib, tizimdan olib tashlaydi.
REM "Administrator sifatida ishga tushirish" orqali bajarilishi kerak.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo XATOLIK: Bu skriptni "Administrator sifatida ishga tushirish" orqali bajaring.
    exit /b 1
)

set SERVICE_NAME=HazoraspBackend
set BACKEND_DIR=%~dp0
set NSSM=%BACKEND_DIR%..\nssm.exe

if not exist "%NSSM%" (
    echo XATOLIK: nssm.exe topilmadi: %NSSM%
    exit /b 1
)

"%NSSM%" stop %SERVICE_NAME%
"%NSSM%" remove %SERVICE_NAME% confirm

echo Xizmat olib tashlandi: %SERVICE_NAME%
