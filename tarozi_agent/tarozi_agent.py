"""Tarozi agenti - tarozixonadagi kompyuterda ishlaydi.

KLAS XK3190-A9+ tarozisini RS232/COM port orqali o'qiydi va o'qigan
qiymatni tarmoq orqali (HTTP POST) ofisdagi asosiy serverga yuboradi.
Asosiy server (backend/main.py) bilan bir xil jismoniy kompyuterda EMAS -
shuning uchun bu mustaqil, alohida dastur: backenddan hech narsa import
qilmaydi, faqat tarmoq orqali gaplashadi.
"""
import os
import re
import threading
import time
from pathlib import Path

import requests
import serial
from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent / ".env")

TAROZI_PORT = os.getenv("TAROZI_PORT", "COM7")
TAROZI_BAUD = int(os.getenv("TAROZI_BAUD", "9600"))
SERVER_URL = os.getenv("SERVER_URL", "http://10.112.30.77:47001").rstrip("/")
TAROZI_AGENT_KEY = os.getenv("TAROZI_AGENT_KEY", "")
YUBORISH_INTERVAL_SONIYA = float(os.getenv("YUBORISH_INTERVAL_SONIYA", "0.5"))

# Bular MUSTAQIL ogohlantirish uchun - backend/.envdagi bilan BIR XIL
# Telegram bot/guruh (o'sha bitta bot barcha tizim xabarlarini yuboradi).
# Bu agent alohida, tarozixona kompyuterida ishlaydi - agar ofisdagi
# SERVER (yoki Cloudflare Tunnel) butunlay o'chib qolsa, backend ICHIDAGI
# hech qanday ogohlantirish ishlay olmaydi (o'lik jarayon xabar yubora
# olmaydi) - shu sabab bu ALOHIDA, mustaqil ogohlantirish shart.
TELEGRAM_TOKEN = os.getenv("TELEGRAM_TOKEN", "")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID", "")
TELEGRAM_ALERT_CHEGARA_SONIYA = float(os.getenv("TELEGRAM_ALERT_CHEGARA_SONIYA", "180"))

if not TAROZI_AGENT_KEY:
    raise RuntimeError(
        ".env faylida TAROZI_AGENT_KEY topilmadi! Serverdagi backend/.env "
        "faylidagi TAROZI_AGENT_KEY bilan bir xil qiymat bo'lishi shart."
    )

# To'liq freym (uzluksiz rejim): TAB + '+'/'-' belgisi + 7 xonali raqam
# (0.1 kg birligida, masalan "+0000100" = 10.0 kg) + DC2 + CR. Liniyada
# elektr shovqin bor - ba'zan TAB/DC2/CR anchor baytlari yo'qolib, faqat
# belgi+7-raqam qismi omon qoladi. Shu "qisqartirilgan" holatda shovqin
# tasodifan haqiqiy freymga o'xshab qolishi mumkin, shuning uchun u faqat
# KETMA-KET IKKI MARTA bir xil qiymat bilan uchraganda qabul qilinadi.
_TAROZI_FREYM_QATIY_RE = re.compile(rb"\x09([+\-])([0-9]{7})\x12\r")
_TAROZI_FREYM_ERKIN_RE = re.compile(rb"([+\-])([0-9]{7})")

_qulf = threading.Lock()
_holat = {"ogirlik_kg": 0.0, "ulangan": False}

# ============ MUSTAQIL TELEGRAM OGOHLANTIRISH (server bilan aloqa) ============
# Backenddagi shunga o'xshash mexanizmdan MUSTAQIL - bu yerda ATAYLAB
# backend/main.py'dan hech narsa import qilinmaydi, chunki aynan backend
# (yoki unga olib boruvchi tarmoq/Cloudflare Tunnel) o'lganda ham bu agent
# xabar bera olishi kerak.
_tg_holati = {"oxirgi_muvaffaqiyat": time.time(), "ogohlantirilgan": False}
_tg_holati_qulf = threading.Lock()


def _telegram_xabar_yuborish(matn: str) -> bool:
    if not TELEGRAM_TOKEN or not TELEGRAM_CHAT_ID:
        return False
    try:
        javob = requests.post(
            f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage",
            json={"chat_id": TELEGRAM_CHAT_ID, "text": matn, "parse_mode": "HTML"},
            timeout=5,
        )
        return javob.status_code == 200
    except requests.RequestException as e:
        print(f"Telegram xabar yuborib bo'lmadi: {e}")
        return False


def _server_aloqasi_holatini_yangila(muvaffaqiyat: bool):
    """Serverga har bir POST urinishidan keyin chaqiriladi. Agar
    TELEGRAM_ALERT_CHEGARA_SONIYA vaqtidan beri hech qanday muvaffaqiyatli
    POST bo'lmasa - bu server (yoki Cloudflare Tunnel, yoki butun tarmoq)
    ishlamayotganidan darak beradi - shunda MUSTAQIL, to'g'ridan-to'g'ri
    Telegram Bot API orqali (backend ORQALI EMAS) ogohlantirish yuboriladi."""
    yuboriladigan_matn = None
    with _tg_holati_qulf:
        if muvaffaqiyat:
            if _tg_holati["ogohlantirilgan"]:
                yuboriladigan_matn = (
                    "✅ Tarozi agenti serverga qayta ulandi "
                    f"({SERVER_URL})."
                )
            _tg_holati["oxirgi_muvaffaqiyat"] = time.time()
            _tg_holati["ogohlantirilgan"] = False
        else:
            muddat_otdi = time.time() - _tg_holati["oxirgi_muvaffaqiyat"]
            if (muddat_otdi > TELEGRAM_ALERT_CHEGARA_SONIYA
                    and not _tg_holati["ogohlantirilgan"]):
                _tg_holati["ogohlantirilgan"] = True
                yuboriladigan_matn = (
                    f"🔴 <b>Diqqat!</b> Tarozi agenti {int(muddat_otdi)} soniyadan "
                    f"buyon serverga ({SERVER_URL}) ulana olmayapti - server, "
                    f"Cloudflare Tunnel yoki tarmoqda muammo bo'lishi mumkin."
                )
    if yuboriladigan_matn:
        _telegram_xabar_yuborish(yuboriladigan_matn)


def _holatni_yangila(ogirlik_kg=None, ulangan=None):
    with _qulf:
        if ogirlik_kg is not None:
            _holat["ogirlik_kg"] = ogirlik_kg
        if ulangan is not None:
            _holat["ulangan"] = ulangan


def _serial_oquvchisi():
    """COM portini fon oqimida uzluksiz o'qiydi. Port ochilmasa yoki aloqa
    uzilib qolsa, 3 soniyadan keyin avtomatik qayta urinadi - agent process
    ishlashda davom etadi, faqat holat 'ulangan: false' bo'lib qoladi."""
    buffer = bytearray()
    oldingi_erkin_nomzod = None
    while True:
        try:
            with serial.Serial(
                TAROZI_PORT,
                baudrate=TAROZI_BAUD,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=0.2,
            ) as ser:
                _holatni_yangila(ulangan=True)
                buffer.clear()
                oldingi_erkin_nomzod = None
                print(f"Tarozi ({TAROZI_PORT}) bilan aloqa o'rnatildi.")
                while True:
                    chunk = ser.read(256)
                    if chunk:
                        buffer += chunk

                        qatiy_moslik = None
                        for qatiy_moslik in _TAROZI_FREYM_QATIY_RE.finditer(buffer):
                            pass

                        if qatiy_moslik:
                            ishora = -1 if qatiy_moslik.group(1) == b"-" else 1
                            ogirlik_kg = ishora * int(qatiy_moslik.group(2)) / 10
                            _holatni_yangila(ogirlik_kg=ogirlik_kg)
                            del buffer[: qatiy_moslik.end()]
                            oldingi_erkin_nomzod = None
                        else:
                            erkin_moslik = None
                            for erkin_moslik in _TAROZI_FREYM_ERKIN_RE.finditer(buffer):
                                pass
                            if erkin_moslik:
                                nomzod = (erkin_moslik.group(1), erkin_moslik.group(2))
                                if nomzod == oldingi_erkin_nomzod:
                                    ishora = -1 if nomzod[0] == b"-" else 1
                                    ogirlik_kg = ishora * int(nomzod[1]) / 10
                                    _holatni_yangila(ogirlik_kg=ogirlik_kg)
                                oldingi_erkin_nomzod = nomzod
                                del buffer[: erkin_moslik.end()]

                        if len(buffer) > 4096:
                            del buffer[:-64]
                            oldingi_erkin_nomzod = None
        except serial.SerialException as e:
            _holatni_yangila(ulangan=False)
            print(f"Tarozi ({TAROZI_PORT}) bilan aloqa yo'q: {e}")
        except Exception as e:
            # Kutilmagan xato turi (masalan ba'zi USB-RS232 adapterlarning
            # noyob drayver xatolari SerialException sifatida kelmasligi
            # mumkin). Buni ushlamasak, bu thread jimgina o'lib qoladi -
            # holat "muzlab qoladi" (hatto ulangan=true bo'lib qolishi
            # mumkin), garchi asosiy thread hali POST yuborishda davom
            # etaversa ham. Shu sabab bu yerda ATAYLAB keng `Exception`
            # ushlanadi - thread hech qachon o'lmasligi kerak.
            _holatni_yangila(ulangan=False)
            print(f"Tarozi o'quvchisida kutilmagan xato: {e}")
        time.sleep(3)


def _serverga_yuboruvchi():
    """Har YUBORISH_INTERVAL_SONIYA'da so'nggi holatni serverga POST qiladi
    (COM ulangan-ulanmaganidan qat'iy nazar - uzilgan holatni ham serverga
    darhol xabar qiladi). Tarmoq/server vaqtincha ishlamasa xatoni yutib,
    keyingi urinishda davom etadi - bu oqim hech qachon to'xtamasligi kerak."""
    sessiya = requests.Session()
    while True:
        with _qulf:
            payload = dict(_holat)
        try:
            javob = sessiya.post(
                f"{SERVER_URL}/tarozi/yubor",
                json=payload,
                headers={"X-Tarozi-Agent-Key": TAROZI_AGENT_KEY},
                timeout=3,
            )
            muvaffaqiyat = javob.status_code == 200
            if javob.status_code == 401:
                print("Serverga yuborilmadi: TAROZI_AGENT_KEY mos kelmayapti (401).")
        except requests.RequestException as e:
            muvaffaqiyat = False
            print(f"Serverga ({SERVER_URL}) yuborib bo'lmadi: {e}")
        _server_aloqasi_holatini_yangila(muvaffaqiyat)
        time.sleep(YUBORISH_INTERVAL_SONIYA)


def main():
    print(f"Tarozi agenti ishga tushdi. Port={TAROZI_PORT}@{TAROZI_BAUD}, Server={SERVER_URL}")
    threading.Thread(target=_serial_oquvchisi, daemon=True).start()
    _serverga_yuboruvchi()  # asosiy thread shu yerda "abadiy" qoladi


if __name__ == "__main__":
    main()
