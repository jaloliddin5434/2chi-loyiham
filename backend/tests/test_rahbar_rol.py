"""Yangi "rahbar" roli - mobil Rahbar dashboard uchun.

Rahbar FAQAT o'qish uchun mo'ljallangan: statistika/navbat/firma
ma'lumotlarini (oddiy login bilan) va PIN tasdiqlangandan keyin
moliyaviy hisobotni ko'ra oladi, lekin foydalanuvchi boshqarish,
sozlamalar, backup kabi admin-ga xos amallarga (va PIN'ning o'zini
o'rnatishga) kirolmaydi."""
import uuid


def _ip():
    return f"10.88.{uuid.uuid4().fields[0] % 255}.{uuid.uuid4().fields[1] % 255}"


def test_rahbar_login_muvaffaqiyatli(client, rahbar_user):
    javob = client.post("/login", json={
        "username": "test_rahbar", "password": "parol123", "role": "rahbar",
    }, headers={"CF-Connecting-IP": _ip()})
    assert javob.status_code == 200
    assert javob.json()["role"] == "rahbar"


def test_rahbar_kunlik_statistikani_kora_oladi(client, rahbar_headers):
    javob = client.get("/statistika/kunlik", headers=rahbar_headers)
    assert javob.status_code == 200
    assert "jami_tonnaj" in javob.json()


def test_rahbar_navbatni_kora_oladi(client, rahbar_headers):
    javob = client.get("/navbat", headers=rahbar_headers)
    assert javob.status_code == 200


def test_rahbar_firmalar_statistikasini_kora_oladi(client, rahbar_headers):
    javob = client.get("/statistika/firmalar", params={"davr": "kunlik"}, headers=rahbar_headers)
    assert javob.status_code == 200
    assert "firmalar" in javob.json()


def test_rahbar_pin_orimasa_moliyaviy_hisobotga_kirolmaydi(client, rahbar_headers):
    javob = client.get("/moliyaviy/hisobot", params={"davr": "kunlik"}, headers=rahbar_headers)
    assert javob.status_code == 403


def test_rahbar_toliq_pin_oqimi_ishlaydi(client, admin_headers, rahbar_headers):
    """Admin PIN o'rnatadi (rahbar buni qila olmaydi - qarang pastdagi
    test), keyin rahbar O'ZI to'g'ri PIN bilan moliyaviy tokenini olib,
    hisobotni ko'ra oladi."""
    admin_h = {**admin_headers, "CF-Connecting-IP": _ip()}
    javob = client.put("/moliyaviy/pin", json={"yangi_pin": "4321"}, headers=admin_h)
    assert javob.status_code == 200

    rahbar_h = {**rahbar_headers, "CF-Connecting-IP": _ip()}
    pin_javob = client.post("/moliyaviy/pin-tekshir", json={"pin": "4321"}, headers=rahbar_h)
    assert pin_javob.status_code == 200
    moliyaviy_token = pin_javob.json()["moliyaviy_token"]

    hisobot_javob = client.get(
        "/moliyaviy/hisobot", params={"davr": "kunlik"},
        headers={"Authorization": f"Bearer {moliyaviy_token}"},
    )
    assert hisobot_javob.status_code == 200
    assert "jami_daromad" in hisobot_javob.json()


def test_rahbar_pin_orimaydi(client, rahbar_headers):
    """PIN o'rnatish/o'zgartirish - faqat admin uchun qoladi, rahbar
    uchun EMAS (rahbar - faqat ko'ruvchi, moliyaviy sozlamalarga
    tegmasligi kerak)."""
    javob = client.put(
        "/moliyaviy/pin", json={"yangi_pin": "9999"},
        headers={**rahbar_headers, "CF-Connecting-IP": _ip()},
    )
    assert javob.status_code == 403


def test_rahbar_foydalanuvchilar_royxatiga_kirolmaydi(client, rahbar_headers):
    javob = client.get("/users", headers=rahbar_headers)
    assert javob.status_code == 403


def test_rahbar_foydalanuvchi_qosha_olmaydi(client, rahbar_headers):
    javob = client.post("/users", json={
        "username": "rahbar_yaratmoqchi", "password": "parol123", "role": "operator",
    }, headers=rahbar_headers)
    assert javob.status_code == 403


def test_rahbar_backup_qila_olmaydi(client, rahbar_headers):
    javob = client.post("/backup", headers=rahbar_headers)
    assert javob.status_code == 403


def test_rahbar_sozlama_ozgartira_olmaydi(client, rahbar_headers):
    javob = client.post("/sozlamalar", json={"biror_kalit": "qiymat"}, headers=rahbar_headers)
    assert javob.status_code == 403


def test_admin_rahbar_royxatga_foydalanuvchi_qosha_oladi(client, admin_headers):
    """Admin panelidagi "Foydalanuvchi qo'shish" formasi endi "rahbar"
    rolini ham yaratishi kerak - schemas.py'dagi RUXSAT_ETILGAN_ROLLAR
    orqali tasdiqlanadi."""
    javob = client.post("/users", json={
        "username": "yangi_rahbar", "password": "parol123", "role": "rahbar",
    }, headers=admin_headers)
    assert javob.status_code == 200
    assert javob.json()["role"] == "rahbar"
