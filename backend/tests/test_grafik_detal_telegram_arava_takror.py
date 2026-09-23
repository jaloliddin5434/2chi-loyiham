"""
GET /statistika/grafik-detal/{kunlik,haftalik,oylik,mavsum} va
GET /telegram/kunlik - avval bu 5 endpointda ham TO'G'RIDAN-TO'G'RI
func.sum(Olchov.netto)/func.sum(Olchov.konditsion) ishlatilgan edi -
xuddi /statistika/firmalar, /statistika/haydovchilar va
/moliyaviy/hisobotdagi eski xatoga o'xshab, bitta arava uchun bir nechta
Olchov qatori bo'lsa (masalan qayta o'lchash/tuzatish natijasida,
ikkalasi ham netto>0) ikki marta hisoblanardi.

Bu fayl main.py'dagi _hujjatlar_guruh_boyicha_jamlangan() orqali
tuzatilgan hisoblashni shu 5 endpoint orqali sinaydi - har birida bitta
arava_raqam=1 uchun IKKITA netto>0 qator (4000 va keyin 5000) beriladi,
faqat ENG OXIRGI qiymat (5000 kg = 5.0 t) hisoblanishi kerak, 9000
(ikkalasi qo'shilib) EMAS.
"""
from datetime import datetime, timedelta

import pytest

from models import Hujjat, Olchov, HujjatHolati, Mahsulot


@pytest.fixture()
def chigit1(db_session):
    """/telegram/kunlik mahsulotni QATTIQ id (1=Chigit) bo'yicha ajratadi -
    shu sabab bu yerda mahsulot ATAYLAB id=1 bilan yaratiladi (xuddi
    test_statistika_netto_va_grafik.py'dagi kabi)."""
    m = Mahsulot(id=1, nom="Chigit", konditsiya_bor=True, is_active=True)
    db_session.add(m)
    db_session.commit()
    return m


def _hujjat_yarat(db_session, mahsulot_id, raqam, created_at):
    h = Hujjat(mahsulot_id=mahsulot_id, raqam=raqam, holat=HujjatHolati.TUGALLANDI,
               firma="Real Firma", shofyor="Real Shofyor", created_at=created_at)
    db_session.add(h)
    db_session.flush()
    return h


def _olchov_qosh(db_session, hujjat_id, arava_raqam, tara, brutto, netto):
    db_session.add(Olchov(hujjat_id=hujjat_id, arava_raqam=arava_raqam,
                           tara=tara, brutto=brutto, netto=netto))
    db_session.commit()


def _ikkita_netto_qatorli_hujjat(db_session, mahsulot_id, raqam, created_at):
    """Bitta arava_raqam=1 uchun IKKITA qator, ikkalasida ham netto>0
    (masalan qayta o'lchash) - ikkalasi ham Olchov.netto>0 filtridan
    o'tadi, shu sabab xom SQL SUM ularni QO'SHIB YUBORARDI (4000+5000=
    9000). To'g'ri natija faqat ENG OXIRGI (id bo'yicha) qiymat - 5000 kg
    = 5.0 t bo'lishi kerak."""
    h = _hujjat_yarat(db_session, mahsulot_id, raqam, created_at)
    _olchov_qosh(db_session, h.id, 1, 18000, 22000, 4000)
    _olchov_qosh(db_session, h.id, 1, 18000, 23000, 5000)
    return h.id


# ---------- /statistika/grafik-detal/* ----------

def test_grafik_detal_kunlik_arava_takror_hisoblanmaydi(
        client, admin_headers, db_session, mahsulot_chigit):
    bugun = datetime.now()
    _ikkita_netto_qatorli_hujjat(
        db_session, mahsulot_chigit.id, "GDK-1",
        bugun.replace(hour=9, minute=0, second=0, microsecond=0))

    natija = client.get(
        f"/statistika/grafik-detal/kunlik?mahsulot={mahsulot_chigit.nom}",
        headers=admin_headers).json()
    soat9 = next(b for b in natija if b["soat"] == 9)
    assert soat9["tonnaj"] == 5.0
    assert soat9["soni"] == 1


def test_grafik_detal_haftalik_arava_takror_hisoblanmaydi(
        client, admin_headers, db_session, mahsulot_chigit):
    bugun = datetime.now()
    hafta_boshi = (bugun - timedelta(days=bugun.weekday())).replace(
        hour=10, minute=0, second=0, microsecond=0)
    _ikkita_netto_qatorli_hujjat(db_session, mahsulot_chigit.id, "GDH-1", hafta_boshi)

    natija = client.get(
        f"/statistika/grafik-detal/haftalik?mahsulot={mahsulot_chigit.nom}",
        headers=admin_headers).json()
    dushanba = next(b for b in natija if b["kun_raqami"] == 1)
    assert dushanba["tonnaj"] == 5.0
    assert dushanba["soni"] == 1


def test_grafik_detal_oylik_arava_takror_hisoblanmaydi(
        client, admin_headers, db_session, mahsulot_chigit):
    bugun = datetime.now()
    oy_boshi_kun = bugun.replace(day=1, hour=10, minute=0, second=0, microsecond=0)
    _ikkita_netto_qatorli_hujjat(db_session, mahsulot_chigit.id, "GDO-1", oy_boshi_kun)

    natija = client.get(
        f"/statistika/grafik-detal/oylik?mahsulot={mahsulot_chigit.nom}",
        headers=admin_headers).json()
    birinchi_kun = next(b for b in natija if b["kun"] == 1)
    assert birinchi_kun["tonnaj"] == 5.0
    assert birinchi_kun["soni"] == 1


def test_grafik_detal_mavsum_arava_takror_hisoblanmaydi(
        client, admin_headers, db_session, mahsulot_chigit):
    bugun = datetime.now()
    _ikkita_netto_qatorli_hujjat(db_session, mahsulot_chigit.id, "GDM-1", bugun)

    natija = client.get(
        f"/statistika/grafik-detal/mavsum?mahsulot={mahsulot_chigit.nom}",
        headers=admin_headers).json()
    joriy_oy = next(b for b in natija if b["oy"] == bugun.month and b["yil"] == bugun.year)
    assert joriy_oy["tonnaj"] == 5.0
    assert joriy_oy["soni"] == 1


def test_grafik_detal_kunlik_ikkita_haqiqiy_arava_togri_qoshiladi(
        client, admin_headers, db_session, mahsulot_chigit):
    """Ikki xil arava_raqam (haqiqiy ikki arava) - bular takrorlanish
    EMAS, ikkalasi ham yig'indiga qo'shilishi kerak (tuzatish
    UNDER-count qilib qo'ymasligi kerak)."""
    bugun = datetime.now()
    h = _hujjat_yarat(db_session, mahsulot_chigit.id, "GDK-2ARAVA",
                       bugun.replace(hour=11, minute=0, second=0, microsecond=0))
    _olchov_qosh(db_session, h.id, 1, 18000, 23000, 5000)
    _olchov_qosh(db_session, h.id, 2, 17000, 21000, 4000)

    natija = client.get(
        f"/statistika/grafik-detal/kunlik?mahsulot={mahsulot_chigit.nom}",
        headers=admin_headers).json()
    soat11 = next(b for b in natija if b["soat"] == 11)
    assert soat11["tonnaj"] == 9.0
    assert soat11["soni"] == 1


# ---------- /telegram/kunlik ----------

def test_telegram_kunlik_bugun_qismi_arava_takror_hisoblanmaydi(
        client, admin_headers, db_session, chigit1):
    _ikkita_netto_qatorli_hujjat(db_session, chigit1.id, "TGK-1", datetime.now())

    natija = client.get("/telegram/kunlik", headers=admin_headers).json()
    assert "Netto: <b>5.0 t</b>" in natija["xabar"]
    assert "9.0 t" not in natija["xabar"]


def test_telegram_kunlik_mavsum_qismi_arava_takror_hisoblanmaydi(
        client, admin_headers, db_session, chigit1):
    """"MAVSUM JAMI" qismi ham (bugungi hujjat joriy mavsum ichida
    bo'lgani uchun) shu hujjatni o'z ichiga oladi - u ham ikki marta
    hisoblanmasligi kerak."""
    _ikkita_netto_qatorli_hujjat(db_session, chigit1.id, "TGK-2", datetime.now())

    natija = client.get("/telegram/kunlik", headers=admin_headers).json()
    assert "Chigit: 1 ta | 5.0 t" in natija["xabar"]
    assert "9.0 t" not in natija["xabar"]
