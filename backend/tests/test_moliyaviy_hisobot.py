"""
GET /moliyaviy/hisobot - moliyaviy tokensiz kirish rad etilishi,
mahsulot turiga qarab formula (Chigit->konditsion, boshqalar->netto),
va narx tarixi to'g'ri (eski hujjat eski narxda) qo'llanilishi.

DIQQAT: bu fayldagi testlar hujjatni "tugallandi" holatiga o'tkazadi -
main.py bu paytda HAQIQIY diskka (C:/RASMLAR/hisobot_*.xlsx) Excel
yozadi (excel_qatorga_yoz()), FAYL NOMI mahsulot NOMI matn satriga
asoslangan (ID emas!) - agar test mahsuloti nomi ("Chigit", "Chiganoq")
haqiqiy production mahsulotlari bilan bir xil bo'lsa, bu HAQIQIY,
ishlab turgan jurnal faylini test ma'lumotlari bilan ustidan yozib
yuborishi mumkin (buni bir marta boshdan kechirdik). Shu sabab bu
funksiya BUTUN FAYL uchun (autouse) monkeypatch bilan zararsizlantirilgan.
"""
import pytest
from utils import konditsion_hisobla


@pytest.fixture(autouse=True)
def _excel_yozishni_ochirish(monkeypatch):
    monkeypatch.setattr("main.excel_qatorga_yoz", lambda hujjat_id, db: None)


def _hujjat_tugallash(client, headers, mahsulot_id, mashina_id, tara, brutto,
                       namlik=None, ifloslik=None):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_id, "mashina_id": mashina_id,
    }, headers=headers)
    hujjat = javob.json()
    olchov_payload = {"hujjat_id": hujjat["id"], "arava_raqam": 1, "tara": tara, "brutto": brutto}
    if namlik is not None:
        olchov_payload["namlik"] = namlik
    if ifloslik is not None:
        olchov_payload["ifloslik"] = ifloslik
    client.post("/olchovlar", json=olchov_payload, headers=headers)
    client.put(f"/hujjatlar/{hujjat['id']}", json={
        "holat": "tugallandi", "sabab": "Test",
    }, headers=headers)
    return hujjat


def test_moliyaviy_tokensiz_hisobot_rad_etiladi(client, admin_headers):
    javob = client.get("/moliyaviy/hisobot?davr=kunlik", headers=admin_headers)
    assert javob.status_code == 403


def test_operator_moliyaviy_hisobotga_kira_olmaydi(client, operator_headers):
    javob = client.get("/moliyaviy/hisobot?davr=kunlik", headers=operator_headers)
    assert javob.status_code == 403


def test_chigit_konditsion_asosida_hisoblanadi(
        client, admin_headers, moliyaviy_headers, mahsulot_chigit, mashina):
    client.post(f"/mahsulotlar/{mahsulot_chigit.id}/narx", json={"narx": 5000},
                headers=moliyaviy_headers)
    _hujjat_tugallash(client, admin_headers, mahsulot_chigit.id, mashina.id,
                       tara=1000, brutto=3000, namlik=5.0, ifloslik=3.0)

    javob = client.get("/moliyaviy/hisobot?davr=kunlik", headers=moliyaviy_headers)
    assert javob.status_code == 200
    natija = javob.json()
    chigit = next(m for m in natija["mahsulotlar"] if m["mahsulot_id"] == mahsulot_chigit.id)
    assert chigit["asos"] == "konditsion"

    kutilgan_konditsion = konditsion_hisobla(2000, 5.0, 3.0)  # netto=3000-1000
    assert chigit["jami_kg"] == pytest.approx(kutilgan_konditsion, rel=1e-3)
    assert chigit["daromad"] == pytest.approx(kutilgan_konditsion * 5000, rel=1e-3)


def test_chiganoq_netto_asosida_hisoblanadi(
        client, admin_headers, moliyaviy_headers, mahsulot_chiganoq, mashina):
    client.post(f"/mahsulotlar/{mahsulot_chiganoq.id}/narx", json={"narx": 2000},
                headers=moliyaviy_headers)
    _hujjat_tugallash(client, admin_headers, mahsulot_chiganoq.id, mashina.id,
                       tara=1000, brutto=4000)  # namlik/ifloslik yo'q - konditsion yo'q

    javob = client.get("/moliyaviy/hisobot?davr=kunlik", headers=moliyaviy_headers)
    natija = javob.json()
    chiganoq = next(m for m in natija["mahsulotlar"] if m["mahsulot_id"] == mahsulot_chiganoq.id)
    assert chiganoq["asos"] == "netto"
    assert chiganoq["jami_kg"] == pytest.approx(3000, rel=1e-3)  # netto = 4000-1000
    assert chiganoq["daromad"] == pytest.approx(3000 * 2000, rel=1e-3)


def test_bekor_qilingan_hujjat_hisobga_kirmaydi(
        client, admin_headers, moliyaviy_headers, mahsulot_chiganoq, mashina):
    client.post(f"/mahsulotlar/{mahsulot_chiganoq.id}/narx", json={"narx": 2000},
                headers=moliyaviy_headers)
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chiganoq.id, "mashina_id": mashina.id,
    }, headers=admin_headers)
    hujjat = javob.json()
    client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "tara": 1000, "brutto": 4000,
    }, headers=admin_headers)
    client.put(f"/hujjatlar/{hujjat['id']}", json={
        "holat": "bekor", "bekor_sabab": "Test bekor",
    }, headers=admin_headers)

    natija = client.get("/moliyaviy/hisobot?davr=kunlik", headers=moliyaviy_headers).json()
    assert not any(m["mahsulot_id"] == mahsulot_chiganoq.id for m in natija["mahsulotlar"])


def test_narx_tarixi_togri_qollaniladi(
        client, admin_headers, moliyaviy_headers, mahsulot_chiganoq, mashina, db_session):
    # DIQQAT: PostgreSQL'da func.now() BUTUN TRANZAKSIYA boshlangan
    # vaqtni qaytaradi (statement vaqtini emas) - bitta test bitta
    # tranzaksiyada ishlagani uchun (tez, izolyatsiyalangan testlar
    # strategiyasi), agar sanalarni qo'lda ajratmasak, shu testdagi
    # barcha yozuvlar BIR XIL vaqt bilan yaratilib qolardi (bu faqat
    # test strategiyasining chekovi - production'da har so'rov alohida
    # tranzaksiya, bu muammo bo'lmaydi). Shu sabab sanalarni aniq
    # belgilaymiz.
    from datetime import datetime, timedelta
    from models import MahsulotNarxi, Hujjat

    # DIQQAT: kichik (soatlik) farq ataylab tanlangan - kunlar bilan
    # orqaga surish "mavsum" chegarasini (1-avgust) kesib o'tib
    # ketishi mumkin edi (agar joriy sana avgust boshiga yaqin bo'lsa).
    erta = datetime.now() - timedelta(hours=5)
    kech = datetime.now() - timedelta(hours=2)

    # 1-narx (ESKI) - 10 kun oldin kuchga kirgan.
    narx1 = client.post(f"/mahsulotlar/{mahsulot_chiganoq.id}/narx", json={"narx": 1000},
                         headers=moliyaviy_headers).json()
    db_session.query(MahsulotNarxi).filter(MahsulotNarxi.id == narx1["id"]).update(
        {"created_at": erta})

    # 1-hujjat - eski narx kuchda bo'lgan paytda yaratilgan.
    hujjat1 = _hujjat_tugallash(client, admin_headers, mahsulot_chiganoq.id, mashina.id,
                                 tara=1000, brutto=2000)  # netto=1000
    db_session.query(Hujjat).filter(Hujjat.id == hujjat1["id"]).update(
        {"created_at": erta + timedelta(hours=1)})

    # 2-narx (YANGI) - 1 kun oldin kuchga kirgan.
    narx2 = client.post(f"/mahsulotlar/{mahsulot_chiganoq.id}/narx", json={"narx": 3000},
                         headers=moliyaviy_headers).json()
    db_session.query(MahsulotNarxi).filter(MahsulotNarxi.id == narx2["id"]).update(
        {"created_at": kech})

    # 2-hujjat - yangi narx kuchga kirgandan keyin yaratilgan.
    hujjat2 = _hujjat_tugallash(client, admin_headers, mahsulot_chiganoq.id, mashina.id,
                                 tara=1000, brutto=3000)  # netto=2000
    db_session.query(Hujjat).filter(Hujjat.id == hujjat2["id"]).update(
        {"created_at": kech + timedelta(hours=1)})
    db_session.flush()

    # "kunlik" bu ikkalasini ham qamramaydi (10 kun/1 kun oldin) -
    # "mavsum" (avgust-iyul) ikkalasini ham qamrab oladi.
    natija = client.get("/moliyaviy/hisobot?davr=mavsum", headers=moliyaviy_headers).json()
    chiganoq = next(m for m in natija["mahsulotlar"] if m["mahsulot_id"] == mahsulot_chiganoq.id)
    # 1-hujjat: 1000kg * 1000 so'm (ESKI narx) = 1_000_000
    # 2-hujjat: 2000kg * 3000 so'm (YANGI narx) = 6_000_000
    # Jami: 7_000_000 (HAR IKKISI ham "yangi" 3000 narxda EMAS - bu 9_000_000 bo'lardi!)
    assert chiganoq["jami_kg"] == pytest.approx(3000, rel=1e-3)
    assert chiganoq["daromad"] == pytest.approx(7_000_000, rel=1e-3)


def test_narxsiz_davr_uchun_hujjat_daromadga_kiritilmaydi(
        client, admin_headers, moliyaviy_headers, mahsulot_chiganoq, mashina):
    # Hech qanday narx o'rnatilmagan holda hujjat tugallanadi.
    _hujjat_tugallash(client, admin_headers, mahsulot_chiganoq.id, mashina.id,
                       tara=1000, brutto=2000)

    natija = client.get("/moliyaviy/hisobot?davr=kunlik", headers=moliyaviy_headers).json()
    chiganoq = next(m for m in natija["mahsulotlar"] if m["mahsulot_id"] == mahsulot_chiganoq.id)
    assert chiganoq["daromad"] == 0
    assert chiganoq["narxsiz_hujjatlar_soni"] == 1


def test_notogri_davr_rad_etiladi(client, moliyaviy_headers):
    javob = client.get("/moliyaviy/hisobot?davr=notogri", headers=moliyaviy_headers)
    assert javob.status_code == 400


def test_narx_qoshish_moliyaviy_token_talab_qiladi(client, admin_headers, mahsulot_chigit):
    javob = client.post(f"/mahsulotlar/{mahsulot_chigit.id}/narx", json={"narx": 5000},
                         headers=admin_headers)
    assert javob.status_code == 403


def test_manfiy_narx_rad_etiladi(client, moliyaviy_headers, mahsulot_chigit):
    javob = client.post(f"/mahsulotlar/{mahsulot_chigit.id}/narx", json={"narx": -100},
                         headers=moliyaviy_headers)
    assert javob.status_code == 422
