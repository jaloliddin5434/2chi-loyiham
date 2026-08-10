@echo off
setlocal

REM profilaktik_restart.bat'ni har kuni soat 05:00'da (tortish ishlari
REM boshlanishidan oldin) avtomatik chaqiradigan Windows Task Scheduler
REM vazifasini o'rnatadi - qarang: profilaktik_restart.bat izohi (nima
REM uchun kerakligi haqida).
REM
REM Talablar:
REM   Bu skript "Administrator sifatida ishga tushirish" orqali bajarilishi kerak.
REM
REM Bir necha marta ishga tushirish xavfsiz - /f bilan mavjud vazifa
REM qayta yoziladi (xato bermaydi).

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo XATOLIK: Bu skriptni "Administrator sifatida ishga tushirish" orqali bajaring.
    exit /b 1
)

set TASK_NAME=TaroziAgentProfilaktikRestart
set AGENT_DIR=%~dp0

if not exist "%AGENT_DIR%profilaktik_restart.bat" (
    echo XATOLIK: %AGENT_DIR%profilaktik_restart.bat topilmadi.
    exit /b 1
)

schtasks /create /tn "%TASK_NAME%" ^
    /tr "\"%AGENT_DIR%profilaktik_restart.bat\"" ^
    /sc daily /st 05:00 /ru SYSTEM /rl HIGHEST /f

if %errorlevel% neq 0 (
    echo XATOLIK: Vazifani ro'yxatga olishda xato yuz berdi.
    exit /b 1
)

echo.
echo Vazifa o'rnatildi: %TASK_NAME% (har kuni 05:00'da ishga tushadi)
echo Tekshirish uchun:  schtasks /query /tn "%TASK_NAME%" /v /fo list
echo O'chirish uchun:   schtasks /delete /tn "%TASK_NAME%" /f
