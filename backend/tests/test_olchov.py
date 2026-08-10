"""
POST /olchovlar - o'lchov saqlash: yangi arava qo'shish, xuddi shu
arava_raqam bilan qayta yuborilganda YANGILANISHI (dublikat qator EMAS),
va netto/konditsion avtomatik hisoblanishi.
"""
import pytest


@pytest.fixture()
def hujjat(client, admin_headers, mahsulot_chigit, mashina):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
    }, headers=admin_headers)
    return javob.json()


def test_olchov_yangi_arava_qoshiladi(client, admin_headers, hujjat):
    javob = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "tara": 1000, "brutto": 3000,
    }, headers=admin_headers)
    assert javob.status_code == 200
    natija = javob.json()
    assert natija["tara"] == 1000
    assert natija["brutto"] == 3000
    # netto = brutto - tara avtomatik hisoblanishi kerak.
    assert natija["netto"] == 2000


def test_olchov_konditsion_avtomatik_hisoblanadi(client, admin_headers, hujjat):
    from utils import konditsion_hisobla
    javob = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1,
        "tara": 1000, "brutto": 3000, "namlik": 5.0, "ifloslik": 3.0,
    }, headers=admin_headers)
    natija = javob.json()
    kutilgan_konditsion = konditsion_hisobla(2000, 5.0, 3.0)
    assert natija["konditsion"] == pytest.approx(kutilgan_konditsion)


def test_olchov_xuddi_shu_arava_yangilanadi_dublikat_bolmaydi(client, admin_headers, hujjat):
    # 1-qadam: faqat TARA saqlanadi (operator ekranidagi haqiqiy oqim).
    javob1 = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "tara": 1000,
    }, headers=admin_headers)
    assert javob1.status_code == 200
    assert javob1.json()["tara"] == 1000
    assert javob1.json()["brutto"] is None

    # 2-qadam: xuddi shu arava_raqam uchun endi BRUTTO ham qo'shiladi -
    # bu YANGI qator EMAS, birinchisi YANGILANISHI kerak (tara saqlanib
    # qolishi, id o'zgarmasligi).
    javob2 = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "brutto": 3000,
    }, headers=admin_headers)
    assert javob2.status_code == 200
    natija2 = javob2.json()
    assert natija2["id"] == javob1.json()["id"]
    assert natija2["tara"] == 1000  # eskisi yo'qolmagan
    assert natija2["brutto"] == 3000
    assert natija2["netto"] == 2000

    # 3-qadam: shu hujjat uchun jami bitta qator bo'lishi kerak (dublikat yo'q).
    royxat = client.get(f"/olchovlar/{hujjat['id']}", headers=admin_headers)
    assert len(royxat.json()) == 1


def test_ikkita_alohida_arava_ikkita_qator_yaratadi(client, admin_headers, hujjat):
    client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "tara": 1000, "brutto": 3000,
    }, headers=admin_headers)
    client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 2, "tara": 1100, "brutto": 3200,
    }, headers=admin_headers)
    royxat = client.get(f"/olchovlar/{hujjat['id']}", headers=admin_headers)
    assert len(royxat.json()) == 2


def test_minimal_ogirlikdan_past_tara_rad_etiladi(client, admin_headers, hujjat):
    """Real productionda topilgan xato: tarozi platformasida hech narsa
    yo'qligi yoki shovqin sabab juda kichik (hatto manfiy netto beruvchi)
    qiymatlar to'siqsiz saqlanardi. Endi hech qanday haqiqiy mashina/
    aravaga mos kelmaydigan (chegaradan past) qiymat rad etiladi.
    Chegaraning o'zi (_OLCHOV_MINIMAL_OGIRLIK_KG) main.py'dan o'qiladi -
    shu bilan test qiymati sozlansa ham (masalan sinov uchun) test
    buzilmaydi."""
    import main
    past_qiymat = main._OLCHOV_MINIMAL_OGIRLIK_KG - 1

    javob = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "tara": past_qiymat,
    }, headers=admin_headers)
    assert javob.status_code == 400

    royxat = client.get(f"/olchovlar/{hujjat['id']}", headers=admin_headers)
    assert royxat.json() == []


def test_minimal_ogirlikdan_past_brutto_rad_etiladi(client, admin_headers, hujjat):
    import main
    past_qiymat = main._OLCHOV_MINIMAL_OGIRLIK_KG - 1

    javob = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "tara": 1000, "brutto": past_qiymat,
    }, headers=admin_headers)
    assert javob.status_code == 400


def test_minimal_ogirlik_chegarasining_ozi_qabul_qilinadi(client, admin_headers, hujjat):
    import main

    javob = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1,
        "tara": main._OLCHOV_MINIMAL_OGIRLIK_KG, "brutto": 3000,
    }, headers=admin_headers)
    assert javob.status_code == 200


def test_mavjud_bolmagan_hujjat_id_404_qaytaradi(client, admin_headers):
    """Avval hujjat_id mavjudligi OLDINDAN tekshirilmasdi - notogri ID
    yuborilsa, Olchov.hujjat_id'dagi FK cheklovi xom holda otilib,
    chiroyli 404 ornida tushunarsiz 500 xato berardi."""
    javob = client.post("/olchovlar", json={
        "hujjat_id": 999999, "arava_raqam": 1, "tara": 15000, "brutto": 25000,
    }, headers=admin_headers)
    assert javob.status_code == 404


def test_namlik_yoki_ifloslik_0_bolsa_ham_konditsion_hisoblanadi(client, admin_headers, hujjat):
    """Real xato: namlik=0 yoki ifloslik=0 (masalan mutlaqo toza paxta)
    haqiqiy, yaroqli qiymat - lekin avvalgi kod `if namlik and ifloslik:`
    (truthy tekshiruv) ishlatgani uchun bunday hollarda konditsion HECH
    QACHON hisoblanmasdi, garchi haqiqiy ma'lumot kiritilgan bo'lsa ham."""
    from utils import konditsion_hisobla

    javob = client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1,
        "tara": 1000, "brutto": 3000, "namlik": 0, "ifloslik": 0,
    }, headers=admin_headers)
    assert javob.status_code == 200
    natija = javob.json()
    assert natija["konditsion"] == pytest.approx(konditsion_hisobla(2000, 0, 0))
    assert natija["konditsion"] is not None
