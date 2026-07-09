@echo off
cd C:\hazorasp_tarozi\backend
start "Backend" cmd /k "uvicorn main:app --host 0.0.0.0 --port 8001"
timeout /t 3
cd C:\hazorasp_tarozi\frontend\build\web
start "WebServer" cmd /k "python -m http.server 8080"