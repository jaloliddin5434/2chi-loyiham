"""
Bug: operator/admin ekranidagi "Tugallangan mashinalar" ro'yxati (operator
panelidagi "Tugallandi" tugmasi va admin panel dashboard'i) GET /navbat/
tugallanganlar orqali, Navbat jadvalining (PostgreSQL) `tugallandi`
bayrog'i asosida to'ldiriladi - Hujjat.holat'dan emas.

Odatiy yo'lda (operator "Tortishni tugatish" tugmasini bosganda, POST
/navbat/tugallandi orqali) ikkalasi ham bir vaqtda yangilanadi. Lekin
admin/hisobchi hujjatni umumiy tahrirlash oynasidan (PUT /hujjatlar/{id},
holat="tugallandi") TO'G'RIDAN-TO'G'RI ham tugatishi mumkin - masalan
operator ekranida oddiy yo'l bilan yakunlab bo'lmagan (masalan netto<=0
kabi anomal o'lchov tufayli qo'lda tuzatilgan) hujjatlarda. Bu yo'lda Navbat
qatori sinxronlanmasdi - natijada Hujjat.holat allaqachon TUGALLANDI bo'lsa
ham, hujjat "Tugallangan mashinalar" ro'yxatida (GET /navbat/tugallanganlar)
HECH QACHON ko'rinmasdi.

Endi PUT /hujjatlar/{id} holatni "tugallandi"ga o'tkazganda, mos Navbat
qatori (agar mavjud bo'lsa) ham tugallandi=True, tugallangan_vaqt=hozir
qilib yangilanadi - shu bilan qaysi yo'l bilan tugatilishidan (va o'lchov
netto qiymatidan) qat'i nazar, BARCHA holat=tugallandi hujjatlar ro'yxatda
ko'rinadi.
"""
import pytest


@pytest.fixture()
def hujjat(client, admin_headers, mahsulot_chigit, mashina):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
    }, headers=admin_headers)
    return javob.json()


@pytest.fixture(autouse=True)
def _excel_yozishni_ozarsizlantirish(monkeypatch):
    # holat "tugallandi"ga o'tganda excel_qatorga_yoz_fon() HAQIQIY diskka
    # yozadi - test bazasi bilan ishlasa ham, bu funksiya alohida. Xuddi
    # test_hujjat_yangilash.py'dagi kabi zararsizlantiramiz.
    monkeypatch.setattr("main.excel_qatorga_yoz", lambda hujjat_id, db: None)


def _navbatga_qosh(client, admin_headers, hujjat, mashina):
    javob = client.post("/navbat/qosh", json={
        "hujjatId": hujjat["id"], "mashinaId": mashina.id, "raqam": "01A123BB",
        "turi": "FAW", "shofyor": "Test Shofyor", "firma": "Test Firma",
        "mahsulotId": hujjat["mahsulot_id"], "mahsulotNomi": "Chigit", "vaqt": "10:00",
        "aravalar": {},
    }, headers=admin_headers)
    assert javob.status_code == 200


def test_admin_tahrirlash_orqali_tugatsa_navbat_ham_yangilanadi(
        client, admin_headers, hujjat, mashina, db_session):
    from models import Navbat

    _navbatga_qosh(client, admin_headers, hujjat, mashina)
    navbat = db_session.query(Navbat).filter(Navbat.hujjat_id == hujjat["id"]).first()
    assert navbat.tugallandi is False

    # Operator "Tortishni tugatish" tugmasini emas, admin umumiy tahrirlash
    # oynasidan to'g'ridan-to'g'ri holatni o'zgartiradi.
    javob = client.put(f"/hujjatlar/{hujjat['id']}", json={
        "holat": "tugallandi", "sabab": "Qo'lda tugatildi",
    }, headers=admin_headers)
    assert javob.status_code == 200

    db_session.expire_all()
    navbat = db_session.query(Navbat).filter(Navbat.hujjat_id == hujjat["id"]).first()
    assert navbat.tugallandi is True
    assert navbat.tugallangan_vaqt is not None


def test_manfiy_netto_bolsa_ham_tugallanganlar_royxatida_korinadi(
        client, admin_headers, hujjat, mashina):
    """Asosiy regressiya testi: netto manfiy (brutto < tara) bo'lsa ham,
    hujjat admin tomonidan to'g'ridan-to'g'ri tugatilgach GET /navbat/
    tugallanganlar ro'yxatida ko'rinishi kerak."""
    _navbatga_qosh(client, admin_headers, hujjat, mashina)

    olchov = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "tara": 20000, "brutto": 19000,
    }, headers=admin_headers)
    assert olchov.status_code == 200
    assert olchov.json()["netto"] == -1000.0

    javob = client.put(f"/hujjatlar/{hujjat['id']}", json={
        "holat": "tugallandi", "sabab": "Anomal olchov - qolda tugatildi",
    }, headers=admin_headers)
    assert javob.status_code == 200

    royxat = client.get("/navbat/tugallanganlar", headers=admin_headers).json()
    assert any(x["hujjatId"] == hujjat["id"] for x in royxat), (
        "Manfiy nettoli, admin tomonidan tugatilgan hujjat tugallanganlar "
        "ro'yxatida yo'q!"
    )


def test_navbat_qatori_bolmasa_ham_hujjat_tugaydi(client, admin_headers, hujjat):
    """Navbatga umuman qo'shilmagan (yoki allaqachon /navbat/bekor bilan
    o'chirilgan) hujjatni admin to'g'ridan-to'g'ri tugatsa - Navbat qatori
    yo'qligi sababli xato bermasligi kerak."""
    javob = client.put(f"/hujjatlar/{hujjat['id']}", json={
        "holat": "tugallandi", "sabab": "Navbatsiz tugatildi",
    }, headers=admin_headers)
    assert javob.status_code == 200
    assert javob.json()["holat"] == "tugallandi"


def test_odatiy_yol_orqali_tugallandi_vaqti_ustidan_yozilmaydi(
        client, admin_headers, operator_headers, hujjat, mashina, db_session):
    """Operator oddiy "Tortishni tugatish" (POST /navbat/tugallandi) orqali
    allaqachon tugatgan bo'lsa, keyinchalik admin shu hujjatga boshqa (holat
    bilan bog'liq bo'lmagan) maydonni yangilasa - Navbat.tugallangan_vaqt
    o'zgarmasligi kerak (allaqachon tugallandi=True, yangi kod bloki shart
    bo'yicha ishlamaydi)."""
    from models import Navbat

    _navbatga_qosh(client, admin_headers, hujjat, mashina)
    j = client.post("/navbat/tugallandi", json={
        "hujjatId": hujjat["id"], "aravalar": {},
    }, headers=operator_headers)
    assert j.status_code == 200

    db_session.expire_all()
    navbat = db_session.query(Navbat).filter(Navbat.hujjat_id == hujjat["id"]).first()
    asl_vaqt = navbat.tugallangan_vaqt
    assert asl_vaqt is not None

    # Endi admin allaqachon tugallandi bo'lgan hujjatga boshqa maydon
    # yangilaydi (holat o'zgarmaydi - eski_holat == yangi holat == tugallandi).
    javob = client.put(f"/hujjatlar/{hujjat['id']}", json={
        "qabul_qildi": "Boshqa qabul qiluvchi", "sabab": "Qoshimcha malumot",
    }, headers=admin_headers)
    assert javob.status_code == 200

    db_session.expire_all()
    navbat = db_session.query(Navbat).filter(Navbat.hujjat_id == hujjat["id"]).first()
    assert navbat.tugallangan_vaqt == asl_vaqt
