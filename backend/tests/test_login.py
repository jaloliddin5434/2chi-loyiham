"""
Login endpointi - to'g'ri/xato ma'lumotlar, bloklangan (is_active=False)
hisob, va tezlik cheklovi (5/daqiqa).

Har bir test o'ziga xos CF-Connecting-IP qiymati bilan so'rov yuboradi -
shu bilan slowapi'ning IP-bo'yicha hisoblagichi testlar orasida
ARALASHIB KETMAYDI (aks holda testlar ijro tartibiga qarab beqaror
bo'lib qolardi, chunki limiter butun test jarayoni davomida bitta
umumiy xotirada saqlanadi).
"""
import uuid

from models import User
from auth import hash_password


def _ip():
    return f"10.99.{uuid.uuid4().fields[0] % 255}.{uuid.uuid4().fields[1] % 255}"


def _foydalanuvchi_yarat(db_session, username, password, role, is_active=True):
    user = User(username=username, password=hash_password(password),
                role=role, is_active=is_active)
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


def test_togri_login_muvaffaqiyatli(client, db_session):
    _foydalanuvchi_yarat(db_session, "login_ok", "parol123", "operator")
    javob = client.post("/login", json={
        "username": "login_ok", "password": "parol123", "role": "operator",
    }, headers={"CF-Connecting-IP": _ip()})
    assert javob.status_code == 200
    natija = javob.json()
    assert natija["username"] == "login_ok"
    assert natija["role"] == "operator"
    assert "access_token" in natija


def test_xato_parol_rad_etiladi(client, db_session):
    _foydalanuvchi_yarat(db_session, "login_xatoparol", "togriparol", "operator")
    javob = client.post("/login", json={
        "username": "login_xatoparol", "password": "notogri", "role": "operator",
    }, headers={"CF-Connecting-IP": _ip()})
    assert javob.status_code == 401


def test_xato_rol_rad_etiladi(client, db_session):
    _foydalanuvchi_yarat(db_session, "login_xatorol", "parol123", "operator")
    javob = client.post("/login", json={
        "username": "login_xatorol", "password": "parol123", "role": "admin",
    }, headers={"CF-Connecting-IP": _ip()})
    assert javob.status_code == 401


def test_bloklangan_hisob_kira_olmaydi(client, db_session):
    _foydalanuvchi_yarat(db_session, "login_bloklangan", "parol123", "operator",
                          is_active=False)
    javob = client.post("/login", json={
        "username": "login_bloklangan", "password": "parol123", "role": "operator",
    }, headers={"CF-Connecting-IP": _ip()})
    assert javob.status_code == 401
    # Bloklangan hisob uchun ALOHIDA xabar EMAS - oddiy login xatosi bilan
    # bir xil bo'lishi kerak (hisob mavjudligini oshkor qilmaslik uchun).
    assert javob.json()["detail"] == "Login yoki parol noto'g'ri!"


def test_mavjud_bolmagan_foydalanuvchi_rad_etiladi(client):
    javob = client.post("/login", json={
        "username": "hech_qachon_mavjud_bolmagan", "password": "parol123", "role": "operator",
    }, headers={"CF-Connecting-IP": _ip()})
    assert javob.status_code == 401


def test_tezlik_cheklovi_5tadan_keyin_ishga_tushadi(client, db_session):
    _foydalanuvchi_yarat(db_session, "login_ratelimit", "parol123", "operator")
    ip = _ip()
    # Birinchi 5 ta urinish (xato parol bilan) - hali rate-limit emas, 401.
    for _ in range(5):
        javob = client.post("/login", json={
            "username": "login_ratelimit", "password": "notogri", "role": "operator",
        }, headers={"CF-Connecting-IP": ip})
        assert javob.status_code == 401
    # 6-chi urinish - endi 429 (Too Many Requests) bo'lishi kerak.
    javob = client.post("/login", json={
        "username": "login_ratelimit", "password": "notogri", "role": "operator",
    }, headers={"CF-Connecting-IP": ip})
    assert javob.status_code == 429
