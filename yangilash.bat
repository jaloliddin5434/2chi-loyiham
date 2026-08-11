@echo off
setlocal

REM Loyihani (backend + frontend) so'nggi git versiyasiga yangilaydi:
REM git pull -> pip install -> pytest -> [tasdiqlash] -> xizmatlarni
REM to'xtatish -> alembic migratsiya -> flutter build -> xizmatlarni
REM qayta ishga tushirish -> sog'lomlikni tekshirish. Har qanday
REM bosqichda xato chiqsa (yoki foydalanuvchi tasdiqlamasa), avtomatik
REM ravishda ESKI, ishlaydigan holatga qaytariladi.
REM
REM DIQQAT: bu skript FAQAT shu (ofis/backend) kompyuterni yangilaydi.
REM tarozi_agent (tarozixona kompyuteri) BUTUNLAY ALOHIDA, bu yerga
REM kirmaydi - uni yangilash uchun alohida qo'lda amal bajarilishi kerak.
REM
REM Talab: Administrator sifatida ishga tushirilishi kerak (xizmatlarni
REM to'xtatish/ishga tushirish va ba'zi papkalarga yozish uchun).

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo XATOLIK: Bu skriptni "Administrator sifatida ishga tushirish" orqali bajaring.
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0yangilash.ps1"
set YANGILASH_NATIJA=%errorlevel%

echo.
if %YANGILASH_NATIJA% equ 0 (
    echo Yangilash tugadi - batafsil: yangilash_tarixi.log
) else (
    echo Yangilash MUVAFFAQIYATSIZ tugadi (kod %YANGILASH_NATIJA%) - batafsil: yangilash_tarixi.log
)
exit /b %YANGILASH_NATIJA%
