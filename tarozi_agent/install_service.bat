@echo off
setlocal

REM Tarozi agentini "TaroziAgent" nomli Windows xizmati sifatida o'rnatadi
REM (NSSM orqali). Xizmat kompyuter qayta yoqilganda, login qilinmasa ham,
REM avtomatik ishga tushadi va process kutilmaganda yiqilib qolsa (masalan
REM xatolik chiqsa) NSSM o'zi qayta ko'taradi.
REM
REM Talablar:
REM   1. nssm.exe (https://nssm.cc/download) shu papkaga joylashtirilgan bo'lishi kerak.
REM   2. Bu skript "Administrator sifatida ishga tushirish" orqali bajarilishi kerak.
REM   3. Python o'rnatilgan va PATH'da bo'lishi kerak (`pip install -r requirements.txt` bajarilgan).
REM   4. tarozi_agent\.env fayli to'ldirilgan (TAROZI_PORT, SERVER_URL, TAROZI_AGENT_KEY).

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo XATOLIK: Bu skriptni "Administrator sifatida ishga tushirish" orqali bajaring.
    exit /b 1
)

set SERVICE_NAME=TaroziAgent
set AGENT_DIR=%~dp0
set NSSM=%AGENT_DIR%nssm.exe

if not exist "%NSSM%" (
    echo XATOLIK: nssm.exe topilmadi: %NSSM%
    echo https://nssm.cc/download saytidan yuklab, shu papkaga joylashtiring.
    exit /b 1
)

for /f "delims=" %%P in ('where python') do (
    if "%PYTHON_EXE%"=="" set PYTHON_EXE=%%P
)
if "%PYTHON_EXE%"=="" (
    echo XATOLIK: python.exe PATH'da topilmadi.
    exit /b 1
)

if not exist "%AGENT_DIR%.env" (
    echo XATOLIK: %AGENT_DIR%.env topilmadi. Avval .env.example'dan nusxa
    echo oling va TAROZI_PORT / SERVER_URL / TAROZI_AGENT_KEY'ni to'ldiring.
    exit /b 1
)

echo Python:        %PYTHON_EXE%
echo Agent papkasi: %AGENT_DIR%

"%NSSM%" install %SERVICE_NAME% "%PYTHON_EXE%" "%AGENT_DIR%tarozi_agent.py"
"%NSSM%" set %SERVICE_NAME% AppDirectory "%AGENT_DIR%"
"%NSSM%" set %SERVICE_NAME% DisplayName "Hazorasp Tarozi Agenti"
"%NSSM%" set %SERVICE_NAME% Description "COM portdagi tarozini o'qib, asosiy serverga tarmoq orqali yuboradi"
"%NSSM%" set %SERVICE_NAME% Start SERVICE_AUTO_START
"%NSSM%" set %SERVICE_NAME% AppStdout "%AGENT_DIR%agent_stdout.log"
"%NSSM%" set %SERVICE_NAME% AppStderr "%AGENT_DIR%agent_stderr.log"
"%NSSM%" set %SERVICE_NAME% AppRotateFiles 1
"%NSSM%" set %SERVICE_NAME% AppRotateBytes 1048576
"%NSSM%" set %SERVICE_NAME% AppExit Default Restart
"%NSSM%" set %SERVICE_NAME% AppRestartDelay 3000

echo.
echo Xizmat o'rnatildi: %SERVICE_NAME%
echo Ishga tushirish uchun:  nssm start %SERVICE_NAME%
echo yoki:                   net start %SERVICE_NAME%
echo Loglarni ko'rish:       %AGENT_DIR%agent_stdout.log / agent_stderr.log
