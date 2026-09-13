"""
POST /hujjatlar, /olchovlar, /navbat/bekor, /nakladnoy/saqlash - avval
HECH QANDAY rol cheklovi yo'q edi (faqat get_current_user - istalgan
faol foydalanuvchi, jumladan "rahbar" ham, yoza olardi). "rahbar" FAQAT
o'qish uchun mo'ljallangan mobil dashboard roli (qarang:
rahbar_dashboard_screen.dart, GET /statistika/* atrofidagi izohlar) -
yozish endpointlariga kirishi kerak emas edi.

Endi bu 4 endpoint require_role("operator", "admin") bilan himoyalangan -
faqat operator va admin yoza oladi, boshqa rollar (rahbar, hisobchi) 403
oladi.
"""
from unittest.mock import patch

import pytest

from auth import create_access_token, hash_password
from models import User


@pytest.fixture()
def hisobchi_headers(db_session):
    user = User(username="test_hisobchi", password=hash_password("parol123"),
                role="hisobchi", is_active=True)
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    token = create_access_token({"sub": user.username, "role": user.role, "id": user.id})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def hujjat(client, admin_headers, mahsulot_chigit, mashina):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
    }, headers=admin_headers)
    return javob.json()


# ---------- POST /hujjatlar ----------

def test_hujjatlar_operator_yarata_oladi(client, operator_headers, mahsulot_chigit, mashina):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
    }, headers=operator_headers)
    assert javob.status_code == 200


def test_hujjatlar_rahbar_yarata_olmaydi(client, rahbar_headers, mahsulot_chigit, mashina):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
    }, headers=rahbar_headers)
    assert javob.status_code == 403


def test_hujjatlar_hisobchi_yarata_olmaydi(client, hisobchi_headers, mahsulot_chigit, mashina):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
    }, headers=hisobchi_headers)
    assert javob.status_code == 403


def test_hujjatlar_tokensiz_401(client, mahsulot_chigit, mashina):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
    })
    assert javob.status_code == 401


# ---------- POST /olchovlar ----------

def test_olchovlar_operator_saqlay_oladi(client, operator_headers, hujjat):
    javob = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "tara": 1000, "brutto": 3000,
    }, headers=operator_headers)
    assert javob.status_code == 200


def test_olchovlar_rahbar_saqlay_olmaydi(client, rahbar_headers, hujjat):
    javob = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "tara": 1000, "brutto": 3000,
    }, headers=rahbar_headers)
    assert javob.status_code == 403


def test_olchovlar_hisobchi_saqlay_olmaydi(client, hisobchi_headers, hujjat):
    javob = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "tara": 1000, "brutto": 3000,
    }, headers=hisobchi_headers)
    assert javob.status_code == 403


# ---------- POST /navbat/bekor ----------

def test_navbat_bekor_operator_bajara_oladi(client, operator_headers, hujjat):
    javob = client.post("/navbat/bekor", json={"hujjatId": hujjat["id"]}, headers=operator_headers)
    assert javob.status_code == 200


def test_navbat_bekor_rahbar_bajara_olmaydi(client, rahbar_headers, hujjat):
    javob = client.post("/navbat/bekor", json={"hujjatId": hujjat["id"]}, headers=rahbar_headers)
    assert javob.status_code == 403


def test_navbat_bekor_hisobchi_bajara_olmaydi(client, hisobchi_headers, hujjat):
    javob = client.post("/navbat/bekor", json={"hujjatId": hujjat["id"]}, headers=hisobchi_headers)
    assert javob.status_code == 403


# ---------- POST /nakladnoy/saqlash ----------
# Haqiqiy PDF generatsiyasi (Playwright, disk yozish) bu yerda sinalmaydi -
# faqat rol tekshiruvi (require_role) so'rov TANASIGA yetib borishidan
# OLDIN ishlashi tekshiriladi, xuddi test_nakladnoy_saqlash_xato_
# logging.py'dagi kabi ichki funksiyani mock qilib.

def test_nakladnoy_saqlash_operator_royxatga_otadi(client, operator_headers, hujjat):
    with patch("main.nakladnoy_uchun_malumot", side_effect=RuntimeError("sinov")):
        javob = client.post("/nakladnoy/saqlash", json={"hujjat_id": hujjat["id"]},
                             headers=operator_headers)
    # 403 EMAS - rol o'tdi, ichki xato tufayli 500 qaytadi.
    assert javob.status_code == 500


def test_nakladnoy_saqlash_rahbar_bajara_olmaydi(client, rahbar_headers, hujjat):
    javob = client.post("/nakladnoy/saqlash", json={"hujjat_id": hujjat["id"]},
                         headers=rahbar_headers)
    assert javob.status_code == 403


def test_nakladnoy_saqlash_hisobchi_bajara_olmaydi(client, hisobchi_headers, hujjat):
    javob = client.post("/nakladnoy/saqlash", json={"hujjat_id": hujjat["id"]},
                         headers=hisobchi_headers)
    assert javob.status_code == 403
