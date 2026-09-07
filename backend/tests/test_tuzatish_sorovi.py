"""
Tuzatish so'rovi tizimi: operator hujjat maydonini to'g'ridan-to'g'ri
o'zgartira olmaydi - so'rov qoldiradi, admin tasdiqlaydi yoki rad etadi.

- POST /tuzatish_sorovi                     (operator so'rov yuboradi)
- GET  /tuzatish_sorovlar                   (admin barchasini ko'radi)
- GET  /tuzatish_sorovlar/operator/{login}  (operator o'zinikini ko'radi)
- POST /tuzatish_sorovi/{id}/tasdiq         (admin tasdiqlaydi -> hujjat + navbat yangilanadi)
- POST /tuzatish_sorovi/{id}/rad            (admin rad etadi -> hujjat o'zgarmaydi)
"""
import pytest


@pytest.fixture()
def hujjat(client, admin_headers, mahsulot_chigit, mashina):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
    }, headers=admin_headers)
    return javob.json()


@pytest.fixture()
def navbatli_hujjat(client, admin_headers, hujjat):
    """Hujjat + unga bog'langan Navbat qatori (operator ekrani /navbat dan
    o'qiydi - tasdiq Navbat'ni ham yangilashini tekshirish uchun)."""
    client.post("/navbat/qosh", json={
        "hujjatId": hujjat["id"], "mashinaId": 1, "raqam": "01A111AA",
        "turi": "FAW", "shofyor": "Eski Shofyor", "firma": "Eski Firma",
        "mahsulotId": 1, "mahsulotNomi": "Chigit", "vaqt": "08:00",
        "klass": "1", "seleksiyaNavi": "Xorazm-150",
        "aravalar": {},
    }, headers=admin_headers)
    return hujjat


# ---------- So'rov yuborish ----------

def test_operator_sorov_yuboradi(client, operator_headers, hujjat):
    javob = client.post("/tuzatish_sorovi", json={
        "hujjat_id": hujjat["id"], "maydon_nomi": "klass",
        "eski_qiymat": "1", "yangi_qiymat": "2", "sabab": "Klass xato kiritilgan",
    }, headers=operator_headers)
    assert javob.status_code == 200
    t = javob.json()
    assert t["holat"] == "kutilmoqda"
    assert t["operator_login"] == "test_operator"
    assert t["maydon_nomi"] == "klass"
    assert t["hal_qilingan_vaqt"] is None
    assert t["admin_login"] is None
    assert t["hujjat_raqam"] == hujjat["raqam"]


def test_sababsiz_sorov_rad_etiladi(client, operator_headers, hujjat):
    javob = client.post("/tuzatish_sorovi", json={
        "hujjat_id": hujjat["id"], "maydon_nomi": "klass", "yangi_qiymat": "2",
    }, headers=operator_headers)
    assert javob.status_code == 400


def test_ruxsatsiz_maydonga_sorov_rad_etiladi(client, operator_headers, hujjat):
    javob = client.post("/tuzatish_sorovi", json={
        "hujjat_id": hujjat["id"], "maydon_nomi": "terim_turi",
        "yangi_qiymat": "Mashina terim", "sabab": "test",
    }, headers=operator_headers)
    assert javob.status_code == 400


def test_yoq_hujjatga_sorov_404(client, operator_headers):
    javob = client.post("/tuzatish_sorovi", json={
        "hujjat_id": 999999, "maydon_nomi": "klass",
        "yangi_qiymat": "2", "sabab": "test",
    }, headers=operator_headers)
    assert javob.status_code == 404


# ---------- Ro'yxatlar ----------

def test_admin_barcha_sorovlarni_koradi(client, admin_headers, operator_headers, hujjat):
    client.post("/tuzatish_sorovi", json={
        "hujjat_id": hujjat["id"], "maydon_nomi": "firma",
        "yangi_qiymat": "Yangi Firma", "sabab": "test",
    }, headers=operator_headers)
    javob = client.get("/tuzatish_sorovlar", headers=admin_headers)
    assert javob.status_code == 200
    assert len(javob.json()) >= 1
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


# ---------- Tasdiq / rad ----------

def test_tasdiq_hujjat_va_navbatni_yangilaydi(client, admin_headers, operator_headers, navbatli_hujjat):
    sorov = client.post("/tuzatish_sorovi", json={
        "hujjat_id": navbatli_hujjat["id"], "maydon_nomi": "firma",
        "eski_qiymat": "Eski Firma", "yangi_qiymat": "Tasdiqlangan Firma",
        "sabab": "Firma noto'g'ri edi",
    }, headers=operator_headers).json()

    javob = client.post(f"/tuzatish_sorovi/{sorov['id']}/tasdiq", headers=admin_headers)
    assert javob.status_code == 200
    assert javob.json()["holat"] == "tasdiqlandi"
    assert javob.json()["admin_login"] == "test_admin"
    assert javob.json()["hal_qilingan_vaqt"] is not None

    # Hujjat yangilandi
    h = client.get(f"/hujjatlar/{navbatli_hujjat['id']}", headers=admin_headers).json()
    assert h["firma"] == "Tasdiqlangan Firma"

    # Navbat qatori HAM yangilandi (operator ekrani shu yerdan o'qiydi)
    navbat = client.get("/navbat", headers=admin_headers).json()
    bizniki = [n for n in navbat if n["hujjatId"] == navbatli_hujjat["id"]]
    assert bizniki and bizniki[0]["firma"] == "Tasdiqlangan Firma"

    # Audit izchilligi
    tarix = client.get(f"/tahrirlar-tarixi/{navbatli_hujjat['id']}", headers=admin_headers).json()
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
    # rad javobida ham hujjat_raqam bo'lishi kerak (tasdiq bilan bir xil) -
    # frontend ikkala javobni ham bir xil ishlaydi.
    assert javob.json()["hujjat_raqam"] == hujjat["raqam"]

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


def test_yoq_sorovni_tasdiq_404(client, admin_headers):
    javob = client.post("/tuzatish_sorovi/999999/tasdiq", headers=admin_headers)
    assert javob.status_code == 404
