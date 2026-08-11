@echo off
setlocal

REM Frontendni "HazoraspFrontend" nomli Windows xizmati sifatida
REM o'rnatadi (NSSM orqali) - backend\install_service.bat bilan bir xil
REM andoza (2026-08-11, backend allaqachon shu tarzda o'rnatilgan).
REM Xizmat kompyuter qayta yoqilganda avtomatik ishga tushadi va
REM kutilmagan tarzda o'chsa NSSM o'zi qayta ko'taradi.
REM
REM DIQQAT: shu paytgacha frontend oddiy `cmd` oynasida, start.bat
REM orqali (Windows xizmati EMAS, Service Recovery'siz) ishlab kelgan
REM edi - shu skript aynan shu bo'shliqni yopadi (backend uchun bo'lgan
REM bilan bir xil sabab).
REM
REM Talablar:
REM   1. C:\hazorasp_tarozi\nssm.exe mavjud bo'lishi kerak.
REM   2. Bu skript "Administrator sifatida ishga tushirish" orqali
REM      bajarilishi kerak.
REM   3. Python o'rnatilgan va PATH'da bo'lishi kerak.
REM   4. Eski (qo'lda, cmd oynasida) ishlab turgan frontend jarayoni
REM      OLDINDAN to'xtatilgan bo'lishi kerak (aks holda 47080 porti
REM      band bo'lib, yangi xizmat ishga tusholmaydi).

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo XATOLIK: Bu skriptni "Administrator sifatida ishga tushirish" orqali bajaring.
    exit /b 1
)

set SERVICE_NAME=HazoraspFrontend
set FRONTEND_DIR=%~dp0
set WEB_DIR=%FRONTEND_DIR%build\web
set NSSM=%FRONTEND_DIR%..\nssm.exe

if not exist "%NSSM%" (
    echo XATOLIK: nssm.exe topilmadi: %NSSM%
    exit /b 1
)

if not exist "%WEB_DIR%" (
    echo XATOLIK: %WEB_DIR% topilmadi - avval "flutter build web --release" bajaring.
    exit /b 1
)

for /f "delims=" %%P in ('where python') do (
    if "%PYTHON_EXE%"=="" set PYTHON_EXE=%%P
)
if "%PYTHON_EXE%"=="" (
    echo XATOLIK: python.exe PATH'da topilmadi.
    exit /b 1
)

echo Python:          %PYTHON_EXE%
echo Frontend papkasi: %WEB_DIR%

"%NSSM%" install %SERVICE_NAME% "%PYTHON_EXE%" "-m http.server 47080"
"%NSSM%" set %SERVICE_NAME% AppDirectory "%WEB_DIR%"
"%NSSM%" set %SERVICE_NAME% DisplayName "Hazorasp Frontend (Tarozi Tizimi)"
"%NSSM%" set %SERVICE_NAME% Description "Hazorasp Tekstil Tarozi Tizimi - Flutter web build server (port 47080)"
"%NSSM%" set %SERVICE_NAME% Start SERVICE_AUTO_START
"%NSSM%" set %SERVICE_NAME% AppStdout "%FRONTEND_DIR%frontend_stdout.log"
"%NSSM%" set %SERVICE_NAME% AppStderr "%FRONTEND_DIR%frontend_stderr.log"
"%NSSM%" set %SERVICE_NAME% AppRotateFiles 1
"%NSSM%" set %SERVICE_NAME% AppRotateBytes 5242880
"%NSSM%" set %SERVICE_NAME% AppRotateOnline 1
"%NSSM%" set %SERVICE_NAME% AppExit Default Restart
"%NSSM%" set %SERVICE_NAME% AppRestartDelay 3000

echo.
echo Xizmat o'rnatildi: %SERVICE_NAME%
echo Ishga tushirish uchun:  nssm start %SERVICE_NAME%
echo yoki:                   net start %SERVICE_NAME%
echo Loglarni ko'rish:       %FRONTEND_DIR%frontend_stdout.log / frontend_stderr.log
