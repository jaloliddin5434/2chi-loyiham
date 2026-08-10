"""
GET /hujjatlar va GET /hujjatlar/{id} - operator ekrani klass/sinf/
seleksiya_navi/terim_turi/tiket_raqam/tuda_raqam ni to'g'ridan-to'g'ri
Hujjat'ga emas, alohida Navbat jadvaliga saqlaydi (arxitekturaviy
qaror, loyihaning birinchi commit'idanoq shunday). Bu ikki endpoint
Hujjat'ning o'zida bo'sh bo'lgan qiymatlarni Navbat'dan to'ldirishi
kerak - aks holda admin panelidagi "Tuzat" oynasi bu maydonlarni
bo'sh ko'rsatadi, garchi operator ularni kiritgan bo'lsa ham.

Shuningdek namlik/ifloslik (Hujjat jadvalida ustun sifatida yo'q,
faqat Olchov'da bor) GET /hujjatlar/{id}da to'g'ri qaytishi kerak.
"""
import pytest


@pytest.fixture()
def hujjat(client, admin_headers, mahsulot_chigit, mashina):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
    }, headers=admin_headers)
    return javob.json()


def _navbat_yarat(db_session, hujjat_id, **maydonlar):
    from models import Navbat
    n = Navbat(hujjat_id=hujjat_id, mashina_id=1, raqam="TEST",
               mahsulot_id=1, mahsulot_nomi="Chigit", **maydonlar)
    db_session.add(n)
    db_session.commit()
    return n


def test_detail_navbatdan_toldiradi_hujjat_bosh_bolsa(
        client, admin_headers, hujjat, db_session):
    _navbat_yarat(db_session, hujjat["id"], tiket_raqam="123456",
                  klass="1", sinf="A", seleksiya_navi="Xorazm-150",
                  terim_turi="Kul terim", tuda_raqam="777")

    javob = client.get(f"/hujjatlar/{hujjat['id']}", headers=admin_headers)
    assert javob.status_code == 200
    natija = javob.json()
    assert natija["tiket_raqam"] == "123456"
    assert natija["klass"] == "1"
    assert natija["sinf"] == "A"
    assert natija["seleksiya_navi"] == "Xorazm-150"
    assert natija["terim_turi"] == "Kul terim"
    assert natija["tuda_raqam"] == "777"


def test_detail_navbatsiz_hali_ham_bosh_qaytadi(client, admin_headers, hujjat):
    # Navbat qatori umuman yo'q - hujjat ham bo'sh - hech narsa
    # o'ylab topilmasligi kerak (None qaytishi kerak, xato emas).
    javob = client.get(f"/hujjatlar/{hujjat['id']}", headers=admin_headers)
    assert javob.status_code == 200
    natija = javob.json()
    assert natija["klass"] is None
    assert natija["tiket_raqam"] is None


def test_detail_hujjat_qiymati_navbatdan_ustun_turadi(
        client, admin_headers, hujjat, db_session):
    # Hujjat'ning o'zida (masalan admin qo'lda kiritgan) qiymat bo'lsa,
    # Navbat'dagi (ehtimol eski/boshqacha) qiymat E'TIBORGA OLINMASLIGI
    # kerak - Hujjat har doim ustun turadi.
    from models import Hujjat
    db_session.query(Hujjat).filter(Hujjat.id == hujjat["id"]).update(
        {"klass": "2-admin-kiritgan"})
    _navbat_yarat(db_session, hujjat["id"], klass="1-operator-kiritgan")

    javob = client.get(f"/hujjatlar/{hujjat['id']}", headers=admin_headers)
    assert javob.json()["klass"] == "2-admin-kiritgan"


def test_detail_namlik_ifloslik_olchovdan_qaytadi(
        client, admin_headers, hujjat):
    client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1,
        "tara": 1000, "brutto": 3000, "namlik": 6.5, "ifloslik": 2.0,
    }, headers=admin_headers)

    javob = client.get(f"/hujjatlar/{hujjat['id']}", headers=admin_headers)
    natija = javob.json()
    assert natija["namlik"] == pytest.approx(6.5)
    assert natija["ifloslik"] == pytest.approx(2.0)


def test_royxat_navbatdan_toldiradi_hujjat_bosh_bolsa(
        client, admin_headers, hujjat, db_session):
    _navbat_yarat(db_session, hujjat["id"], tiket_raqam="999888",
                  klass="3", terim_turi="Qo'l terim")

    javob = client.get("/hujjatlar", headers=admin_headers)
    assert javob.status_code == 200
    satr = next(h for h in javob.json()["natijalar"] if h["id"] == hujjat["id"])
    assert satr["tiket_raqam"] == "999888"
    assert satr["klass"] == "3"
    assert satr["terim_turi"] == "Qo'l terim"


def test_royxat_ustunlar_hali_ham_toliq(client, admin_headers, hujjat):
    # Regressiya: mavjud (Navbat'ga bog'liq bo'lmagan) maydonlar
    # ustunlar buzilmasligi kerak.
    javob = client.get("/hujjatlar", headers=admin_headers)
    satr = next(h for h in javob.json()["natijalar"] if h["id"] == hujjat["id"])
    assert satr["raqam"] == hujjat["raqam"]
    assert satr["mahsulot_id"] == hujjat["mahsulot_id"]


def test_notogri_sana_formati_422_qaytaradi(client, admin_headers):
    """Avval sana_dan/sana_gacha `str` edi - istalgan matn to'g'ridan-
    to'g'ri SQL solishtirishga borib, PostgreSQL'da xom 500 xato
    berardi. Endi `date` turi FastAPI/Pydantic orqali OLDINDAN
    tekshiriladi, aniq 422 qaytishi kerak."""
    javob = client.get("/hujjatlar?sana_dan=notogri-sana", headers=admin_headers)
    assert javob.status_code == 422


def test_notogri_sana_formati_eksportda_ham_422_qaytaradi(client, admin_headers, mahsulot_chigit):
    javob = client.get(
        f"/hujjatlar/eksport?mahsulot_id={mahsulot_chigit.id}&sana_gacha=xxx",
        headers=admin_headers,
    )
    assert javob.status_code == 422


def test_togri_sana_formati_ishlayveradi(client, admin_headers, hujjat):
    javob = client.get("/hujjatlar?sana_dan=2020-01-01", headers=admin_headers)
    assert javob.status_code == 200
