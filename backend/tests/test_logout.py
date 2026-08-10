"""POST /logout - joriy tokenni qora ro'yxatga qo'shib, DARHOL
yaroqsizlantiradi (JWT o'zining tabiiy muddati - 8 soat - tugashini
kutmasdan). Avval bunday endpoint umuman yo'q edi - "chiqish" faqat
frontend tokenni mahalliy o'chirishi bilan cheklanardi, token o'zi hali
ham amal qilardi."""
from models import QoraRoyxatToken


def test_logout_keyin_eski_token_ishlamay_qoladi(client, admin_headers):
    # Token hali logout qilinmagan - oddiy so'rov ishlashi kerak.
    javob0 = client.get("/mashinalar", headers=admin_headers)
    assert javob0.status_code == 200

    javob = client.post("/logout", headers=admin_headers)
    assert javob.status_code == 200

    # XUDDI SHU token endi ishlamasligi kerak - garchi muddati hali
    # tugamagan bo'lsa ham.
    javob2 = client.get("/mashinalar", headers=admin_headers)
    assert javob2.status_code == 401


def test_logout_qora_royxatga_yozadi(client, admin_headers, db_session):
    oldingi_soni = db_session.query(QoraRoyxatToken).count()
    client.post("/logout", headers=admin_headers)
    db_session.expire_all()
    assert db_session.query(QoraRoyxatToken).count() == oldingi_soni + 1


def test_boshqa_foydalanuvchi_tokeni_logoutdan_tegilmaydi(
        client, admin_headers, operator_headers):
    """Bitta foydalanuvchining logout qilishi FAQAT o'sha bitta
    sessiyaga (tokenga) tegishi kerak - boshqa foydalanuvchi (yoki
    o'sha foydalanuvchining boshqa qurilmadagi) tokeni ishlab turishi
    kerak."""
    client.post("/logout", headers=admin_headers)

    # admin tokeni endi ishlamaydi.
    assert client.get("/mashinalar", headers=admin_headers).status_code == 401
    # operator tokeni hali ishlashi kerak.
    assert client.get("/mashinalar", headers=operator_headers).status_code == 200


def test_tokensiz_logout_401_qaytaradi(client):
    javob = client.post("/logout")
    assert javob.status_code == 401


def test_ikki_marta_logout_xato_bermaydi(client, admin_headers):
    """Ikkinchi logout urinishi (masalan tarmoq xatosi tufayli frontend
    qayta yuborsa) - token allaqachon qora ro'yxatda bo'lgani uchun
    401 (get_current_user orqali) qaytadi, lekin server ICHIDA xato
    (500) chiqmasligi kerak."""
    client.post("/logout", headers=admin_headers)
    javob = client.post("/logout", headers=admin_headers)
    # Token allaqachon qora ro'yxatda - get_current_user uni 401 bilan
    # rad etadi (ikkinchi marta yozishga urinish emas).
    assert javob.status_code == 401
