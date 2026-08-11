@echo off
REM DIQQAT (2026-08-11): backend endi "HazoraspBackend" nomli Windows
REM xizmati sifatida ishlaydi (qarang: backend\install_service.bat) -
REM kompyuter yoqilganda AVTOMATIK ishga tushadi, Service Recovery
REM bilan. Shu skript ENDI backendni ishga TUSHIRMAYDI - aks holda
REM 47001 portida IKKINCHI, xizmatdan tashqari raqobatchi jarayon
REM paydo bo'lib qolar edi. Agar xizmat biror sababdan to'xtagan bo'lsa,
REM uni "net start HazoraspBackend" bilan ishga tushiring, bu skript
REM bilan EMAS.
cd C:\hazorasp_tarozi\frontend\build\web
start "WebServer" cmd /k "python -m http.server 47080"