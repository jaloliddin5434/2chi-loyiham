@echo off
setlocal

REM Backendni "HazoraspBackend" nomli Windows xizmati sifatida o'rnatadi
REM (NSSM orqali) - xuddi tarozi_agent\install_service.bat/CloudflaredTunnel
REM bilan bir xil andoza. Xizmat kompyuter qayta yoqilganda, login
REM qilinmasa ham, avtomatik ishga tushadi va process kutilmaganda
REM yiqilib qolsa (masalan xatolik chiqsa yoki majburan o'chirilsa)
REM NSSM o'zi qayta ko'taradi.
REM
REM DIQQAT: shu paytgacha backend oddiy `cmd` oynasida, start.bat
REM orqali (Windows xizmati EMAS, Service Recovery'siz) ishlab kelgan
REM edi - shu skript aynan shu bo'shliqni yopadi.
REM
REM Talablar:
REM   1. C:\hazorasp_tarozi\nssm.exe mavjud bo'lishi kerak (allaqachon
REM      CloudflaredTunnel uchun ishlatilmoqda).
REM   2. Bu skript "Administrator sifatida ishga tushirish" orqali
REM      bajarilishi kerak.
REM   3. Python o'rnatilgan va PATH'da bo'lishi kerak.
REM   4. backend\.env fayli to'ldirilgan bo'lishi kerak.
REM   5. Eski (qo'lda, cmd oynasida) ishlab turgan backend jarayoni
REM      OLDINDAN to'xtatilgan bo'lishi kerak (aks holda 47001 porti
REM      band bo'lib, yangi xizmat ishga tusholmaydi).

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo XATOLIK: Bu skriptni "Administrator sifatida ishga tushirish" orqali bajaring.
    exit /b 1
)

set SERVICE_NAME=HazoraspBackend
set BACKEND_DIR=%~dp0
set NSSM=%BACKEND_DIR%..\nssm.exe

REM %~dp0 HAR DOIM oxirida "\" bilan tugaydi - AppDirectory uchun
REM oxiridagi "\"siz alohida nusxa kerak (tarozi_agent\install_service.bat
REM bilan bir xil sabab - qarang shu fayldagi izoh).
set BACKEND_DIR_NOSLASH=%BACKEND_DIR%
if "%BACKEND_DIR_NOSLASH:~-1%"=="\" set BACKEND_DIR_NOSLASH=%BACKEND_DIR_NOSLASH:~0,-1%

if not exist "%NSSM%" (
    echo XATOLIK: nssm.exe topilmadi: %NSSM%
    exit /b 1
)

for /f "delims=" %%P in ('where python') do (
    if "%PYTHON_EXE%"=="" set PYTHON_EXE=%%P
)
if "%PYTHON_EXE%"=="" (
    echo XATOLIK: python.exe PATH'da topilmadi.
    exit /b 1
)

if not exist "%BACKEND_DIR%.env" (
    echo XATOLIK: %BACKEND_DIR%.env topilmadi - avval to'ldiring.
    exit /b 1
)

echo Python:         %PYTHON_EXE%
echo Backend papkasi: %BACKEND_DIR%

"%NSSM%" install %SERVICE_NAME% "%PYTHON_EXE%" "-m uvicorn main:app --host 0.0.0.0 --port 47001 --forwarded-allow-ips="
"%NSSM%" set %SERVICE_NAME% AppDirectory "%BACKEND_DIR_NOSLASH%"
"%NSSM%" set %SERVICE_NAME% DisplayName "Hazorasp Backend (Tarozi Tizimi)"
"%NSSM%" set %SERVICE_NAME% Description "Hazorasp Tekstil Tarozi Tizimi - FastAPI backend (port 47001)"
"%NSSM%" set %SERVICE_NAME% Start SERVICE_AUTO_START
"%NSSM%" set %SERVICE_NAME% AppStdout "%BACKEND_DIR%backend_stdout.log"
"%NSSM%" set %SERVICE_NAME% AppStderr "%BACKEND_DIR%backend_stderr.log"
"%NSSM%" set %SERVICE_NAME% AppRotateFiles 1
"%NSSM%" set %SERVICE_NAME% AppRotateBytes 5242880
REM AppRotateOnline'siz, hajm bo'yicha aylanish FAQAT xizmat qayta ishga
REM tushganda tekshiriladi - backend oylab qayta ishga tushmasdan
REM ishlashi mo'ljallangani uchun (qarang: tarozi_agent\install_service.bat,
REM xuddi shu sabab).
"%NSSM%" set %SERVICE_NAME% AppRotateOnline 1
"%NSSM%" set %SERVICE_NAME% AppExit Default Restart
"%NSSM%" set %SERVICE_NAME% AppRestartDelay 3000

echo.
echo Xizmat o'rnatildi: %SERVICE_NAME%
echo Ishga tushirish uchun:  nssm start %SERVICE_NAME%
echo yoki:                   net start %SERVICE_NAME%
echo Loglarni ko'rish:       %BACKEND_DIR%backend_stdout.log / backend_stderr.log
