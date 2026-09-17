"""
Bug: 2 (yoki 3) pritsepli mashinada Kamaz navbatdan BRUTTO uchun tanlanganda,
operator ekrani nechta arava borligini bilmasdi - GET /navbat javobida
"aravalarSoni" umuman yo'q edi. Natijada frontend standart 1 arava deb
hisoblab, 1-arava bruttosi o'lchangandan keyin darhol "tugallandi" deb
nakladnoy chiqarardi - 2-pritsep bruttosi hech qachon o'lchanmasdi.

Hujjat.aravalar_soni ustuni tara bosqichida (POST /hujjatlar) allaqachon
to'g'ri saqlanadi - shu qiymat endi GET /navbat va GET /navbat/
tugallanganlar javobiga ham qo'shiladi.
"""
import pytest


@pytest.fixture()
def hujjat_2_arava(client, admin_headers, mahsulot_chigit, mashina):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
        "aravalar_soni": 2,
    }, headers=admin_headers)
    assert javob.status_code == 200
    return javob.json()


def _navbatga_qosh(client, admin_headers, hujjat, mashina):
    javob = client.post("/navbat/qosh", json={
        "hujjatId": hujjat["id"], "mashinaId": mashina.id, "raqam": "01A123BB",
        "turi": "FAW", "shofyor": "Test Shofyor", "firma": "Test Firma",
        "mahsulotId": hujjat["mahsulot_id"], "mahsulotNomi": "Chigit", "vaqt": "10:00",
        "aravalar": {},
    }, headers=admin_headers)
    assert javob.status_code == 200


@pytest.fixture(autouse=True)
def _excel_yozishni_ozarsizlantirish(monkeypatch):
    monkeypatch.setattr("main.excel_qatorga_yoz", lambda hujjat_id, db: None)


def test_navbat_royxati_aravalar_sonini_qaytaradi(
        client, admin_headers, hujjat_2_arava, mashina):
    _navbatga_qosh(client, admin_headers, hujjat_2_arava, mashina)

    royxat = client.get("/navbat", headers=admin_headers).json()
    qator = next(x for x in royxat if x["hujjatId"] == hujjat_2_arava["id"])
    assert qator["aravalarSoni"] == 2


def test_navbat_royxati_hujjat_bolmasa_standart_1_qaytaradi(
        client, admin_headers, mahsulot_chigit, mashina):
    hujjat = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
    }, headers=admin_headers).json()
    _navbatga_qosh(client, admin_headers, hujjat, mashina)

    royxat = client.get("/navbat", headers=admin_headers).json()
    qator = next(x for x in royxat if x["hujjatId"] == hujjat["id"])
    assert qator["aravalarSoni"] == 1


def test_tugallanganlar_royxati_aravalar_sonini_qaytaradi(
        client, admin_headers, operator_headers, hujjat_2_arava, mashina):
    _navbatga_qosh(client, admin_headers, hujjat_2_arava, mashina)
    j = client.post("/navbat/tugallandi", json={
        "hujjatId": hujjat_2_arava["id"], "aravalar": {},
    }, headers=operator_headers)
    assert j.status_code == 200

    royxat = client.get("/navbat/tugallanganlar", headers=admin_headers).json()
    qator = next(x for x in royxat if x["hujjatId"] == hujjat_2_arava["id"])
    assert qator["aravalarSoni"] == 2
