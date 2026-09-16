"""
Integratsiya testi: admin hujjatning firma nomini PUT /hujjatlar/{id}
orqali o'zgartirganda, bu o'zgarish operator ko'radigan BARCHA joylarda
(GET /hujjatlar/{id}, GET /navbat, nakladnoy) to'g'ri ko'rinishi kerak -
navbatda turgan paytda ham, tugallangandan keyin ham.

To'liq oqim:
1. Operator: yangi mashina yaratadi, hujjat ochadi, navbatga qo'shadi,
   TARA o'lchaydi (POST /mashinalar, /hujjatlar, /navbat/qosh, /olchovlar).
2. Admin: hujjatning firma nomini o'zgartiradi (PUT /hujjatlar/{id}).
3. Tekshiriladi: GET /hujjatlar/{id}, GET /navbat, nakladnoy sahifasi
   (GET /nakladnoy-korish/{token}) - hammasida yangi firma ko'rinishi kerak.
4. Operator BRUTTO ni ham o'lchaydi va navbatni tugatadi - shundan keyin
   ham GET /hujjatlar/{id}, GET /navbat/tugallanganlar va nakladnoy
   sahifasida yangi firma ko'rinishi tekshiriladi.

DIQQAT: bu loyihada alohida "GET /nakladnoy/{id}" endpointi yo'q - nakladnoy
faqat tasodifiy token bo'yicha ochiladi (GET /nakladnoy-korish/{token},
QR kod orqali). Haqiqiy PDF generatsiyasi (Playwright) bu yerda sinalmaydi -
xuddi test_nakladnoy_korish_xss.py'dagi kabi, tokenni to'g'ridan-to'g'ri
bazaga yozib, faqat HTML ko'rinish sahifasi tekshiriladi.
"""
import secrets

import pytest


@pytest.fixture(autouse=True)
def _excel_yozishni_ozarsizlantirish(monkeypatch):
    # Navbat tugatilganda (holat -> tugallandi) excel_qatorga_yoz_fon()
    # HAQIQIY diskka yozadi - test uchun zararsizlantiramiz (xuddi
    # test_hujjat_yangilash.py va test_hujjat_tugallandi_navbat_sync.py'dagi
    # kabi).
    monkeypatch.setattr("main.excel_qatorga_yoz", lambda hujjat_id, db: None)


def test_firma_ozgarishi_hujjat_navbat_va_nakladnoyda_yangilanadi(
        client, operator_headers, admin_headers, mahsulot_chigit, db_session):
    # ---------- 1) Operator: mashina, hujjat, navbat, TARA ----------
    mashina_j = client.post("/mashinalar", json={
        "davlat_raqami": "01A777KM", "turi": "FAW", "shofyor": "Aliyev Vali",
        "firma": "Eski Firma MChJ", "viloyat": "Xorazm",
    }, headers=operator_headers)
    assert mashina_j.status_code == 200, mashina_j.text
    mashina = mashina_j.json()

    hujjat_j = client.post("/hujjatlar", json={
        "mashina_id": mashina["id"], "mahsulot_id": mahsulot_chigit.id,
    }, headers=operator_headers)
    assert hujjat_j.status_code == 200, hujjat_j.text
    hujjat = hujjat_j.json()
    hujjat_id = hujjat["id"]
    # Hujjat yaratilganda firma mashinadan meros olinadi.
    assert hujjat["firma"] == "Eski Firma MChJ"

    navbat_j = client.post("/navbat/qosh", json={
        "hujjatId": hujjat_id, "mashinaId": mashina["id"],
        "raqam": mashina["davlat_raqami"], "turi": "FAW",
        "shofyor": "Aliyev Vali", "firma": "Eski Firma MChJ",
        "mahsulotId": mahsulot_chigit.id, "mahsulotNomi": mahsulot_chigit.nom,
        "vaqt": "10:00", "aravalar": {},
    }, headers=operator_headers)
    assert navbat_j.status_code == 200, navbat_j.text

    tara_j = client.post("/olchovlar", json={
        "hujjat_id": hujjat_id, "arava_raqam": 1, "tara": 18000,
    }, headers=operator_headers)
    assert tara_j.status_code == 200, tara_j.text

    # Nakladnoy tokenini to'g'ridan-to'g'ri bazaga yozib qo'yamiz (PDF/
    # Playwright generatsiyasisiz) - GET /nakladnoy-korish/{token} shundan
    # keyingina ishlaydi.
    from models import Hujjat
    h = db_session.query(Hujjat).filter(Hujjat.id == hujjat_id).first()
    h.nakladnoy_token = secrets.token_urlsafe(24)
    db_session.commit()
    token = h.nakladnoy_token

    # ---------- 2) Admin: firma nomini o'zgartiradi ----------
    yangilash_j = client.put(f"/hujjatlar/{hujjat_id}", json={
        "firma": "Yangi Firma MChJ", "sabab": "Test",
    }, headers=admin_headers)
    assert yangilash_j.status_code == 200, yangilash_j.text
    assert yangilash_j.json()["firma"] == "Yangi Firma MChJ"

    # ---------- 3) Tekshiruv: navbatda turgan paytda ----------
    hujjat_get = client.get(f"/hujjatlar/{hujjat_id}", headers=admin_headers).json()
    assert hujjat_get["firma"] == "Yangi Firma MChJ", (
        "GET /hujjatlar/{id} eski firma nomini ko'rsatmoqda!")

    navbat_royxat = client.get("/navbat", headers=admin_headers).json()
    navbat_item = next((n for n in navbat_royxat if n["hujjatId"] == hujjat_id), None)
    assert navbat_item is not None, "Hujjat GET /navbat ro'yxatida topilmadi!"
    assert navbat_item["firma"] == "Yangi Firma MChJ", (
        f"GET /navbat eski firma nomini ko'rsatmoqda: {navbat_item['firma']!r} "
        "(admin PUT /hujjatlar/{id} orqali o'zgartirgan firma Navbat qatoriga "
        "sinxronlanmagan)"
    )

    nakladnoy_html = client.get(f"/nakladnoy-korish/{token}").text
    assert "Yangi Firma MChJ" in nakladnoy_html, (
        "Nakladnoy sahifasida yangi firma nomi ko'rinmayapti!")

    # ---------- 4) Operator BRUTTO ni o'lchaydi, navbatni tugatadi ----------
    brutto_j = client.post("/olchovlar", json={
        "hujjat_id": hujjat_id, "arava_raqam": 1, "tara": 18000, "brutto": 23000,
    }, headers=operator_headers)
    assert brutto_j.status_code == 200, brutto_j.text

    tugat_j = client.post("/navbat/tugallandi", json={
        "hujjatId": hujjat_id,
        "aravalar": {"1": {"tara": 18000, "brutto": 23000}},
    }, headers=operator_headers)
    assert tugat_j.status_code == 200, tugat_j.text

    # ---------- Tekshiruv: tugallangandan keyin ham ----------
    hujjat_get2 = client.get(f"/hujjatlar/{hujjat_id}", headers=admin_headers).json()
    assert hujjat_get2["holat"] == "tugallandi"
    assert hujjat_get2["firma"] == "Yangi Firma MChJ", (
        "Tugallangandan keyin GET /hujjatlar/{id} eski firma nomini ko'rsatmoqda!")

    # Tugallangach hujjat endi FAOL navbatda emas.
    navbat_royxat2 = client.get("/navbat", headers=admin_headers).json()
    assert all(n["hujjatId"] != hujjat_id for n in navbat_royxat2)

    tugallanganlar = client.get("/navbat/tugallanganlar", headers=admin_headers).json()
    tug_item = next((n for n in tugallanganlar if n["hujjatId"] == hujjat_id), None)
    assert tug_item is not None, "Hujjat GET /navbat/tugallanganlar ro'yxatida topilmadi!"
    assert tug_item["firma"] == "Yangi Firma MChJ", (
        f"GET /navbat/tugallanganlar eski firma nomini ko'rsatmoqda: "
        f"{tug_item['firma']!r}"
    )

    nakladnoy_html2 = client.get(f"/nakladnoy-korish/{token}").text
    assert "Yangi Firma MChJ" in nakladnoy_html2, (
        "Tugallangandan keyin nakladnoy sahifasida yangi firma nomi ko'rinmayapti!")
