"""
Tuzatish so'rovi tizimi: operator hujjat maydonini to'g'ridan-to'g'ri
o'zgartira olmaydi - so'rov qoldiradi, admin tasdiqlaydi yoki rad etadi.

- POST /tuzatish_sorovi                         (operator so'rov yuboradi)
- GET  /tuzatish_sorovlar                       (admin barchasini ko'radi)
- GET  /tuzatish_sorovlar/operator/{login}      (operator o'zinikini ko'radi)
- POST /tuzatish_sorovi/{id}/tasdiq             (admin tasdiqlaydi -> hujjat yangilanadi)
- POST /tuzatish_sorovi/{id}/rad                (admin rad etadi -> hujjat o'zgarmaydi)
"""
import pytest


@pytest.fixture()
def hujjat(client, admin_headers, mahsulot_chigit, mashina):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
    }, headers=admin_headers)
    return javob.json()


def test_operator_sorov_yuboradi(client, operator_headers, hujjat):
    javob = client.post("/tuzatish_sorovi", json={
        "hujjat_id": hujjat["id"],
        "maydon_nomi": "klass",
        "eski_qiymat": "1",
        "yangi_qiymat": "2",
        "sabab": "Klass xato kiritilgan",
    }, headers=operator_headers)
    assert javob.status_code == 200
    t = javob.json()
    assert t["holat"] == "kutilmoqda"
    assert t["operator_login"] == "test_operator"
    assert t["maydon_nomi"] == "klass"
    assert t["hal_qilingan_vaqt"] is None
    assert t["admin_login"] is None


def test_sababsiz_sorov_rad_etiladi(client, operator_headers, hujjat):
    javob = client.post("/tuzatish_sorovi", json={
        "hujjat_id": hujjat["id"], "maydon_nomi": "klass", "yangi_qiymat": "2",
    }, headers=operator_headers)
    assert javob.status_code == 400


def test_ruxsatsiz_maydonga_sorov_rad_etiladi(client, operator_headers, hujjat):
    # terim_turi ATAYLAB ruxsat etilgan ro'yxatda yo'q
    javob = client.post("/tuzatish_sorovi", json={
        "hujjat_id": hujjat["id"], "maydon_nomi": "terim_turi",
        "yangi_qiymat": "Mashina terim", "sabab": "test",
    }, headers=operator_headers)
    assert javob.status_code == 400


def test_admin_barcha_sorovlarni_koradi(client, admin_headers, operator_headers, hujjat):
    client.post("/tuzatish_sorovi", json={
        "hujjat_id": hujjat["id"], "maydon_nomi": "firma",
        "yangi_qiymat": "Yangi Firma", "sabab": "test",
    }, headers=operator_headers)
    javob = client.get("/tuzatish_sorovlar", headers=admin_headers)
    assert javob.status_code == 200
    assert len(javob.json()) >= 1
    assert javob.json()[0]["hujjat_raqam"] == hujjat["raqam"]

    # holat filtri
    kutilmoqda = client.get("/tuzatish_sorovlar?holat=kutilmoqda", headers=admin_headers)
    assert all(t["holat"] == "kutilmoqda" for t in kutilmoqda.json())


def test_operator_admin_royxatini_kora_olmaydi(client, operator_headers):
    javob = client.get("/tuzatish_sorovlar", headers=operator_headers)
    assert javob.status_code == 403


def test_operator_ozining_sorovlarini_koradi(client, operator_headers, hujjat):
    client.post("/tuzatish_sorovi", json={
        "hujjat_id": hujjat["id"], "maydon_nomi": "sinf",
        "yangi_qiymat": "A", "sabab": "test",
    }, headers=operator_headers)
    javob = client.get("/tuzatish_sorovlar/operator/test_operator", headers=operator_headers)
    assert javob.status_code == 200
    assert len(javob.json()) == 1
    assert javob.json()[0]["maydon_nomi"] == "sinf"


def test_operator_boshqa_operator_sorovini_kora_olmaydi(client, operator_headers):
    javob = client.get("/tuzatish_sorovlar/operator/boshqa_odam", headers=operator_headers)
    assert javob.status_code == 403


def test_tasdiq_hujjatni_yangilaydi(client, admin_headers, operator_headers, hujjat):
    sorov = client.post("/tuzatish_sorovi", json={
        "hujjat_id": hujjat["id"], "maydon_nomi": "firma",
        "yangi_qiymat": "Tasdiqlangan Firma", "sabab": "Firma noto'g'ri edi",
    }, headers=operator_headers).json()

    javob = client.post(f"/tuzatish_sorovi/{sorov['id']}/tasdiq", headers=admin_headers)
    assert javob.status_code == 200
    assert javob.json()["holat"] == "tasdiqlandi"
    assert javob.json()["admin_login"] == "test_admin"
    assert javob.json()["hal_qilingan_vaqt"] is not None

    # hujjat haqiqatan yangilandi
    h = client.get(f"/hujjatlar/{hujjat['id']}", headers=admin_headers).json()
    assert h["firma"] == "Tasdiqlangan Firma"

    # audit izchilligi uchun TahrirTarixi'ga ham yozildi
    tarix = client.get(f"/tahrirlar-tarixi/{hujjat['id']}", headers=admin_headers).json()
    assert any(t["maydon"] == "firma" and t["yangi_qiymat"] == "Tasdiqlangan Firma"
               for t in tarix)


def test_tasdiq_namlik_konditsionni_qayta_hisoblaydi(client, admin_headers, operator_headers, hujjat):
    from utils import konditsion_hisobla
    client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "tara": 1000, "brutto": 3000,
    }, headers=admin_headers)
    client.put(f"/hujjatlar/{hujjat['id']}", json={
        "namlik": 10, "ifloslik": 5, "sabab": "boshlang'ich",
    }, headers=admin_headers)

    sorov = client.post("/tuzatish_sorovi", json={
        "hujjat_id": hujjat["id"], "maydon_nomi": "namlik",
        "yangi_qiymat": "8", "sabab": "Namlik qayta o'lchandi",
    }, headers=operator_headers).json()
    javob = client.post(f"/tuzatish_sorovi/{sorov['id']}/tasdiq", headers=admin_headers)
    assert javob.status_code == 200

    olchovlar = client.get(f"/olchovlar/{hujjat['id']}", headers=admin_headers).json()
    assert olchovlar[0]["namlik"] == pytest.approx(8)
    assert olchovlar[0]["konditsion"] == pytest.approx(konditsion_hisobla(2000, 8, 5))


def test_rad_hujjatni_ozgartirmaydi(client, admin_headers, operator_headers, hujjat):
    sorov = client.post("/tuzatish_sorovi", json={
        "hujjat_id": hujjat["id"], "maydon_nomi": "firma",
        "yangi_qiymat": "Rad Etilgan Firma", "sabab": "test",
    }, headers=operator_headers).json()

    javob = client.post(f"/tuzatish_sorovi/{sorov['id']}/rad", headers=admin_headers)
    assert javob.status_code == 200
    assert javob.json()["holat"] == "rad_etildi"
    assert javob.json()["admin_login"] == "test_admin"

    h = client.get(f"/hujjatlar/{hujjat['id']}", headers=admin_headers).json()
    assert h["firma"] != "Rad Etilgan Firma"


def test_hal_qilingan_sorov_qayta_hal_qilinmaydi(client, admin_headers, operator_headers, hujjat):
    sorov = client.post("/tuzatish_sorovi", json={
        "hujjat_id": hujjat["id"], "maydon_nomi": "sinf",
        "yangi_qiymat": "B", "sabab": "test",
    }, headers=operator_headers).json()
    client.post(f"/tuzatish_sorovi/{sorov['id']}/tasdiq", headers=admin_headers)

    qayta = client.post(f"/tuzatish_sorovi/{sorov['id']}/rad", headers=admin_headers)
    assert qayta.status_code == 400


def test_operator_tasdiqlay_olmaydi(client, operator_headers, hujjat):
    sorov = client.post("/tuzatish_sorovi", json={
        "hujjat_id": hujjat["id"], "maydon_nomi": "sinf",
        "yangi_qiymat": "C", "sabab": "test",
    }, headers=operator_headers).json()
    javob = client.post(f"/tuzatish_sorovi/{sorov['id']}/tasdiq", headers=operator_headers)
    assert javob.status_code == 403
