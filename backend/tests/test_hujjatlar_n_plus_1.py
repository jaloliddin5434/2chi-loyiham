"""6-band: GET /hujjatlar, GET /hujjatlar/eksport va GET /navbat avval
sahifadagi/ro'yxatdagi HAR BIR qator uchun alohida (N+1) so'rov
yuborardi. Bu testlar (a) natija to'g'riligi o'zgarmaganini va (b)
so'rovlar soni endi hujjatlar/navbat soniga QARAM EMASLIGINI (bir nechta
hujjat qo'shilsa ham so'rovlar soni deyarli o'zgarmasligini) tekshiradi."""
import pytest
from sqlalchemy import event

import main as m


@pytest.fixture()
def mashina(db_session):
    from models import Mashina
    mash = Mashina(davlat_raqami="01A999AA", turi="FAW", shofyor="N+1 Shofyor",
                    firma="N+1 Firma", viloyat="Xorazm", telefon=None)
    db_session.add(mash)
    db_session.commit()
    db_session.refresh(mash)
    return mash


def _hujjat_va_olchov_yarat(client, admin_headers, mahsulot_id, mashina_id, raqam_ustama):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_id, "mashina_id": mashina_id,
    }, headers=admin_headers)
    hid = javob.json()["id"]
    client.post("/olchovlar", json={
        "hujjat_id": hid, "arava_raqam": 1, "tara": 1000 + raqam_ustama, "brutto": 3000 + raqam_ustama,
    }, headers=admin_headers)
    return hid


def _sorovlar_sonini_sanab(callable_fn):
    soni = {"n": 0}

    def _hisobla(*args, **kwargs):
        soni["n"] += 1

    event.listen(m.engine, "before_cursor_execute", _hisobla)
    try:
        natija = callable_fn()
    finally:
        event.remove(m.engine, "before_cursor_execute", _hisobla)
    return natija, soni["n"]


def test_royxat_olchov_togri_qaytaradi_va_sorovlar_soni_hujjatga_qaram_emas(
        client, admin_headers, mahsulot_chigit, mashina):
    for i in range(5):
        _hujjat_va_olchov_yarat(client, admin_headers, mahsulot_chigit.id, mashina.id, i * 10)

    javob, sorovlar_1 = _sorovlar_sonini_sanab(
        lambda: client.get("/hujjatlar", headers=admin_headers))
    assert javob.status_code == 200
    natijalar = javob.json()["natijalar"]
    assert len(natijalar) >= 5
    # Netto to'g'ri hisoblanganini tekshiramiz (batch so'rov ham xuddi
    # oldingi N+1 so'rov kabi to'g'ri qiymat qaytarishi kerak).
    birinchi = next(h for h in natijalar if h["tara"] == 1000)
    assert birinchi["brutto"] == 3000
    assert birinchi["netto"] == 2000

    for i in range(5, 10):
        _hujjat_va_olchov_yarat(client, admin_headers, mahsulot_chigit.id, mashina.id, i * 10)

    _, sorovlar_2 = _sorovlar_sonini_sanab(
        lambda: client.get("/hujjatlar", headers=admin_headers))

    # Hujjatlar soni ikki barobardan ko'proq oshdi (5 -> 10+), lekin
    # so'rovlar soni N+1 bo'lganda ham shunga yarasha oshgan bo'lardi -
    # endi deyarli o'zgarmasligi kerak (bir nechta qo'shimcha so'rov
    # farqi normal, lekin hujjat sonига proportsional o'sish EMAS).
    assert sorovlar_2 <= sorovlar_1 + 2, (
        f"So'rovlar soni hujjatlar soniga qarab o'sib bormoqda (N+1 hali bor): "
        f"{sorovlar_1} -> {sorovlar_2}"
    )


def _navbat_qosh(client, admin_headers, hid, mashina, mahsulot_id):
    client.post("/navbat/qosh", json={
        "hujjatId": hid, "mashinaId": mashina.id, "raqam": mashina.davlat_raqami,
        "mahsulotId": mahsulot_id, "mahsulotNomi": "Chigit",
    }, headers=admin_headers)


def test_50_hujjat_bilan_sorovlar_soni_kichik_va_deyarli_ozgarmas(
        client, admin_headers, mahsulot_chigit, mashina):
    """Kattaroq, aniqroq tekshiruv: 10 ta va 50 ta hujjat bilan so'rovlar
    soni deyarli bir xil bo'lishi kerak. N+1 bo'lganda 10 ta -> ~11,
    50 ta -> ~51 so'rov bo'lardi; batch (.in_) bilan ikkalasi ham
    o'zgarmas, kichik son (odatda 3-4)."""
    for i in range(10):
        hid = _hujjat_va_olchov_yarat(client, admin_headers, mahsulot_chigit.id, mashina.id, i)
        _navbat_qosh(client, admin_headers, hid, mashina, mahsulot_chigit.id)

    _, hujjatlar_10 = _sorovlar_sonini_sanab(
        lambda: client.get("/hujjatlar?sahifa_hajmi=100", headers=admin_headers))
    _, navbat_10 = _sorovlar_sonini_sanab(
        lambda: client.get("/navbat", headers=admin_headers))
    _, eksport_10 = _sorovlar_sonini_sanab(
        lambda: client.get(f"/hujjatlar/eksport?mahsulot_id={mahsulot_chigit.id}",
                            headers=admin_headers))

    for i in range(10, 50):
        hid = _hujjat_va_olchov_yarat(client, admin_headers, mahsulot_chigit.id, mashina.id, i)
        _navbat_qosh(client, admin_headers, hid, mashina, mahsulot_chigit.id)

    javob, hujjatlar_50 = _sorovlar_sonini_sanab(
        lambda: client.get("/hujjatlar?sahifa_hajmi=100", headers=admin_headers))
    navbat_javob, navbat_50 = _sorovlar_sonini_sanab(
        lambda: client.get("/navbat", headers=admin_headers))
    _, eksport_50 = _sorovlar_sonini_sanab(
        lambda: client.get(f"/hujjatlar/eksport?mahsulot_id={mahsulot_chigit.id}",
                            headers=admin_headers))

    # Mutlaq chegara: 50 ta hujjat uchun ham har endpoint 10 tadan kam
    # so'rov yuborishi kerak (N+1 bo'lsa 50+ bo'lardi).
    assert hujjatlar_50 < 10, f"GET /hujjatlar: 50 hujjat uchun {hujjatlar_50} so'rov (N+1?)"
    assert navbat_50 < 10, f"GET /navbat: 50 qator uchun {navbat_50} so'rov (N+1?)"
    assert eksport_50 < 10, f"GET /hujjatlar/eksport: 50 hujjat uchun {eksport_50} so'rov (N+1?)"

    # Proporsional o'sish YO'Q: hujjatlar soni 5 barobar oshdi (10->50),
    # so'rovlar soni esa ~o'zgarmas (kichik doimiy farqqa yo'l qo'yiladi).
    assert hujjatlar_50 <= hujjatlar_10 + 1
    assert navbat_50 <= navbat_10 + 1
    assert eksport_50 <= eksport_10 + 1

    # Ma'lumot yo'qolmadi: 50 tasi ham qaytdi, netto to'g'ri.
    natijalar = javob.json()["natijalar"]
    assert len(natijalar) == 50
    assert javob.json()["jami"] == 50
    for h in natijalar:
        assert h["netto"] == 2000  # brutto(3000+i) - tara(1000+i) = 2000 (i bekor bo'ladi)
    assert len(navbat_javob.json()) == 50


def test_eksport_olchov_togri_qaytaradi(client, admin_headers, mahsulot_chigit, mashina):
    _hujjat_va_olchov_yarat(client, admin_headers, mahsulot_chigit.id, mashina.id, 0)

    javob = client.get(f"/hujjatlar/eksport?mahsulot_id={mahsulot_chigit.id}", headers=admin_headers)
    assert javob.status_code == 200


def test_navbat_hujjat_raqamini_togri_qaytaradi(client, admin_headers, mahsulot_chigit, mashina):
    hid = _hujjat_va_olchov_yarat(client, admin_headers, mahsulot_chigit.id, mashina.id, 0)
    hujjat = client.get(f"/hujjatlar/{hid}", headers=admin_headers).json()

    client.post("/navbat/qosh", json={
        "hujjatId": hid, "mashinaId": mashina.id, "raqam": mashina.davlat_raqami,
        "mahsulotId": mahsulot_chigit.id, "mahsulotNomi": "Chigit",
    }, headers=admin_headers)

    javob = client.get("/navbat", headers=admin_headers)
    assert javob.status_code == 200
    qator = next(n for n in javob.json() if n["hujjatId"] == hid)
    assert qator["hujjatRaqam"] == hujjat["raqam"]
