"""
GET /hujjatlar/eksport - race condition tuzatildi.

Muammo edi: bu endpoint yangi Workbook'ni HAR DOIM diskka to'g'ridan-
to'g'ri, HECH QANDAY qulfsiz yozardi (wb.save(papka / fayl_nomi)).
Mavjud excel_qatorga_yoz() (fon jurnal yozuvi) esa xuddi shu turdagi
muammoni allaqachon _excel_fayl_qulfi() (fayl yo'liga xos
threading.Lock) bilan hal qilgan edi - lekin bu qulf shu (qo'lda,
"Excel" tugmasi orqali chaqiriladigan) eksport endpointida ISHLATILMAS
edi. Agar ikki admin AYNAN bir xil mahsulot+sana oralig'i uchun eksportni
bir vaqtda so'rasa (demak bir xil fayl yo'liga yozadi), ikkalasining
wb.save() chaqiruvi bir-biriga xalaqit berib, fayl buzilishi (yoki
Windows'da ikkinchisi "band fayl" xatosiga uchrashi) mumkin edi.

Tuzatish: main.py'dagi mavjud _excel_fayl_qulfi(fayl_yol) endi shu
endpointda ham ishlatiladi (faqat wb.save(...) chaqiruvi atrofida).

Bu fayl `client`/`db_session` fixturalaridan ATAYLAB FOYDALANMAYDI (xuddi
test_excel_fon_yozuvi.py'dagi kabi) - haqiqiy, mustaqil SessionLocal()
ulanishlari va HAQIQIY (real commit qilingan) ma'lumotlar bilan ishlaydi,
RASMLAR_DIR esa pytest'ning vaqtinchalik tmp_path'iga yo'naltiriladi
(haqiqiy production fayllariga hech qanday ta'sir qilmaydi).
"""
import shutil
import threading
import time
from datetime import datetime
from pathlib import Path

import openpyxl
import pytest

import main
from database import SessionLocal
from models import Hujjat, HujjatHolati, Mahsulot, Olchov
from utils import xavfsiz_papka_nomi

MAHSULOT_NOMI = "EksportQulfSinovi"
RAQAM_PREFIKS = "EKSPORTQULF-"


def _tozala():
    db = SessionLocal()
    try:
        eski = db.query(Hujjat).filter(Hujjat.raqam.like(f"{RAQAM_PREFIKS}%")).all()
        idlar = [h.id for h in eski]
        if idlar:
            db.query(Olchov).filter(Olchov.hujjat_id.in_(idlar)).delete(synchronize_session=False)
            db.query(Hujjat).filter(Hujjat.id.in_(idlar)).delete(synchronize_session=False)
        db.query(Mahsulot).filter(Mahsulot.nom == MAHSULOT_NOMI).delete(synchronize_session=False)
        db.commit()
    finally:
        db.close()
    papka = Path(main.RASMLAR_DIR) / MAHSULOT_NOMI
    if papka.exists():
        shutil.rmtree(papka)


@pytest.fixture()
def sinov_mahsuloti(tmp_path, monkeypatch):
    # RASMLAR_DIR pytest'ning vaqtinchalik papkasiga yo'naltiriladi -
    # xuddi test_excel_fon_yozuvi.py'dagi kabi, haqiqiy production
    # fayllariga tegmaslik uchun.
    monkeypatch.setattr(main, "RASMLAR_DIR", str(tmp_path))

    _tozala()
    db = SessionLocal()
    try:
        mahsulot = Mahsulot(nom=MAHSULOT_NOMI, konditsiya_bor=False, is_active=True)
        db.add(mahsulot)
        db.commit()
        db.refresh(mahsulot)
        mahsulot_id = mahsulot.id

        h = Hujjat(mahsulot_id=mahsulot_id, raqam=f"{RAQAM_PREFIKS}001",
                   mashina_raqami="90 SINOV 001", shofyor="Sinov Shofyor",
                   firma="Sinov MChJ", holat=HujjatHolati.TUGALLANDI,
                   created_at=datetime.now())
        db.add(h)
        db.flush()
        db.add(Olchov(hujjat_id=h.id, arava_raqam=1, tara=18000, brutto=24000, netto=6000))
        db.commit()
    finally:
        db.close()

    yield mahsulot_id

    _tozala()


def _fayl_yoli(mahsulot_nomi):
    """hujjatlar_eksport() dagi bilan AYNAN BIR XIL yo'l qurilishi -
    sana_dan/sana_gacha berilmagan (None) chaqiruv uchun."""
    papka = Path(main.RASMLAR_DIR) / xavfsiz_papka_nomi(mahsulot_nomi)
    fayl_nomi = f"{mahsulot_nomi.replace(' ', '_')}_boshidan_hozirgacha.xlsx"
    return str(papka / fayl_nomi)


def _eksport_chaqir(mahsulot_id):
    db = SessionLocal()
    try:
        return main.hujjatlar_eksport(
            mahsulot_id=mahsulot_id, sana_dan=None, sana_gacha=None,
            db=db, current_user={"sub": "test_admin", "role": "admin"})
    finally:
        db.close()


def test_eksport_mavjud_fayl_qulfini_ishlatadi(sinov_mahsuloti):
    """Asosiy tuzatish: endi GET /hujjatlar/eksport ham
    excel_qatorga_yoz()dagi BILAN BIR XIL, shu FAYLGA xos qulfni
    (_excel_fayl_qulfi) ishlatadi. Buni to'g'ridan-to'g'ri, deterministik
    tekshiramiz: qulfni QO'LDA oldindan olib turamiz - shu faylga
    yo'naltirilgan eksport chaqiruvi shu qulf BO'SHAGUNICHA HAQIQATAN
    to'xtab turishi kerak."""
    fayl_yol = _fayl_yoli(MAHSULOT_NOMI)
    qulf = main._excel_fayl_qulfi(fayl_yol)

    tugadimi = threading.Event()
    xatolar = []

    def _fon():
        try:
            _eksport_chaqir(sinov_mahsuloti)
        except Exception as e:  # noqa: BLE001
            xatolar.append(e)
        finally:
            tugadimi.set()

    qulf.acquire()
    try:
        t = threading.Thread(target=_fon)
        t.start()
        # Qulf bizning qo'limizda turgani uchun, eksport chaqiruvi HALI
        # tugamagan bo'lishi kerak (0.4s - haqiqatan bloklanganini
        # ko'rsatish uchun yetarli, ammo testni sekinlashtirmaydigan
        # bufer).
        time.sleep(0.4)
        assert not tugadimi.is_set(), (
            "Eksport chaqiruvi qulf band bo'lsa ham TUGADI! "
            "_excel_fayl_qulfi bu endpointda ishlatilmayapti - "
            "race condition tuzatilmagan."
        )
    finally:
        qulf.release()

    t.join(timeout=10)
    assert not xatolar, f"Kutilmagan xato: {xatolar}"
    assert tugadimi.is_set(), "Qulf bo'shagandan keyin eksport chaqiruvi tugashi kerak edi"


def test_eksport_parallel_sorovlar_faylni_buzmaydi(sinov_mahsuloti):
    """Ikki admin bir vaqtda AYNAN bir xil mahsulot+sana oralig'i
    eksportini so'rasa (demak bir xil fayl yo'liga yozadi) - fayl
    buzilib qolmasligi (har doim ochiladigan, yaroqli .xlsx bo'lib
    qolishi) va hech qanday kutilmagan xato bermasligi kerak."""
    boshlash_tosigi = threading.Barrier(2)
    xatolar = []

    def _fon():
        try:
            boshlash_tosigi.wait(timeout=5)
            _eksport_chaqir(sinov_mahsuloti)
        except Exception as e:  # noqa: BLE001
            xatolar.append(e)

    t1 = threading.Thread(target=_fon)
    t2 = threading.Thread(target=_fon)
    t1.start()
    t2.start()
    t1.join(timeout=15)
    t2.join(timeout=15)

    assert not xatolar, f"Parallel eksportda kutilmagan xato: {xatolar}"

    fayl = Path(_fayl_yoli(MAHSULOT_NOMI))
    assert fayl.exists()
    # Fayl buzilgan bo'lsa, bu yerda zipfile.BadZipFile kabi xato bilan tugaydi.
    wb = openpyxl.load_workbook(fayl)
    ws = wb.active
    topildi = any("90 SINOV 001" in row for row in ws.iter_rows(values_only=True))
    assert topildi, "Eksport qilingan hujjat qatori faylda topilmadi"
