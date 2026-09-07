"""_serial_oquvchisi() ichidagi freym tahlili va KONSENSUS filtri sinovlari.

Bu qism - STX (0x02) + belgi + AYNAN 7 raqam regex, "ruxsat etilgan
baytlar" shovqin filtri, oxirgi 3 freymdan KAMIDA 2 tasi bir xil bo'lishi
sharti - real productionda (2026-09) shovqinli RS232 liniyasi tufayli
qayta yozilgan edi, ammo shu paytgacha testsiz qolgan.

Yondashuv: serial.Serial monkeypatch qilinadi - soxta port oldindan
belgilangan baytlarni qaytaradi va ro'yxat tugagach serial.SerialException
otadi (ichki o'qish sikli xavfsiz tugaydi); time.sleep esa _Stop bilan
tashqi `while True` siklini to'xtatadi. Shundan keyin yakuniy
_holat["ogirlik_kg"] tekshiriladi.
"""
import sys
from pathlib import Path

import pytest
import serial

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import tarozi_agent as ta


class _Stop(Exception):
    """time.sleep() o'rnini bosadi - tashqi `while True` siklini tark etish."""


def _soxta_serial(chunklar):
    """serial.Serial o'rnini bosuvchi kontekst-menejer klassi qaytaradi.
    `chunklar` - ser.read() ketma-ket qaytaradigan baytlar bloklari; ro'yxat
    tugagach serial.SerialException otiladi."""
    class _SoxtaSerial:
        def __init__(self, *a, **kw):
            self._navbat = list(chunklar)

        def __enter__(self):
            return self

        def __exit__(self, *a):
            return False

        def read(self, n=1):
            if not self._navbat:
                raise serial.SerialException("sinov: ma'lumot tugadi")
            return self._navbat.pop(0)

    return _SoxtaSerial


def _oqit(monkeypatch, chunklar, boluvchi=None):
    """Soxta port orqali _serial_oquvchisi()ni bir marta to'liq aylantiradi
    va yakuniy _holat["ogirlik_kg"]ni qaytaradi. Boshlang'ich qiymat -999.0
    (sentinel): agar u qaytsa - demak hech qanday konsensus qabul qilinmagan."""
    monkeypatch.setattr(ta.serial, "Serial", _soxta_serial(chunklar))

    def _uxlama(_soniya):
        raise _Stop()

    monkeypatch.setattr(ta.time, "sleep", _uxlama)
    if boluvchi is not None:
        monkeypatch.setattr(ta, "TAROZI_BOLUVCHI", boluvchi)

    ta._holatni_yangila(ogirlik_kg=-999.0, ulangan=False)
    with pytest.raises(_Stop):
        ta._serial_oquvchisi()
    return ta._holat["ogirlik_kg"]


F = b"\x02+0000800"   # +80.0 kg (TAROZI_BOLUVCHI=10 bilan)


def test_toliq_freym_oqiladi(monkeypatch):
    # 3 ta bir xil toza freym -> konsensus to'la, qiymat qabul qilinadi.
    assert _oqit(monkeypatch, [F, F, F]) == pytest.approx(80.0)


def test_bitta_yoki_ikkita_freym_yetarli_emas(monkeypatch):
    # Konsensus oynasi (3) to'lmaguncha qiymat yangilanmaydi.
    assert _oqit(monkeypatch, [F, F]) == pytest.approx(-999.0)


def test_shovqinli_anchor_baytlari_tashlab_yuboriladi(monkeypatch):
    # Freym atrofidagi buzuq anchorlar (\x09 \x03 \x12 \r \x9a \x1a) -
    # "ruxsat etilgan baytlar" filtri ularni olib tashlaydi, freym baribir
    # to'g'ri o'qiladi (real productionda anchor oxiri turlicha kelardi).
    shovqinli = b"\x09\x03" + F + b"\x12\r\x9a\x1a"
    assert _oqit(monkeypatch, [shovqinli, shovqinli, shovqinli]) == pytest.approx(80.0)


def test_notoliq_freym_qabul_qilinmaydi(monkeypatch):
    # 6 xonali "freym" (bitta raqam yo'qolgan) - regexga (7 raqam shart)
    # umuman mos kelmaydi, qiymat hech qachon yangilanmaydi.
    yarim = b"\x02+000080"
    assert _oqit(monkeypatch, [yarim, yarim, yarim, yarim]) == pytest.approx(-999.0)


def test_konsensus_2_uchdan_bilan_qabul_qilinadi(monkeypatch):
    # Oyna [800, 8000, 800] - 3 tadan 2 tasi bir xil -> 800 qabul qilinadi,
    # siljib ketgan yolg'iz 8000 e'tiborga olinmaydi.
    aralash = F + b"\x02+0008000" + F
    assert _oqit(monkeypatch, [aralash]) == pytest.approx(80.0)


def test_konsensus_yoq_bolsa_oxirgi_barqaror_qiymat_saqlanadi(monkeypatch):
    # Avval barqaror 800 (3/3), keyin uchta har xil o'qish (700/600/500) ->
    # yangi 2/3 ko'pchilik yo'q, oxirgi qabul qilingan 80.0 saqlanib qoladi.
    barqaror = F + F + F
    turlicha = b"\x02+0000700\x02+0000600\x02+0000500"
    assert _oqit(monkeypatch, [barqaror, turlicha]) == pytest.approx(80.0)


def test_manfiy_qiymat(monkeypatch):
    m = b"\x02-0000500"   # -50.0 kg
    assert _oqit(monkeypatch, [m, m, m]) == pytest.approx(-50.0)


def test_boluvchi_qiymatni_masshtablaydi(monkeypatch):
    # TAROZI_BOLUVCHI=100 (indikator 0.01 kg birligida) -> "0008000" = 80.0 kg.
    fr = b"\x02+0008000"
    assert _oqit(monkeypatch, [fr, fr, fr], boluvchi=100.0) == pytest.approx(80.0)
