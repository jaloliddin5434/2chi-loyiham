"""POST /navbat/qosh - agar shu hujjat_id uchun eski Navbat yozuvi
allaqachon mavjud bo'lsa, avval o'chirilib, keyin yangisi yaratiladi.
Bu ikkalasi BITTA tranzaksiyada bo'lishi kerak - agar yangisini
yaratishda xato chiqsa, eski yozuv o'chirilgan holda yo'qolib
qolmasligi (mashina navbatdan "g'oyib bo'lishi") kerak emas.
"""
import pytest
from unittest.mock import patch


@pytest.fixture()
def hujjat(client, admin_headers, mahsulot_chigit, mashina):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
    }, headers=admin_headers)
    return javob.json()


def _navbat_payload(hujjat_id, mashina_id):
    return {
        "hujjatId": hujjat_id,
        "mashinaId": mashina_id,
        "raqam": "01A123BB",
        "turi": "FAW",
        "shofyor": "Test Shofyor",
        "firma": "Test Firma",
        "mahsulotId": 1,
        "mahsulotNomi": "Chigit",
        "vaqt": "2026-08-07 10:00",
    }


def test_ikkinchi_qoshish_eskisini_almashtiradi(
        client, admin_headers, hujjat, mashina, db_session):
    from models import Navbat

    javob1 = client.post("/navbat/qosh", json=_navbat_payload(hujjat["id"], mashina.id),
                          headers=admin_headers)
    assert javob1.status_code == 200
    assert db_session.query(Navbat).filter(Navbat.hujjat_id == hujjat["id"]).count() == 1

    javob2 = client.post("/navbat/qosh", json=_navbat_payload(hujjat["id"], mashina.id),
                          headers=admin_headers)
    assert javob2.status_code == 200
    # Almashtirilgandan keyin ham FAQAT bitta yozuv bo'lishi kerak
    # (eskisi o'chib, bitta yangisi qo'shilgan - ikkitasi emas).
    assert db_session.query(Navbat).filter(Navbat.hujjat_id == hujjat["id"]).count() == 1


def test_yangisini_yaratishda_xato_bolsa_eskisi_yoqolmaydi(
        client, admin_headers, hujjat, mashina, db_session):
    """ASOSIY REGRESSIYA TESTI: eski yozuvni o'chirish va yangisini
    yaratish bitta tranzaksiyada ekanligini tasdiqlaydi - agar
    yangisini QURISHDA (obyekt yaratishda) xato chiqsa, eskisi HALI
    HAM bazada qolishi kerak (butunlay yo'qolib qolmasligi kerak)."""
    from models import Navbat

    javob1 = client.post("/navbat/qosh", json=_navbat_payload(hujjat["id"], mashina.id),
                          headers=admin_headers)
    assert javob1.status_code == 200
    eski_id = db_session.query(Navbat).filter(Navbat.hujjat_id == hujjat["id"]).first().id

    # Yangi Navbat obyekti QURILAYOTGANDA (eski allaqachon db.delete()
    # bilan belgilangandan KEYIN, lekin commit'dan OLDIN) sun'iy xato
    # chaqiramiz - aynan shu payt eski koddagi xavfli oraliq edi.
    asl_init = Navbat.__init__

    def buzilgan_init(self, *args, **kwargs):
        raise ValueError("Sun'iy xato - yangi Navbat qurilayotganda (test)")

    # TestClient standart holatda server xatolarini QAYTA OTADI (500
    # javob emas) - shu sabab bu yerda pytest.raises bilan kutamiz.
    with patch.object(Navbat, "__init__", buzilgan_init):
        with pytest.raises(ValueError, match="Sun'iy xato"):
            client.post("/navbat/qosh", json=_navbat_payload(hujjat["id"], mashina.id),
                         headers=admin_headers)

    # ENG MUHIM TEKSHIRUV: eski yozuv HALI HAM bazada turibdi -
    # tranzaksiya to'liq bekor qilingan (rollback), "o'chirilgan, lekin
    # yangisi yo'q" oraliq holatda QOLMAGAN.
    db_session.expire_all()
    qolganlar = db_session.query(Navbat).filter(Navbat.hujjat_id == hujjat["id"]).all()
    assert len(qolganlar) == 1, (
        f"Navbat yozuvi yo'qolib qoldi! (topildi: {len(qolganlar)} ta, "
        f"eski id={eski_id})")
    assert qolganlar[0].id == eski_id
