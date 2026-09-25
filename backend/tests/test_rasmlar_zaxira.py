"""Yangi RASMLAR zaxira funksiyasi: C:/RASMLAR papkasi har kuni soat
12:05'da alohida zaxira kompyuterga (10.112.30.66, E:/RASMLAR_ZAXIRA)
robocopy /MIR bilan ko'chiriladi. Scheduler mantig'i (kunlik vaqt
oynasi, bir urinish/while True ajratilishi, Sozlama guard) mavjud
avtomatik_telegram_hisobot() bilan bir xil naqshda.

Muhim xatti-harakatlar:
- Zaxira kompyuter o'chiq (tarmoqda javob bermayapti) bo'lsa - XATO
  EMAS, jimgina o'tkazib yuboriladi, Telegram'ga hech narsa
  yuborilmaydi.
- Zaxira kompyuter ishlab turgan holda robocopy HAQIQIY xato bilan
  tugasa - Telegram'ga "❌ RASMLAR zaxirasi xato" yuboriladi.
- Muvaffaqiyatli bo'lsa - Telegram'ga "✅ RASMLAR zaxirasi yuborildi"
  yuboriladi va bugungi kun uchun guard belgilanadi (qayta
  urinilmaydi).
"""
from datetime import datetime
from unittest.mock import MagicMock, patch

import main
from models import Sozlama


# ---------- vaqt oynasi ----------

def test_rasmlar_zaxira_yuborish_vaqti_faqat_12_05_12_10_oraligida():
    v = main._rasmlar_zaxira_yuborish_vaqtimi
    assert v(datetime(2026, 9, 25, 12, 4)) is False
    assert v(datetime(2026, 9, 25, 12, 5)) is True
    assert v(datetime(2026, 9, 25, 12, 7)) is True
    assert v(datetime(2026, 9, 25, 12, 9)) is True
    assert v(datetime(2026, 9, 25, 12, 10)) is False
    assert v(datetime(2026, 9, 25, 8, 30)) is False
    assert v(datetime(2026, 9, 25, 23, 59)) is False


# ---------- rasmlar_zaxira_kompyuterga_kochir() ----------

def test_rasmlar_papkasi_yoq_bolsa_hech_narsa_qilmay_muvaffaqiyat_qaytaradi():
    with patch("main.os.path.isdir", return_value=False), \
         patch("subprocess.run") as mock_run:
        natija = main.rasmlar_zaxira_kompyuterga_kochir()
    assert natija is True
    mock_run.assert_not_called()


def test_zaxira_kompyuter_ochiq_bolsa_robocopy_chaqirilmaydi_none_qaytadi():
    """Kompyuter tarmoqda javob bermasa (o'chiq) - robocopy'ni umuman
    chaqirmasdan (SMB timeout'da "osilib" qolmaslik uchun) None
    qaytarishi kerak - bu chaqiruvchi uchun 'xato emas, o'tkazib
    yubor' degani."""
    with patch("main.os.path.isdir", return_value=True), \
         patch("main._rasmlar_zaxira_kompyuter_ishlaydimi", return_value=False), \
         patch("subprocess.run") as mock_run:
        natija = main.rasmlar_zaxira_kompyuterga_kochir()
    assert natija is None
    mock_run.assert_not_called()


def test_robocopy_muvaffaqiyatli_bolsa_true_qaytadi():
    javob = MagicMock()
    javob.returncode = 1  # robocopy: 1 = fayllar ko'chirildi, muvaffaqiyat
    with patch("main.os.path.isdir", return_value=True), \
         patch("main._rasmlar_zaxira_kompyuter_ishlaydimi", return_value=True), \
         patch("subprocess.run", return_value=javob) as mock_run:
        natija = main.rasmlar_zaxira_kompyuterga_kochir()
    assert natija is True
    args = mock_run.call_args.args[0]
    assert args[0] == "robocopy"
    assert main.RASMLAR_DIR in args
    assert main.RASMLAR_ZAXIRA_YOL in args
    assert "/MIR" in args
    assert "/R:3" in args
    assert "/W:5" in args


def test_robocopy_xato_kod_bilan_tugasa_false_qaytadi():
    javob = MagicMock()
    javob.returncode = 8  # 8+ = haqiqiy xato
    with patch("main.os.path.isdir", return_value=True), \
         patch("main._rasmlar_zaxira_kompyuter_ishlaydimi", return_value=True), \
         patch("subprocess.run", return_value=javob):
        natija = main.rasmlar_zaxira_kompyuterga_kochir()
    assert natija is False


# ---------- _rasmlar_zaxira_bir_urinish() (Telegram + guard) ----------

def test_kompyuter_ochiq_bolsa_xato_chiqmaydi_telegram_yuborilmaydi(db_session):
    with patch("main.rasmlar_zaxira_kompyuterga_kochir", return_value=None), \
         patch("main.telegram_xabar_yuborish") as mock_telegram:
        natija = main._rasmlar_zaxira_bir_urinish(db_session)
    assert natija is False
    mock_telegram.assert_not_called()
    qoldi = db_session.query(Sozlama).filter(
        Sozlama.kalit == main.RASMLAR_ZAXIRA_SOZLAMA_KALIT).first()
    assert qoldi is None  # guard belgilanmadi - keyingi tsiklda qayta sinaladi


def test_muvaffaqiyatli_bolsa_togri_xabar_yuboriladi_va_guard_belgilanadi(db_session):
    with patch("main.rasmlar_zaxira_kompyuterga_kochir", return_value=True), \
         patch("main.telegram_xabar_yuborish") as mock_telegram:
        natija = main._rasmlar_zaxira_bir_urinish(db_session)
    assert natija is True
    mock_telegram.assert_called_once_with("✅ RASMLAR zaxirasi yuborildi")
    qoldi = db_session.query(Sozlama).filter(
        Sozlama.kalit == main.RASMLAR_ZAXIRA_SOZLAMA_KALIT).first()
    assert qoldi is not None
    from datetime import date
    assert qoldi.qiymat == str(date.today())


def test_haqiqiy_xato_bolsa_togri_xato_xabari_yuboriladi_guard_belgilanmaydi(db_session):
    with patch("main.rasmlar_zaxira_kompyuterga_kochir", return_value=False), \
         patch("main.telegram_xabar_yuborish") as mock_telegram:
        natija = main._rasmlar_zaxira_bir_urinish(db_session)
    assert natija is False
    mock_telegram.assert_called_once_with("❌ RASMLAR zaxirasi xato")
    qoldi = db_session.query(Sozlama).filter(
        Sozlama.kalit == main.RASMLAR_ZAXIRA_SOZLAMA_KALIT).first()
    assert qoldi is None  # xato - keyingi tsiklda (shu kunning oynasida) qayta sinaladi


def test_bugun_allaqachon_bajarilgan_bolsa_qayta_urinmaydi(db_session):
    from datetime import date
    db_session.add(Sozlama(kalit=main.RASMLAR_ZAXIRA_SOZLAMA_KALIT,
                            qiymat=str(date.today())))
    db_session.commit()

    with patch("main.rasmlar_zaxira_kompyuterga_kochir") as mock_kochir, \
         patch("main.telegram_xabar_yuborish") as mock_telegram:
        natija = main._rasmlar_zaxira_bir_urinish(db_session)

    assert natija is False
    mock_kochir.assert_not_called()
    mock_telegram.assert_not_called()
