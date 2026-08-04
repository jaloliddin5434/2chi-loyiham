"""
PUT /users/{id}/holat - foydalanuvchini faolsizlantirish/faollashtirish:
bloklangandan keyin login ishlamasligi, admin o'z-o'zini bloklay
olmasligi, va oxirgi faol adminni bloklab bo'lmasligi.
"""
from models import User
from auth import hash_password, create_access_token


def test_operatorni_faolsizlantirish_va_qayta_faollashtirish(
        client, admin_headers, operator_user):
    # Faolsizlantirish
    javob = client.put(f"/users/{operator_user.id}/holat", json={
        "is_active": False,
    }, headers=admin_headers)
    assert javob.status_code == 200
    assert javob.json()["is_active"] is False

    # Login endi ishlamasligi kerak.
    login_javob = client.post("/login", json={
        "username": operator_user.username, "password": "parol123", "role": "operator",
    }, headers={"X-Forwarded-For": "10.50.1.1"})
    assert login_javob.status_code == 401

    # Qayta faollashtirish
    javob2 = client.put(f"/users/{operator_user.id}/holat", json={
        "is_active": True,
    }, headers=admin_headers)
    assert javob2.status_code == 200
    assert javob2.json()["is_active"] is True

    # Login endi qayta ishlashi kerak.
    login_javob2 = client.post("/login", json={
        "username": operator_user.username, "password": "parol123", "role": "operator",
    }, headers={"X-Forwarded-For": "10.50.1.2"})
    assert login_javob2.status_code == 200


def test_admin_ozini_ozi_faolsizlantira_olmaydi(client, admin_headers, admin_user):
    javob = client.put(f"/users/{admin_user.id}/holat", json={
        "is_active": False,
    }, headers=admin_headers)
    assert javob.status_code == 400


def test_faolsizlantirilgan_foydalanuvchining_joriy_tokeni_ishlamay_qoladi(
        client, admin_headers, operator_user):
    """Audit orqali topilgan xavfsizlik teshigi: avval `is_active` FAQAT
    /login'da tekshirilardi - operator ALLAQACHON qo'lidagi (hali
    muddati tugamagan) tokeni bilan, faolsizlantirilgandan KEYIN ham,
    soatlab ishlayverardi. Endi HAR so'rovda bazadan tekshiriladi - shu
    tokenning o'zi darhol ishlamay qolishi kerak, yangi login qilmasdan
    ham."""
    # Operator "allaqachon qo'lida" tokenni oladi (login orqali emas,
    # to'g'ridan-to'g'ri - xuddi u avvalroq, hali faol paytida kirgan
    # va shu tokenni saqlab qolgandek).
    eski_token = create_access_token(
        {"sub": operator_user.username, "role": operator_user.role, "id": operator_user.id})
    eski_headers = {"Authorization": f"Bearer {eski_token}"}

    # Token hali faol - oddiy so'rov ishlashi kerak.
    javob0 = client.get("/mashinalar", headers=eski_headers)
    assert javob0.status_code == 200

    # Admin operatorni faolsizlantiradi.
    javob = client.put(f"/users/{operator_user.id}/holat", json={
        "is_active": False,
    }, headers=admin_headers)
    assert javob.status_code == 200

    # ESKI (hali muddati tugamagan) token bilan endi so'rov RAD ETILISHI
    # kerak - yangi login qilinmagan bo'lsa ham.
    javob2 = client.get("/mashinalar", headers=eski_headers)
    assert javob2.status_code == 401


def test_oxirgi_faol_adminni_faolsizlantirib_bolmaydi(
        client, admin_headers, admin_user, db_session):
    # Ikkinchi admin qo'shiladi, keyin faolsizlantiriladi - shu paytda
    # birinchi admin ("admin_user", chaqiruvchi) hali faol, shuning uchun
    # bu muvaffaqiyatli bo'lishi kerak (oxirgi admin emas).
    ikkinchi_admin = User(username="ikkinchi_admin", password=hash_password("parol123"),
                           role="admin", is_active=True)
    db_session.add(ikkinchi_admin)
    db_session.commit()
    db_session.refresh(ikkinchi_admin)

    javob = client.put(f"/users/{ikkinchi_admin.id}/holat", json={
        "is_active": False,
    }, headers=admin_headers)
    assert javob.status_code == 200
