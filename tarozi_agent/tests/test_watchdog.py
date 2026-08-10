"""tarozi_agent.py'dagi watchdog (muzlab qolishni aniqlash) mexanizmini
sinaydi. Real productionda (2026-08-09/10) _serial_oquvchisi() thread'i
"o'lmasdan" (avvalgi audit tuzatishi hali ham ishlaydi), lekin OS/drayver
darajasida CHEKSIZ BLOKLANIB qolgan edi - bu try/except ushlay olmaydigan
holat, faqat kompyuterni qayta yoqish yordam bergan. Bu watchdog aynan
shu holatni (sog'lomlik belgisi juda uzoq yangilanmasa) aniqlab, jarayonni
o'zi majburan qayta ishga tushiradi.

_watchdog_bir_tekshiruv() ATAYLAB haqiqiy `os._exit()` chaqirmaydi (buni
sinovda ishlatsak, pytest jarayonining o'zi o'lib qolardi) - shu sabab
sinovlarda `os._exit` va Telegram chaqiruvi monkeypatch qilinadi, faqat
ULAR CHAQIRILDIMI/CHAQIRILMADIMI tekshiriladi."""
import sys
import time
import threading
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import tarozi_agent as ta


def test_yangi_belgi_muzlagan_deb_topilmaydi(monkeypatch):
    chaqirilgan_exit = []
    monkeypatch.setattr(ta.os, "_exit", lambda kod: chaqirilgan_exit.append(kod))

    ta._soglomlik_belgisini_yangila()
    ta._watchdog_bir_tekshiruv()

    assert chaqirilgan_exit == []


def test_chegaraning_ozidan_past_muzlagan_deb_topilmaydi(monkeypatch):
    chaqirilgan_exit = []
    monkeypatch.setattr(ta.os, "_exit", lambda kod: chaqirilgan_exit.append(kod))

    with ta._soglomlik_qulf:
        ta._soglomlik_holati["oxirgi_faollik"] = (
            time.time() - (ta._MUZLAB_QOLISH_CHEGARA_SONIYA - 5))
    ta._watchdog_bir_tekshiruv()

    assert chaqirilgan_exit == []


def test_eskirgan_belgida_exit_va_telegram_chaqiriladi(monkeypatch):
    """Asosiy stsenariy: sog'lomlik belgisi chegaradan ko'p eskirgan -
    jarayon o'zini majburan qayta ishga tushirishi (os._exit) va
    oldindan ogohlantirish yuborishi kerak."""
    chaqirilgan_exit = []
    yuborilgan_xabarlar = []
    monkeypatch.setattr(ta.os, "_exit", lambda kod: chaqirilgan_exit.append(kod))
    monkeypatch.setattr(
        ta, "_telegram_xabar_yuborish",
        lambda matn: (yuborilgan_xabarlar.append(matn), True)[1])

    with ta._soglomlik_qulf:
        ta._soglomlik_holati["oxirgi_faollik"] = (
            time.time() - (ta._MUZLAB_QOLISH_CHEGARA_SONIYA + 5))
    ta._watchdog_bir_tekshiruv()

    assert chaqirilgan_exit == [1]
    assert len(yuborilgan_xabarlar) == 1
    assert "javob bermayapti" in yuborilgan_xabarlar[0]


def test_konsolga_chiqariladigan_xabar_faqat_ascii(monkeypatch, capsys):
    """Real sinovda topilgan xato: agar log xabarida emoji (masalan
    'DIQQAT' belgisi) bo'lsa, ba'zi Windows konsol/log kodировkalari
    (masalan cp1251) buni chop etishda UnicodeEncodeError bilan
    QULAYDI - bu esa watchdog threadining O'ZINI, aynan reaksiya berish
    kerak bo'lgan paytda o'ldirib qo'yardi. Konsolga chiqadigan xabar
    ENDI faqat ASCII bo'lishi kerak (emoji faqat Telegram xabarida,
    HTTP JSON orqali, konsol kodировkasidan mustaqil ravishda)."""
    monkeypatch.setattr(ta.os, "_exit", lambda kod: None)
    monkeypatch.setattr(ta, "_telegram_xabar_yuborish", lambda matn: True)

    with ta._soglomlik_qulf:
        ta._soglomlik_holati["oxirgi_faollik"] = (
            time.time() - (ta._MUZLAB_QOLISH_CHEGARA_SONIYA + 5))
    ta._watchdog_bir_tekshiruv()

    chiqish = capsys.readouterr()
    # cp1251 kabi eski kodировkalar ham qamrab oladigan qattiq tekshiruv -
    # xabar HAQIQATAN faqat ASCII ekanini tasdiqlaydi (shunchaki
    # try/except bilan yashirilmagan).
    chiqish.out.encode("ascii")


def test_serial_oquvchisi_real_thread_belgini_muntazam_yangilaydi(monkeypatch):
    """_serial_oquvchisi()ning HAQIQIY (mock qilinmagan) nusxasini alohida
    thread'da, mavjud bo'lmagan COM portga (SerialException kutiladi -
    xavfsiz, haqiqiy uskuna kerak emas) ishga tushiradi va sog'lomlik
    belgisi haqiqatan muntazam yangilanib turishini tasdiqlaydi."""
    monkeypatch.setattr(ta, "TAROZI_PORT", "COM_MAVJUD_EMAS_SINOV_999")

    with ta._soglomlik_qulf:
        ta._soglomlik_holati["oxirgi_faollik"] = 0.0  # qasddan juda eski

    t = threading.Thread(target=ta._serial_oquvchisi, daemon=True)
    t.start()
    try:
        time.sleep(0.5)  # bir nechta (portni ochish muvaffaqiyatsiz) sikl uchun yetarli
        chaqirilgan_exit = []
        monkeypatch.setattr(ta.os, "_exit", lambda kod: chaqirilgan_exit.append(kod))
        ta._watchdog_bir_tekshiruv()
        assert chaqirilgan_exit == [], (
            "Real thread ishlab turganda watchdog uni 'muzlagan' deb "
            "topmasligi kerak edi - sog'lomlik belgisi yangilanib turishi kerak."
        )
    finally:
        # `t` daemon thread - pytest jarayoni tugaganda avtomatik tugaydi,
        # bu yerda qo'shimcha to'xtatish shart emas (COM_MAVJUD_EMAS_SINOV_999
        # hech qachon ochilmaydi, zararli yon ta'sir yo'q).
        pass
