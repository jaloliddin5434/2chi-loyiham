"""
POST /olchovlar - o'lchov saqlash: yangi arava qo'shish, xuddi shu
arava_raqam bilan qayta yuborilganda YANGILANISHI (dublikat qator EMAS),
va netto/konditsion avtomatik hisoblanishi.
"""
import pytest


@pytest.fixture()
def hujjat(client, admin_headers, mahsulot_chigit, mashina):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
    }, headers=admin_headers)
    return javob.json()


def test_olchov_yangi_arava_qoshiladi(client, admin_headers, hujjat):
    javob = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "tara": 1000, "brutto": 3000,
    }, headers=admin_headers)
    assert javob.status_code == 200
    natija = javob.json()
    assert natija["tara"] == 1000
    assert natija["brutto"] == 3000
    # netto = brutto - tara avtomatik hisoblanishi kerak.
    assert natija["netto"] == 2000


def test_olchov_konditsion_avtomatik_hisoblanadi(client, admin_headers, hujjat):
    from utils import konditsion_hisobla
    javob = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1,
        "tara": 1000, "brutto": 3000, "namlik": 5.0, "ifloslik": 3.0,
    }, headers=admin_headers)
    natija = javob.json()
    kutilgan_konditsion = konditsion_hisobla(2000, 5.0, 3.0)
    assert natija["konditsion"] == pytest.approx(kutilgan_konditsion)


def test_olchov_xuddi_shu_arava_yangilanadi_dublikat_bolmaydi(client, admin_headers, hujjat):
    # 1-qadam: faqat TARA saqlanadi (operator ekranidagi haqiqiy oqim).
    javob1 = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "tara": 1000,
    }, headers=admin_headers)
    assert javob1.status_code == 200
    assert javob1.json()["tara"] == 1000
    assert javob1.json()["brutto"] is None

    # 2-qadam: xuddi shu arava_raqam uchun endi BRUTTO ham qo'shiladi -
    # bu YANGI qator EMAS, birinchisi YANGILANISHI kerak (tara saqlanib
    # qolishi, id o'zgarmasligi).
    javob2 = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "brutto": 3000,
    }, headers=admin_headers)
    assert javob2.status_code == 200
    natija2 = javob2.json()
    assert natija2["id"] == javob1.json()["id"]
    assert natija2["tara"] == 1000  # eskisi yo'qolmagan
    assert natija2["brutto"] == 3000
    assert natija2["netto"] == 2000

    # 3-qadam: shu hujjat uchun jami bitta qator bo'lishi kerak (dublikat yo'q).
    royxat = client.get(f"/olchovlar/{hujjat['id']}", headers=admin_headers)
    assert len(royxat.json()) == 1


def test_ikkita_alohida_arava_ikkita_qator_yaratadi(client, admin_headers, hujjat):
    client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "tara": 1000, "brutto": 3000,
    }, headers=admin_headers)
    client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 2, "tara": 1100, "brutto": 3200,
    }, headers=admin_headers)
    royxat = client.get(f"/olchovlar/{hujjat['id']}", headers=admin_headers)
    assert len(royxat.json()) == 2
