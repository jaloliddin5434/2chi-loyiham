"""
To'liq integratsiya testi: 2 aravali (pritsepli) mashina uchun operator
oqimining boshidan oxirigacha - hujjat yaratish, har ikki arava tara,
navbatga qo'shish, har ikki arava brutto, va yakunlash.

Muhim: backendning o'zi (POST /navbat/tugallandi) NECHTA arava
o'lchanganini TEKSHIRMAYDI - bu qaror operator ekranida (frontend,
aravalarSoni/_keyingiBruttoSizArava() orqali) qabul qilinadi va faqat
BARCHA aravalar bruttosi olingandan keyin shu endpoint chaqiriladi (qarang:
operator_kop_arava_brutto_test.dart). Shu sabab bu test ham xuddi shu
haqiqiy oqimni takrorlaydi: 1-arava brutto saqlangandan keyin operator
ekrani /navbat/tugallandi'ni CHAQIRMAYDI (hujjat "jarayon"da qoladi),
faqat 2-arava (oxirgisi) brutto saqlangandan KEYIN chaqiradi.
"""
import pytest

from models import Hujjat, HujjatHolati


@pytest.fixture(autouse=True)
def _excel_yozishni_ozarsizlantirish(monkeypatch):
    monkeypatch.setattr("main.excel_qatorga_yoz", lambda hujjat_id, db: None)


def test_2_aravali_mashina_toliq_oqimi(
        client, operator_headers, mahsulot_chigit, mashina, db_session):
    # 1. Operator bo'lib, 2 aravali mashina uchun hujjat yaratadi.
    hujjat_javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
        "aravalar_soni": 2,
    }, headers=operator_headers)
    assert hujjat_javob.status_code == 200
    hujjat = hujjat_javob.json()
    assert hujjat["aravalar_soni"] == 2

    # 2-3. Har ikki arava uchun TARA o'lchanadi.
    tara1 = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "tara": 5000,
    }, headers=operator_headers)
    assert tara1.status_code == 200
    assert tara1.json()["brutto"] is None

    tara2 = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 2, "tara": 4800,
    }, headers=operator_headers)
    assert tara2.status_code == 200
    assert tara2.json()["brutto"] is None

    # 4. Mashina navbatga qo'shiladi (tara olingandan keyin, brutto uchun).
    navbat_javob = client.post("/navbat/qosh", json={
        "hujjatId": hujjat["id"], "mashinaId": mashina.id, "raqam": "01A777KAM",
        "turi": "Kamaz", "shofyor": "Test Shofyor", "firma": "Test Firma",
        "mahsulotId": hujjat["mahsulot_id"], "mahsulotNomi": "Chigit", "vaqt": "09:00",
        "aravalar": {},
    }, headers=operator_headers)
    assert navbat_javob.status_code == 200

    # 5. GET /navbat orqali mashina olinadi - aravalarSoni to'g'ri kelishi
    # (bu, avval mavjud bo'lgan bug'ning oldini oladi - qarang: aravalarSoni
    # umuman jo'natilmasdi va operator ekrani standart 1 deb hisoblardi).
    royxat = client.get("/navbat", headers=operator_headers).json()
    qator = next(x for x in royxat if x["hujjatId"] == hujjat["id"])
    assert qator["aravalarSoni"] == 2

    # 6. 1-arava BRUTTO o'lchanadi - bu YOLG'IZ O'ZI hujjatni tugatMAYDI
    # (operator ekrani navbat/tugallandi'ni hali chaqirmaydi, chunki
    # 2-arava hali kutilmoqda).
    brutto1 = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "brutto": 9000,
    }, headers=operator_headers)
    assert brutto1.status_code == 200
    assert brutto1.json()["netto"] == 4000

    db_session.expire_all()
    hujjat_db = db_session.query(Hujjat).filter(Hujjat.id == hujjat["id"]).first()
    assert hujjat_db.holat == HujjatHolati.JARAYON, (
        "1-arava bruttosi saqlangandan keyin hujjat vaqtidan oldin "
        "tugallandi deb belgilanib qoldi!"
    )
    # GET /navbat FAQAT hali tugallanmagan qatorlarni qaytaradi - mashina
    # bu ro'yxatda hamon ko'rinishi kerak (agar tugallandi bo'lsa,
    # ro'yxatdan butunlay tushib qolgan bo'lardi).
    royxat = client.get("/navbat", headers=operator_headers).json()
    assert any(x["hujjatId"] == hujjat["id"] for x in royxat), (
        "1-arava bruttosidan keyin mashina navbat ro'yxatidan yo'qolib, "
        "vaqtidan oldin tugallandi deb hisoblanib qoldi!"
    )

    # 7. 2-arava (oxirgi) BRUTTO o'lchanadi - ENDI operator ekrani barcha
    # aravalar tugaganini aniqlab, /navbat/tugallandi'ni chaqiradi.
    brutto2 = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 2, "brutto": 8700,
    }, headers=operator_headers)
    assert brutto2.status_code == 200
    assert brutto2.json()["netto"] == 3900

    tugallandi_javob = client.post("/navbat/tugallandi", json={
        "hujjatId": hujjat["id"], "aravalar": {},
    }, headers=operator_headers)
    assert tugallandi_javob.status_code == 200

    db_session.expire_all()
    hujjat_db = db_session.query(Hujjat).filter(Hujjat.id == hujjat["id"]).first()
    assert hujjat_db.holat == HujjatHolati.TUGALLANDI

    # Endi faol navbat ro'yxatidan chiqib ketgan bo'lishi kerak.
    royxat = client.get("/navbat", headers=operator_headers).json()
    assert not any(x["hujjatId"] == hujjat["id"] for x in royxat)

    # 8. GET /navbat/tugallanganlar ro'yxatida ko'rinadi, aravalarSoni ham
    # to'g'ri keladi.
    tugallanganlar = client.get("/navbat/tugallanganlar", headers=operator_headers).json()
    qator = next(x for x in tugallanganlar if x["hujjatId"] == hujjat["id"])
    assert qator["aravalarSoni"] == 2
