"""
1-band: barcha /statistika/* va /telegram/kunlik FAQAT holat="tugallandi"
VA netto > 0 bo'lgan Olchov qatorlarini hisoblaydi (test/simulyator va
takroriy tara-only qatorlar statistikani buzmasin).

2-band: /statistika/grafik/kunlik -> X o'qi SOATLAR (00-23, 24 ustun);
/statistika/grafik/haftalik -> X o'qi KUNLAR (Dush-Yak, 7 ustun).
Oylik/mavsum grafik bucketing o'zgarmagan.

DIQQAT: statistika/telegram endpointlari mahsulotni QATTIQ id (1=Chigit,
2=Chiganoq, ...) bo'yicha ajratadi - shu sabab bu yerda mahsulot ATAYLAB
id=1 bilan yaratiladi (mahsulot_chigit fixture'i autoincrement tufayli
har xil id oladi).
"""
from datetime import datetime, timedelta

import pytest

from models import Hujjat, Olchov, HujjatHolati, Mahsulot
from utils import konditsion_hisobla


@pytest.fixture()
def chigit1(db_session):
    m = Mahsulot(id=1, nom="Chigit", konditsiya_bor=True, is_active=True)
    db_session.add(m)
    db_session.commit()
    return m


def _tugallangan_hujjat(db_session, mahsulot_id, netto, raqam,
                         created_at=None, holat=HujjatHolati.TUGALLANDI,
                         qoshimcha_olchovlar=None):
    """netto > 0 bo'lgan bitta Olchov qatori bilan hujjat. `qoshimcha_olchovlar`
    - qo'shimcha (masalan netto=None tara-only yoki netto<=0) qatorlar
    ro'yxati: [(tara, brutto, netto), ...]."""
    h = Hujjat(mahsulot_id=mahsulot_id, raqam=raqam, holat=holat,
                firma="Real Firma", shofyor="Real Shofyor",
                created_at=created_at or datetime.now())
    db_session.add(h)
    db_session.flush()
    if netto is not None:
        db_session.add(Olchov(
            hujjat_id=h.id, arava_raqam=1, tara=18000, brutto=18000 + netto,
            netto=netto, namlik=8.0, ifloslik=2.0,
            konditsion=konditsion_hisobla(netto, 8.0, 2.0)))
    for i, (t, b, n) in enumerate(qoshimcha_olchovlar or [], start=2):
        db_session.add(Olchov(hujjat_id=h.id, arava_raqam=i, tara=t, brutto=b, netto=n))
    db_session.commit()
    return h.id


# ---------- 1-band: netto > 0 filtri ----------

def test_netto_null_tara_only_qator_statistikani_buzmaydi(
        client, admin_headers, db_session, chigit1):
    # Bitta HAQIQIY o'lchov (netto=7000) + ikkita "shovqin" qator:
    #   - tara-only (netto=None) - simulyator/yarim o'lchov
    #   - netto=0 (bo'sh mashina, xato yozuv)
    _tugallangan_hujjat(
        db_session, chigit1.id, 7000, "NF-1",
        qoshimcha_olchovlar=[(18000, None, None), (18000, 18000, 0)])

    for yol in ["/statistika/kunlik", "/statistika/haftalik",
                "/statistika/oylik", "/statistika/mavsum"]:
        j = client.get(yol, headers=admin_headers).json()
        assert j["jami_tonnaj"] == 7.0, f"{yol}: faqat netto>0 qator hisoblanishi kerak"
        assert j["chigit"]["tonnaj"] == 7.0


def test_netto_null_hujjat_statistikaga_umuman_kirmaydi(
        client, admin_headers, db_session, chigit1):
    # Butun hujjatda birorta netto>0 qator yo'q -> statistikaga kirmasin
    _tugallangan_hujjat(db_session, chigit1.id, None, "NF-2",
                        qoshimcha_olchovlar=[(18000, None, None)])
    _tugallangan_hujjat(db_session, chigit1.id, 5000, "NF-3")

    j = client.get("/statistika/kunlik", headers=admin_headers).json()
    assert j["chigit"]["soni"] == 1  # faqat NF-3
    assert j["jami_tonnaj"] == 5.0


def test_jarayondagi_hujjat_grafik_va_telegramda_kirmaydi(
        client, admin_headers, db_session, chigit1):
    _tugallangan_hujjat(db_session, chigit1.id, 6000, "NF-TUG")
    _tugallangan_hujjat(db_session, chigit1.id, 4000, "NF-JAR",
                        holat=HujjatHolati.JARAYON)

    kunlik = client.get("/statistika/grafik/kunlik", headers=admin_headers).json()
    assert sum(b["jami"] for b in kunlik) == 1  # faqat tugallangan

    tg = client.get("/telegram/kunlik", headers=admin_headers).json()
    assert "6.0 t" in tg["xabar"]      # tugallangan
    assert "4.0 t" not in tg["xabar"]  # jarayondagi qo'shilmagan


def test_firmalar_haydovchilar_netto_filtri(
        client, admin_headers, db_session, chigit1):
    _tugallangan_hujjat(db_session, chigit1.id, 6000, "NF-FH-1",
                        qoshimcha_olchovlar=[(18000, None, None)])
    j_firma = client.get("/statistika/firmalar", headers=admin_headers).json()
    real = [f for f in j_firma["firmalar"] if f["nom"] == "Real Firma"]
    assert real and real[0]["jami_tonnaj"] == 6.0

    j_h = client.get("/statistika/haydovchilar", headers=admin_headers).json()
    real_h = [x for x in j_h["haydovchilar"] if x["nom"] == "Real Shofyor"]
    assert real_h and real_h[0]["jami_tonnaj"] == 6.0


# ---------- 2-band: grafik X o'qi ----------

def test_grafik_kunlik_soatlar_boyicha_24_ustun(
        client, admin_headers, db_session, chigit1):
    bugun = datetime.now()
    _tugallangan_hujjat(db_session, chigit1.id, 5000, "GK-9",
                        created_at=bugun.replace(hour=9, minute=15))
    _tugallangan_hujjat(db_session, chigit1.id, 6000, "GK-9b",
                        created_at=bugun.replace(hour=9, minute=50))
    _tugallangan_hujjat(db_session, chigit1.id, 7000, "GK-14",
                        created_at=bugun.replace(hour=14, minute=5))

    natija = client.get("/statistika/grafik/kunlik", headers=admin_headers).json()
    assert len(natija) == 24
    assert [b["soat"] for b in natija] == list(range(24))
    soat_map = {b["soat"]: b for b in natija}
    assert soat_map[9]["chigit"] == 2
    assert soat_map[9]["jami"] == 2
    assert soat_map[14]["chigit"] == 1
    assert soat_map[0]["chigit"] == 0


def test_grafik_haftalik_kunlar_boyicha_7_ustun(
        client, admin_headers, db_session, chigit1):
    bugun = datetime.now()
    hafta_boshi = (bugun - timedelta(days=bugun.weekday())).replace(
        hour=10, minute=0, second=0, microsecond=0)
    # Dushanba (isodow=1) va Chorshanba (isodow=3)
    _tugallangan_hujjat(db_session, chigit1.id, 5000, "GH-D",
                        created_at=hafta_boshi)
    _tugallangan_hujjat(db_session, chigit1.id, 6000, "GH-C",
                        created_at=hafta_boshi + timedelta(days=2))

    natija = client.get("/statistika/grafik/haftalik", headers=admin_headers).json()
    assert len(natija) == 7
    assert [b["kun_raqami"] for b in natija] == [1, 2, 3, 4, 5, 6, 7]
    kun_map = {b["kun_raqami"]: b for b in natija}
    assert kun_map[1]["chigit"] == 1  # Dushanba
    assert kun_map[3]["chigit"] == 1  # Chorshanba
    assert kun_map[2]["chigit"] == 0  # Seshanba


def test_grafik_oylik_mavsum_bucketing_ozgarmagan(client, admin_headers):
    """Oylik - "kun" maydonli kunlik buketlar; mavsum - "oy" maydonli
    oylik buketlar (o'zgartirilmadi)."""
    oylik = client.get("/statistika/grafik/oylik", headers=admin_headers).json()
    assert oylik and all("kun" in b and "soat" not in b for b in oylik)
    mavsum = client.get("/statistika/grafik/mavsum", headers=admin_headers).json()
    assert mavsum and all("oy" in b for b in mavsum)


def test_grafik_kunlik_netto_va_holat_filtri(
        client, admin_headers, db_session, chigit1):
    bugun = datetime.now()
    _tugallangan_hujjat(db_session, chigit1.id, 5000, "GKF-ok",
                        created_at=bugun.replace(hour=8))
    # netto=None -> hisoblanmasligi kerak
    _tugallangan_hujjat(db_session, chigit1.id, None, "GKF-null",
                        created_at=bugun.replace(hour=8),
                        qoshimcha_olchovlar=[(18000, None, None)])
    # jarayondagi -> hisoblanmasligi kerak
    _tugallangan_hujjat(db_session, chigit1.id, 9000, "GKF-jar",
                        created_at=bugun.replace(hour=8),
                        holat=HujjatHolati.JARAYON)

    natija = client.get("/statistika/grafik/kunlik", headers=admin_headers).json()
    assert {b["soat"]: b["chigit"] for b in natija}[8] == 1
