"""To'liq (end-to-end) operator jarayoni - 4 ta mahsulot turi
(konditsiyali "Chigit-turi" va uchta konditsiyasiz - "Chiganoq",
"Pochog", "Patoz" turlari) uchun ALOHIDA test: real login -> mashina
yaratish -> hujjat yaratish -> TARA o'lchash -> ma'lumot (firma/tiket)
kiritish -> navbatga qo'shish -> BRUTTO o'lchash -> tugallash -> HAQIQIY
nakladnoy PDF generatsiyasi (Playwright) -> HAQIQIY Excel jurnaliga
yozish -> disk fayllari tekshiriladi.

MUHIM ARXITEKTURA QARORI - nega bu fayl `client`/`db_session`
fixturalarini ISHLATMAYDI:
    POST /navbat/tugallandi -> background_tasks.add_task(excel_qatorga_
    yoz_fon, ...) -> bu funksiya O'ZINING ALOHIDA SessionLocal()
    ulanishini ochadi. `client`/`db_session` fixturasi esa har testni
    BITTA tashqi tranzaksiya + SAVEPOINT'lar ichida ishlatadi (hech
    qachon HAQIQIY commit qilinmaydi, test oxirida ROLLBACK). Natijada
    excel_qatorga_yoz_fon()ning alohida ulanishi hujjat/o'lchov
    qatorlarini UMUMAN KO'RMAS EDI (qarang: test_excel_fon_yozuvi.py -
    xuddi shu sabab bilan u ham shu fixturalardan voz kechgan).
    Shu sabab bu yerda xom `TestClient(main.app)` ishlatiladi (get_db
    override qilinmagan holda) - barcha yozuvlar HAQIQIY commit
    qilinadi, lekin baribir xavfsiz: conftest.py butun test sessiyasi
    uchun DATABASE_URL'ni alohida "hazorasp_tarozi_test" bazasiga
    almashtirgan (production bazasiga HECH QANDAY yozuv bormaydi).
    Yaratilgan barcha qatorlar test oldidan VA oxirida (muvaffaqiyatli
    yoki muvaffaqiyatsiz bo'lishidan qat'i nazar) aniq prefiks bo'yicha
    qo'lda tozalanadi.

RASMLAR_DIR haqiqiy "C:/RASMLAR" ga EMAS, pytest'ning vaqtinchalik
`tmp_path`iga yo'naltiriladi (monkeypatch) - shu bilan Excel/PDF/HTML
fayllar HAQIQIY yoziladi va tekshiriladi, lekin production papkasiga
hech qanday ta'sir qilmaydi.
"""
import uuid
from datetime import date
from pathlib import Path

import openpyxl
import pytest
from fastapi.testclient import TestClient

import main
from auth import hash_password
from database import SessionLocal
from models import Hujjat, HujjatHolati, Mahsulot, Mashina, Navbat, Olchov, User
from utils import xavfsiz_papka_nomi

MASHINA_PREFIKS = "E2E"
OPERATOR_LOGIN = "e2e_toliq_operator"


def _ip():
    return f"10.98.{uuid.uuid4().fields[0] % 255}.{uuid.uuid4().fields[1] % 255}"


def _tozala(mahsulot_nomlari):
    """Hujjat.raqam AVTOMATIK (MAHSULOT_RAQAM_PREFIKS + yil + ketma-ket
    raqam) generatsiya qilinadi - bizning RAQAM_PREFIKS bilan hech
    qanday aloqasi yo'q, shu sabab tozalash Mashina.davlat_raqami
    prefiksi orqali (biz to'liq nazorat qiladigan yagona maydon)
    amalga oshiriladi."""
    db = SessionLocal()
    try:
        mashina_idlar = [m.id for m in db.query(Mashina).filter(
            Mashina.davlat_raqami.like(f"{MASHINA_PREFIKS}%")).all()]
        if mashina_idlar:
            hujjat_idlar = [h.id for h in db.query(Hujjat).filter(
                Hujjat.mashina_id.in_(mashina_idlar)).all()]
            if hujjat_idlar:
                db.query(Olchov).filter(Olchov.hujjat_id.in_(hujjat_idlar)).delete(synchronize_session=False)
                db.query(Navbat).filter(Navbat.hujjat_id.in_(hujjat_idlar)).delete(synchronize_session=False)
                db.query(Hujjat).filter(Hujjat.id.in_(hujjat_idlar)).delete(synchronize_session=False)
            db.query(Mashina).filter(Mashina.id.in_(mashina_idlar)).delete(synchronize_session=False)
        db.query(User).filter(User.username == OPERATOR_LOGIN).delete(synchronize_session=False)
        for nom in mahsulot_nomlari:
            db.query(Mahsulot).filter(Mahsulot.nom == nom).delete(synchronize_session=False)
        db.commit()
    finally:
        db.close()


def _qatorni_top(ws, mashina_raqami):
    for row in ws.iter_rows(values_only=True):
        if mashina_raqami in row:
            return row
    return None


@pytest.fixture()
def xom_client(tmp_path, monkeypatch):
    """`main.app.dependency_overrides` HECH KIM tomonidan o'rnatilmagan
    (chunki `client`/`db_session` fixturalari so'ralmagan) - shu sabab
    bu TestClient REAL get_db() orqali ishlaydi (real commit)."""
    monkeypatch.setattr(main, "RASMLAR_DIR", str(tmp_path))
    yield TestClient(main.app), tmp_path


def _toliq_oqim(xom_client, mahsulot_nomi, konditsiya_bor, mashina_raqami,
                 tara, brutto, namlik=None, ifloslik=None):
    client, rasmlar_papkasi = xom_client
    _tozala([mahsulot_nomi])  # oldingi uzilib qolgan urinishdan qoldiq bo'lsa
    try:
        db = SessionLocal()
        try:
            mahsulot = Mahsulot(nom=mahsulot_nomi, konditsiya_bor=konditsiya_bor, is_active=True)
            db.add(mahsulot)
            if not db.query(User).filter(User.username == OPERATOR_LOGIN).first():
                db.add(User(username=OPERATOR_LOGIN, password=hash_password("parol123"),
                            role="operator", is_active=True))
            db.commit()
            db.refresh(mahsulot)
            mahsulot_id = mahsulot.id
        finally:
            db.close()

        # --- 1. Operator login ---
        login_javob = client.post("/login", json={
            "username": OPERATOR_LOGIN, "password": "parol123", "role": "operator",
        }, headers={"CF-Connecting-IP": _ip()})
        assert login_javob.status_code == 200, login_javob.text
        token = login_javob.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # --- 2. Yangi mashina qo'shish ---
        mashina_javob = client.post("/mashinalar", json={
            "davlat_raqami": mashina_raqami, "turi": "Kamaz", "shofyor": "E2E Shofyor",
            "firma": "E2E Boshlang'ich Firma", "viloyat": "Xorazm",
        }, headers=headers)
        assert mashina_javob.status_code == 200, mashina_javob.text
        mashina = mashina_javob.json()

        # --- 3. Hujjat yaratish (aravalar_soni=1) ---
        hujjat_javob = client.post("/hujjatlar", json={
            "mashina_id": mashina["id"], "mahsulot_id": mahsulot_id, "aravalar_soni": 1,
        }, headers=headers)
        assert hujjat_javob.status_code == 200, hujjat_javob.text
        hujjat = hujjat_javob.json()
        assert hujjat["aravalar_soni"] == 1

        # --- 4. TARA o'lchash (namlik/ifloslik shu bosqichda kiritiladi) ---
        tara_javob = client.post("/olchovlar", json={
            "hujjat_id": hujjat["id"], "arava_raqam": 1, "tara": tara,
            "namlik": namlik, "ifloslik": ifloslik,
        }, headers=headers)
        assert tara_javob.status_code == 200, tara_javob.text
        assert tara_javob.json()["tara"] == tara
        assert tara_javob.json()["brutto"] is None

        # --- 5. Ma'lumot kiritish: firma, tiket ---
        put_javob = client.put(f"/hujjatlar/{hujjat['id']}", json={
            "firma": "E2E Yakuniy Firma", "tiket_raqam": "7654321",
            "sabab": "E2E to'liq oqim testi - ma'lumot kiritildi",
        }, headers=headers)
        assert put_javob.status_code == 200, put_javob.text
        assert put_javob.json()["firma"] == "E2E Yakuniy Firma"
        assert put_javob.json()["tiket_raqam"] == "7654321"

        # --- 6. Navbatga qo'shish ---
        navbat_javob = client.post("/navbat/qosh", json={
            "hujjatId": hujjat["id"], "mashinaId": mashina["id"], "raqam": mashina_raqami,
            "turi": "Kamaz", "shofyor": "E2E Shofyor", "firma": "E2E Yakuniy Firma",
            "mahsulotId": mahsulot_id, "mahsulotNomi": mahsulot_nomi, "vaqt": "10:00",
            "tiketRaqam": "7654321", "aravalar": {},
        }, headers=headers)
        assert navbat_javob.status_code == 200, navbat_javob.text

        royxat = client.get("/navbat", headers=headers).json()
        qator = next((x for x in royxat if x["hujjatId"] == hujjat["id"]), None)
        assert qator is not None, "Mashina navbat ro'yxatida ko'rinmadi"
        assert qator["aravalarSoni"] == 1

        # --- 7. BRUTTO o'lchash ---
        brutto_javob = client.post("/olchovlar", json={
            "hujjat_id": hujjat["id"], "arava_raqam": 1, "brutto": brutto,
        }, headers=headers)
        assert brutto_javob.status_code == 200, brutto_javob.text
        kutilgan_netto = brutto - tara
        assert brutto_javob.json()["netto"] == pytest.approx(kutilgan_netto)

        # --- 8. Navbatni tugallash (HAQIQIY Excel yozuvi shu yerda,
        # background_tasks orqali, TestClient javob qaytishidan OLDIN
        # sinxron bajaradi) ---
        tugallandi_javob = client.post("/navbat/tugallandi", json={
            "hujjatId": hujjat["id"], "aravalar": {},
        }, headers=headers)
        assert tugallandi_javob.status_code == 200, tugallandi_javob.text

        db = SessionLocal()
        try:
            hujjat_db = db.query(Hujjat).filter(Hujjat.id == hujjat["id"]).first()
            assert hujjat_db.holat == HujjatHolati.TUGALLANDI, (
                f"Hujjat holati 'tugallandi' emas: {hujjat_db.holat}")
        finally:
            db.close()

        # GET /navbat/tugallanganlar ro'yxatida ko'rinishi kerak.
        tugallanganlar = client.get("/navbat/tugallanganlar", headers=headers).json()
        assert any(x["hujjatId"] == hujjat["id"] for x in tugallanganlar)

        # --- 9. Nakladnoy PDF/HTML generatsiyasi (HAQIQIY Playwright) ---
        sana_bugun = date.today().isoformat()
        nakladnoy_javob = client.post("/nakladnoy/saqlash", json={
            "hujjat_id": hujjat["id"], "mashina_raqami": mashina_raqami,
            "mahsulot_nomi": mahsulot_nomi, "sana": sana_bugun,
            "nakladnoy_raqam": hujjat["raqam"],
        }, headers=headers)
        assert nakladnoy_javob.status_code == 200, nakladnoy_javob.text

        # --- 10. Nakladnoy QR-korish sahifasi (login talab qilmaydi) ---
        db = SessionLocal()
        try:
            hujjat_db = db.query(Hujjat).filter(Hujjat.id == hujjat["id"]).first()
            token_nakladnoy = hujjat_db.nakladnoy_token
        finally:
            db.close()
        assert token_nakladnoy, "nakladnoy_token o'rnatilmadi"
        korish_javob = client.get(f"/nakladnoy-korish/{token_nakladnoy}")
        assert korish_javob.status_code == 200
        assert mashina_raqami in korish_javob.text

        # --- 11. Rasmlar papkasi + nakladnoy.pdf/html haqiqatan diskda ---
        raqam_papka = xavfsiz_papka_nomi(mashina_raqami.replace(" ", "_"))
        mashina_papka = (Path(rasmlar_papkasi) / xavfsiz_papka_nomi(mahsulot_nomi)
                          / sana_bugun[:7] / sana_bugun / raqam_papka)
        assert (mashina_papka / "nakladnoy.pdf").exists(), \
            f"Nakladnoy PDF yaratilmadi: {mashina_papka}"
        assert (mashina_papka / "nakladnoy.pdf").stat().st_size > 0
        assert (mashina_papka / "nakladnoy.html").exists(), \
            f"Nakladnoy HTML yaratilmadi: {mashina_papka}"

        # --- 12. Excel jurnali (hisobot_<Mahsulot>_<yil>.xlsx) haqiqatan
        # diskda, to'g'ri qiymatlar bilan ---
        yil = date.today().year
        excel_fayl = (Path(rasmlar_papkasi) / xavfsiz_papka_nomi(mahsulot_nomi)
                      / f"hisobot_{mahsulot_nomi.replace(' ', '_')}_{yil}.xlsx")
        assert excel_fayl.exists(), f"Excel hisobot fayli yaratilmadi: {excel_fayl}"
        wb = openpyxl.load_workbook(excel_fayl)
        ws = wb.active
        qator = _qatorni_top(ws, mashina_raqami)
        assert qator is not None, "Yozilgan hujjatning qatori Excel faylida topilmadi"
        assert qator[4] == round(tara)
        assert qator[5] == round(brutto)
        assert qator[6] == round(kutilgan_netto)
        # Ustunlar tartibi konditsiya_bor'ga qarab farqlanadi - qarang:
        # main.py excel_qatorga_yoz_fon() (_jurnal_qator_yozuvchi).
        mashina_ustuni = 8 if konditsiya_bor else 7
        assert qator[mashina_ustuni] == mashina_raqami
    finally:
        _tozala([mahsulot_nomi])


def test_chigit_toliq_e2e_oqim(xom_client):
    _toliq_oqim(xom_client, "E2E Chigit", True, "E2E111CH",
                tara=18000, brutto=25500, namlik=8.5, ifloslik=2.0)


def test_chiganoq_toliq_e2e_oqim(xom_client):
    _toliq_oqim(xom_client, "E2E Chiganoq", False, "E2E222CG",
                tara=17000, brutto=23000)


def test_pochog_toliq_e2e_oqim(xom_client):
    _toliq_oqim(xom_client, "E2E Pochog", False, "E2E333PO",
                tara=16500, brutto=21000)


def test_patoz_toliq_e2e_oqim(xom_client):
    _toliq_oqim(xom_client, "E2E Patoz", False, "E2E444PZ",
                tara=15500, brutto=19800)
