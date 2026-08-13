"""Tarozi agenti - tarozixonadagi kompyuterda ishlaydi.

KLAS XK3190-A9+ tarozisini RS232/COM port orqali o'qiydi va o'qigan
qiymatni tarmoq orqali (HTTP POST) ofisdagi asosiy serverga yuboradi.
Asosiy server (backend/main.py) bilan bir xil jismoniy kompyuterda EMAS -
shuning uchun bu mustaqil, alohida dastur: backenddan hech narsa import
qilmaydi, faqat tarmoq orqali gaplashadi.
"""
import os
import re
import socket
import threading
import time
from pathlib import Path

import requests
import serial
import urllib3.util.connection as _urllib3_ulanish
from dotenv import load_dotenv
from requests.adapters import HTTPAdapter

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

# ============ FAQAT IPv4 (Windows IPv6'ni o'chirish YETARLI BO'LMADI) ============
# Real productionda (2026-08-13, tarozixona kompyuteri) SERVER_URL domen
# orqali (Cloudflare Tunnel, masalan api.smart-tarozi.uz) ishlaydi, shuning
# uchun har bir so'rovda DNS orqali IPv4 VA IPv6 manzillar qaytishi mumkin.
# urllib3 esa DNSdan qaytgan BIRINCHI manzilni sinab ko'radi - agar u IPv6
# bo'lsa-yu, tarmoq/marshrutlash IPv6'ni to'liq qo'llab-quvvatlamasa, ulanish
# osilib qolib "Read timed out" bilan tugaydi. Windows tarmoq sozlamalarida
# IPv6'ni o'chirish BU HOLATNI TUZATMADI (ilova baribir IPv6 manzilini sinab
# ko'raverdi). Shu sabab bu yerda kodning O'ZIDA, Windows sozlamalaridan
# MUSTAQIL ravishda kafolatlanadi: urllib3'ning DNS oila tanlovini
# (`allowed_gai_family`) faqat AF_INET'ga qulflovchi maxsus HTTPAdapter
# yaratilib, BARCHA so'rovlar (serverga ham, Telegramga ham) shu orqali
# yuboriladi - hech qachon IPv6 sinalmaydi.
def _faqat_ipv4_gai_oilasi():
    return socket.AF_INET


class _IPv4HTTPAdapter(HTTPAdapter):
    """Ushbu adapter mount qilingan `requests.Session` orqali yuborilgan
    HAR BIR so'rov (HTTP ham, HTTPS ham) faqat IPv4 orqali ulanadi."""

    def __init__(self, *args, **kwargs):
        _urllib3_ulanish.allowed_gai_family = _faqat_ipv4_gai_oilasi
        super().__init__(*args, **kwargs)


_ipv4_sessiyasi = requests.Session()
_ipv4_sessiyasi.mount("https://", _IPv4HTTPAdapter())
_ipv4_sessiyasi.mount("http://", _IPv4HTTPAdapter())

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
        javob = _ipv4_sessiyasi.post(
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


# ============ MUZLAB QOLISHNI KUZATUVCHI (watchdog) ============
# _serial_oquvchisi()dagi keng `except Exception` FAQAT haqiqiy istisnolarni
# (xato chiqishini) ushlaydi. Ba'zi USB-RS232 perexodniklar (ayniqsa CH340
# chipli arzon qurilmalar, sanoat muhitidagi elektr shovqinida) drayver
# darajasida CHEKSIZ BLOKLANIB (hang) qolishi mumkin - bu istisno EMAS,
# `serial.Serial(...)` yoki `ser.read()` chaqiruvi shunchaki HECH QACHON
# qaytmaydi, try/except buni umuman ko'ra olmaydi. Real productionda
# (2026-08-09/10) aynan shu holat yuz berdi - xizmat "Running" ko'rinsa
# ham, tarozi ma'lumoti soatlab kelmadi, faqat butun kompyuterni qayta
# yoqish yordam berdi.
#
# Bu watchdog _serial_oquvchisi() qancha vaqtdan beri "faol" ekanini
# (muvaffaqiyatli o'qishmi, oddiy xatomi - farqi yo'q, HAR sikl
# aylanishida) kuzatadi. Agar juda uzoq (oddiy holatda soniyalar ichida
# yangilanishi kerak bo'lgan belgi, _MUZLAB_QOLISH_CHEGARA_SONIYA dan
# ko'p) yangilanmasa - bu chaqiruvning o'zi qayerdadir abadiy bloklanib
# qolganidan darak beradi. Shunda butun jarayon MAJBURAN to'xtatiladi
# (`os._exit`) - NSSM (allaqachon `AppExit=Restart` bilan sozlangan,
# qarang: install_service.bat) uni darhol qayta ko'taradi - bu OS
# darajasida COM tutqichini to'liq yopib-ochishga majburlaydi (garchi
# 100% kafolat bermasa ham - agar aynan operatsion tizim/drayverning
# o'zi chalkashib qolgan bo'lsa, baribir jismoniy aralashuv kerak
# bo'lishi mumkin).
_soglomlik_qulf = threading.Lock()
_soglomlik_holati = {"oxirgi_faollik": time.time()}
_MUZLAB_QOLISH_CHEGARA_SONIYA = 60
_WATCHDOG_TEKSHIRUV_OSIYA = 15


def _soglomlik_belgisini_yangila():
    with _soglomlik_qulf:
        _soglomlik_holati["oxirgi_faollik"] = time.time()


def _watchdog_bir_tekshiruv():
    """Bitta tekshiruv sikli - alohida funksiya qilib ajratilgan, shunda
    sinovlarda `while True`/`time.sleep`ga va haqiqiy `os._exit()`ga
    tegmasdan to'g'ridan-to'g'ri chaqirish mumkin (`os._exit` sinovlarda
    monkeypatch qilinadi)."""
    with _soglomlik_qulf:
        oxirgi = _soglomlik_holati["oxirgi_faollik"]
    muddat_otdi = time.time() - oxirgi
    if muddat_otdi > _MUZLAB_QOLISH_CHEGARA_SONIYA:
        # DIQQAT: konsol/log (NSSM'ning agent_stdout.log'i) uchun ATAYLAB
        # emojisiz, faqat ASCII matn ishlatiladi - real sinovda aniqlandi:
        # ba'zi Windows konsollari/log kodировkalari (masalan cp1251)
        # emojini o'z ichiga olgan `print()`ni UnicodeEncodeError bilan
        # QULATIB QO'YADI. Bu ESA aynan shu watchdog thread'ining o'zini
        # o'ldirib qo'yar edi - ya'ni muzlab qolishni aniqlagan payti,
        # reaksiya berishdan OLDIN qulab, hech narsa qilolmay qolardi
        # (ironik, lekin haqiqiy xato - shu funksiyaning o'zini sinashda
        # topilgan). Telegram xabari HTTP JSON orqali yuboriladi - konsol
        # kodировkasiga bog'liq emas, shu sabab u yerda emoji xavfsiz.
        log_xabar = (
            f"DIQQAT: Tarozi agentining o'quvchi qismi {int(muddat_otdi)} "
            f"soniyadan buyon javob bermayapti (drayver/COM port darajasida "
            f"muzlab qolgan bo'lishi mumkin) - jarayon avtomatik qayta "
            f"ishga tushirilmoqda."
        )
        telegram_xabar = (
            f"🔴 <b>Diqqat!</b> Tarozi agentining o'quvchi qismi "
            f"{int(muddat_otdi)} soniyadan buyon javob bermayapti (drayver/"
            f"COM port darajasida muzlab qolgan bo'lishi mumkin) - jarayon "
            f"avtomatik qayta ishga tushirilmoqda."
        )
        print(log_xabar)
        _telegram_xabar_yuborish(telegram_xabar)
        os._exit(1)


def _watchdog_kuzatuvchisi():
    while True:
        time.sleep(_WATCHDOG_TEKSHIRUV_OSIYA)
        _watchdog_bir_tekshiruv()


def _serial_oquvchisi():
    """COM portini fon oqimida uzluksiz o'qiydi. Port ochilmasa yoki aloqa
    uzilib qolsa, 3 soniyadan keyin avtomatik qayta urinadi - agent process
    ishlashda davom etadi, faqat holat 'ulangan: false' bo'lib qoladi."""
    buffer = bytearray()
    oldingi_erkin_nomzod = None
    while True:
        # Har OUTER (qayta ulanish) va INNER (o'qish) sikl aylanishida
        # sog'lomlik belgisi yangilanadi - qarang: _watchdog_bir_tekshiruv().
        # Agar `serial.Serial(...)`ning o'zi (portni ochish) yoki `ser.read()`
        # drayver darajasida CHEKSIZ bloklanib qolsa (bu try/except
        # ushlay OLMAYDIGAN holat - chaqiruv oddiy hech qachon qaytmaydi),
        # belgi yangilanishni to'xtatadi va watchdog buni aniqlaydi.
        _soglomlik_belgisini_yangila()
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
                    _soglomlik_belgisini_yangila()
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
    sessiya = _ipv4_sessiyasi
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
    threading.Thread(target=_watchdog_kuzatuvchisi, daemon=True).start()
    _serverga_yuboruvchi()  # asosiy thread shu yerda "abadiy" qoladi


if __name__ == "__main__":
    main()
