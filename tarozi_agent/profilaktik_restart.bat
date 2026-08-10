@echo off
setlocal

REM TaroziAgent xizmatini oddiy to'xtatib-qayta-ishga-tushiradi. Bu skript
REM Windows Task Scheduler orqali har kuni (soat ~05:00, tortish ishlari
REM boshlanishidan oldin) avtomatik chaqiriladi - profilaktik_restart_
REM ornatish.bat shuni ro'yxatga oladi.
REM
REM Nima uchun kerak: 2026-08-09/10'da tarozi_agent'ning o'zi (thread)
REM o'lmagan, lekin OS/drayver (COM port/USB) darajasida CHEKSIZ
REM bloklanib qolgan holat kuzatildi - process "Running" ko'rinardi,
REM lekin haqiqatda javob bermasdi, faqat kompyuterni qayta yoqish
REM yordam berdi. Shu bilan bir qatorda, tarozi_agent.py'ga endi ICHKI
REM watchdog ham qo'shildi (soglomlik belgisi 60 soniyadan ortiq
REM yangilanmasa, process o'zini o'zi majburan qayta ishga tushiradi -
REM qarang: _watchdog_kuzatuvchisi()). Bu kunlik restart esa - qo'shimcha,
REM ICHKI watchdog hali aniqlamagan (masalan asta-sekin resurs sizib
REM chiqishi kabi) muammolarning oldini oluvchi ikkinchi, mustaqil
REM himoya qatlami.

net stop TaroziAgent
timeout /t 3 /nobreak >nul
net start TaroziAgent
