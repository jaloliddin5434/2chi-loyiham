"""GET /statistika/firmalar va GET /statistika/haydovchilar - firma va
haydovchi boyicha jami hujjat/tonnaj hisoboti, sinov yozuvlarini
chiqarib tashlashi va davr filtri togri ishlashini tekshiradi."""
from datetime import datetime, timedelta

from models import Hujjat, Olchov, HujjatHolati
from utils import konditsion_hisobla


def _hujjat_qosh(db_session, mahsulot_id, firma, shofyor, tara, brutto,
                  namlik=8.0, ifloslik=2.0, created_at=None, raqam=None,
                  holat=HujjatHolati.TUGALLANDI):
    h = Hujjat(
        mahsulot_id=mahsulot_id,
        raqam=raqam or f"SINOV-{datetime.now().timestamp()}",
        firma=firma, shofyor=shofyor,
        holat=holat,
        created_at=created_at or datetime.now(),
    )
    db_session.add(h)
    db_session.flush()
    netto = brutto - tara
    konditsion = konditsion_hisobla(netto, namlik, ifloslik)
    db_session.add(Olchov(hujjat_id=h.id, arava_raqam=1, tara=tara, brutto=brutto,
                           netto=netto, namlik=namlik, ifloslik=ifloslik, konditsion=konditsion))
    db_session.commit()
    return h.id


def test_firmalar_statistika_asosiy_korsatkichlar(client, admin_headers, db_session, mahsulot_chigit):
    _hujjat_qosh(db_session, mahsulot_chigit.id, "Firma A", "Ali", 18000, 25000, raqam="FRM-A-1")
    _hujjat_qosh(db_session, mahsulot_chigit.id, "Firma A", "Vali", 18000, 24000, raqam="FRM-A-2")
    _hujjat_qosh(db_session, mahsulot_chigit.id, "Firma B", "Hasan", 18000, 20000, raqam="FRM-B-1")

    javob = client.get("/statistika/firmalar", headers=admin_headers)
    assert javob.status_code == 200
    natija = javob.json()["firmalar"]

    nomlar = {f["nom"]: f for f in natija}
    assert "Firma A" in nomlar and "Firma B" in nomlar
    assert nomlar["Firma A"]["soni"] == 2
    assert nomlar["Firma A"]["jami_tonnaj"] == round((7000 + 6000) / 1000, 2)
    # Eng kop tonnajli firma birinchi turishi kerak (Firma A > Firma B)
    assert natija[0]["nom"] == "Firma A"


def test_firmalar_statistika_sinov_firmalarini_chiqarib_tashlaydi(client, admin_headers, db_session, mahsulot_chigit):
    _hujjat_qosh(db_session, mahsulot_chigit.id, "Test Firma", "Sinov Odam", 18000, 25000, raqam="TF-1")
    _hujjat_qosh(db_session, mahsulot_chigit.id, "Sinov Firma", "Sinov Odam2", 18000, 25000, raqam="SF-1")
    _hujjat_qosh(db_session, mahsulot_chigit.id, "Haqiqiy Firma", "Real Odam", 18000, 25000, raqam="HQ-1")

    javob = client.get("/statistika/firmalar", headers=admin_headers)
    assert javob.status_code == 200
    nomlar = [f["nom"] for f in javob.json()["firmalar"]]

    assert "Test Firma" not in nomlar
    assert "Sinov Firma" not in nomlar
    assert "Haqiqiy Firma" in nomlar


def test_bosh_firma_royxatdan_chiqarib_tashlanadi(client, admin_headers, db_session, mahsulot_chigit):
    _hujjat_qosh(db_session, mahsulot_chigit.id, None, "Kimdir", 18000, 25000, raqam="BOSH-1")
    _hujjat_qosh(db_session, mahsulot_chigit.id, "", "Kimdir2", 18000, 25000, raqam="BOSH-2")

    javob = client.get("/statistika/firmalar", headers=admin_headers)
    assert javob.status_code == 200
    nomlar = [f["nom"] for f in javob.json()["firmalar"]]
    assert None not in nomlar
    assert "" not in nomlar


def test_haydovchilar_statistika_asosiy_korsatkichlar(client, admin_headers, db_session, mahsulot_chigit):
    _hujjat_qosh(db_session, mahsulot_chigit.id, "Firma X", "Eng Faol Haydovchi", 18000, 26000, raqam="HYD-1")
    _hujjat_qosh(db_session, mahsulot_chigit.id, "Firma X", "Eng Faol Haydovchi", 18000, 25000, raqam="HYD-2")
    _hujjat_qosh(db_session, mahsulot_chigit.id, "Firma X", "Kam Ishlagan", 18000, 19000, raqam="HYD-3")

    javob = client.get("/statistika/haydovchilar", headers=admin_headers)
    assert javob.status_code == 200
    natija = javob.json()["haydovchilar"]

    nomlar = {h["nom"]: h for h in natija}
    assert nomlar["Eng Faol Haydovchi"]["soni"] == 2
    assert natija[0]["nom"] == "Eng Faol Haydovchi"  # eng kop tonnaj birinchi


def test_davr_parametri_togri_filtrlaydi(client, admin_headers, db_session, mahsulot_chigit):
    kecha = datetime.now() - timedelta(days=1, hours=1)
    _hujjat_qosh(db_session, mahsulot_chigit.id, "Kechagi Firma", "Kim", 18000, 25000,
                 created_at=kecha, raqam="KECHA-1")

    kunlik = client.get("/statistika/firmalar?davr=kunlik", headers=admin_headers)
    haftalik = client.get("/statistika/firmalar?davr=haftalik", headers=admin_headers)

    kunlik_nomlar = [f["nom"] for f in kunlik.json()["firmalar"]]
    haftalik_nomlar = [f["nom"] for f in haftalik.json()["firmalar"]]

    assert "Kechagi Firma" not in kunlik_nomlar, "Kunlik hisobot kechagi yozuvni ham olib kelmasligi kerak edi"
    assert "Kechagi Firma" in haftalik_nomlar, "Haftalik hisobot kechagi yozuvni olib kelishi kerak edi"


def test_moliyaviy_ruxsat_talab_qilinmaydi_oddiy_operator_ham_kora_oladi(client, operator_headers, db_session, mahsulot_chigit):
    """Bu - moliyaviy (PIN-himoyalangan) hisobot emas, oddiy statistika -
    operator ham korishi mumkin bolishi kerak (mavjud /statistika/*
    endpointlari bilan bir xil xulq-atvor)."""
    javob = client.get("/statistika/firmalar", headers=operator_headers)
    assert javob.status_code == 200
    javob2 = client.get("/statistika/haydovchilar", headers=operator_headers)
    assert javob2.status_code == 200


def test_bekor_qilingan_hujjat_statistikaga_kirmaydi(client, admin_headers, db_session, mahsulot_chigit):
    """REAL production'da topilgan holat: bekor qilingan (BEKOR_QILINDI)
    hujjat firma/haydovchi tonnajiga qoshilib ketmasligi kerak - aks
    holda bekor qilingan buyurtma haqiqiy statistikani buzadi."""
    _hujjat_qosh(db_session, mahsulot_chigit.id, "Bekor Firma", "Bekor Haydovchi",
                 18000, 25000, raqam="BEKOR-1", holat=HujjatHolati.BEKOR_QILINDI)
    _hujjat_qosh(db_session, mahsulot_chigit.id, "Faol Firma", "Faol Haydovchi",
                 18000, 25000, raqam="FAOL-1")

    firmalar = client.get("/statistika/firmalar", headers=admin_headers).json()["firmalar"]
    haydovchilar = client.get("/statistika/haydovchilar", headers=admin_headers).json()["haydovchilar"]

    assert "Bekor Firma" not in [f["nom"] for f in firmalar]
    assert "Bekor Haydovchi" not in [h["nom"] for h in haydovchilar]
    assert "Faol Firma" in [f["nom"] for f in firmalar]
    assert "Faol Haydovchi" in [h["nom"] for h in haydovchilar]
