@echo off
REM DIQQAT (2026-08-11): backend VA frontend endi ikkalasi ham Windows
REM xizmati sifatida ishlaydi ("HazoraspBackend" va "HazoraspFrontend" -
REM qarang: backend\install_service.bat, frontend\install_service.bat).
REM Kompyuter yoqilganda AVTOMATIK ishga tushadilar, Service Recovery
REM bilan (jarayon kutilmagan tarzda o'chsa, NSSM o'zi qayta ko'taradi).
REM
REM Shu skript ENDI HECH NARSANI ishga TUSHIRMAYDI - aks holda 47001/
REM 47080 portlarida IKKINCHI, xizmatdan tashqari raqobatchi jarayonlar
REM paydo bo'lib qolar edi.
REM
REM Xizmat holatini tekshirish uchun:
REM   sc query HazoraspBackend
REM   sc query HazoraspFrontend
REM Biror sababdan to'xtagan bo'lsa, qo'lda ishga tushirish uchun:
REM   net start HazoraspBackend
REM   net start HazoraspFrontend
echo Backend va frontend endi Windows xizmati sifatida ishlaydi -
echo bu skript orqali qo'lda ishga tushirish shart emas.
echo Holatni tekshirish: sc query HazoraspBackend ^&^& sc query HazoraspFrontend
