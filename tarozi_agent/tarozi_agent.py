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
SERVER_URL = os.getenv("SERVER_URL", "http://10.112.30.77:8001").rstrip("/")
TAROZI_AGENT_KEY = os.getenv("TAROZI_AGENT_KEY", "")
YUBORISH_INTERVAL_SONIYA = float(os.getenv("YUBORISH_INTERVAL_SONIYA", "0.5"))

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
            if javob.status_code == 401:
                print("Serverga yuborilmadi: TAROZI_AGENT_KEY mos kelmayapti (401).")
        except requests.RequestException as e:
            print(f"Serverga ({SERVER_URL}) yuborib bo'lmadi: {e}")
        time.sleep(YUBORISH_INTERVAL_SONIYA)


def main():
    print(f"Tarozi agenti ishga tushdi. Port={TAROZI_PORT}@{TAROZI_BAUD}, Server={SERVER_URL}")
    threading.Thread(target=_serial_oquvchisi, daemon=True).start()
    _serverga_yuboruvchi()  # asosiy thread shu yerda "abadiy" qoladi


if __name__ == "__main__":
    main()
