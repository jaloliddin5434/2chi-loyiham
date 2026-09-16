"""DELETE /admin/sezon-tozala - yangi mavsum boshlanganda eski mavsum
ma'lumotlarini (hujjatlar, olchovlar, navbat, tahrir tarixi, tuzatish
so'rovlari) tozalaydi. Foydalanuvchilar, sozlamalar, mahsulotlar va
mashinalar TEGILMAYDI. Faqat admin chaqira oladi va qaytarib bo'lmaydigan
amal ekani uchun aniq tasdiq ({"tasdiqlayman": true}) talab qilinadi.
"""
import pytest

from models import Hujjat, Navbat, Olchov, TahrirTarixi, TuzatishSorovi, Sozlama, User, Mahsulot, Mashina


@pytest.fixture()
def hujjat(client, admin_headers, mahsulot_chigit, mashina):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
    }, headers=admin_headers)
    return javob.json()


@pytest.fixture()
def toliq_malumotlar(db_session, hujjat, admin_user):
    """Hujjatga bog'liq barcha turdagi qatorlarni (olchov, navbat, tahrir
    tarixi, tuzatish so'rovi) to'g'ridan-to'g'ri bazaga qo'shadi."""
    db_session.add(Olchov(hujjat_id=hujjat["id"], arava_raqam=1, tara=1000, brutto=3000))
    db_session.add(Navbat(hujjat_id=hujjat["id"], mashina_id=1, raqam="01A123BB",
                           mahsulot_id=1, mahsulot_nomi="Chigit"))
    db_session.add(TahrirTarixi(hujjat_id=hujjat["id"], maydon="klass",
                                 eski_qiymat="1", yangi_qiymat="2", sabab="test",
                                 ozgartirgan_user_id=admin_user.id,
                                 ozgartirgan_username=admin_user.username))
    db_session.add(TuzatishSorovi(hujjat_id=hujjat["id"], operator_login="test_operator",
                                   maydon_nomi="klass", yangi_qiymat="2", sabab="test"))
    db_session.commit()
    return hujjat


def test_operator_kira_olmaydi(client, operator_headers):
    javob = client.request("DELETE", "/admin/sezon-tozala", json={"tasdiqlayman": True}, headers=operator_headers)
    assert javob.status_code == 403


def test_rahbar_kira_olmaydi(client, rahbar_headers):
    javob = client.request("DELETE", "/admin/sezon-tozala", json={"tasdiqlayman": True}, headers=rahbar_headers)
    assert javob.status_code == 403


def test_tokensiz_401(client):
    javob = client.request("DELETE", "/admin/sezon-tozala", json={"tasdiqlayman": True})
    assert javob.status_code == 401


def test_tasdiqsiz_rad_etiladi(client, admin_headers, toliq_malumotlar, db_session):
    javob = client.request("DELETE", "/admin/sezon-tozala", json={}, headers=admin_headers)
    assert javob.status_code == 400
    # Hech narsa o'chirilmagan bo'lishi kerak.
    db_session.expire_all()
    assert db_session.query(Hujjat).count() == 1
    assert db_session.query(Olchov).count() == 1


def test_notogri_tasdiq_qiymati_rad_etiladi(client, admin_headers, toliq_malumotlar):
    javob = client.request("DELETE", "/admin/sezon-tozala", json={"tasdiqlayman": "ha"}, headers=admin_headers)
    assert javob.status_code == 400


def test_admin_hammasini_ochiradi(client, admin_headers, toliq_malumotlar, db_session):
    javob = client.request("DELETE", "/admin/sezon-tozala", json={"tasdiqlayman": True}, headers=admin_headers)
    assert javob.status_code == 200
    natija = javob.json()["ochirildi"]
    assert natija == {
        "tahrir_tarixi": 1, "tuzatish_sorovlari": 1, "olchovlar": 1,
        "navbat": 1, "hujjatlar": 1,
    }

    db_session.expire_all()
    assert db_session.query(Hujjat).count() == 0
    assert db_session.query(Olchov).count() == 0
    assert db_session.query(Navbat).count() == 0
    assert db_session.query(TahrirTarixi).count() == 0
    assert db_session.query(TuzatishSorovi).count() == 0


def test_foydalanuvchi_sozlama_mahsulot_mashina_saqlanadi(
        client, admin_headers, toliq_malumotlar, db_session, mahsulot_chigit, mashina):
    db_session.add(Sozlama(kalit="test_kalit", qiymat="test_qiymat"))
    db_session.commit()

    javob = client.request("DELETE", "/admin/sezon-tozala", json={"tasdiqlayman": True}, headers=admin_headers)
    assert javob.status_code == 200

    db_session.expire_all()
    assert db_session.query(User).count() > 0
    assert db_session.query(Sozlama).filter(Sozlama.kalit == "test_kalit").count() == 1
    assert db_session.query(Mahsulot).filter(Mahsulot.id == mahsulot_chigit.id).count() == 1
    assert db_session.query(Mashina).filter(Mashina.id == mashina.id).count() == 1
