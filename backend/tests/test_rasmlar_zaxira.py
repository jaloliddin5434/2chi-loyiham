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
  tugasa - Telegram'ga "❌ RASMLAR zaxirasi xato" BIR marta yuboriladi
  va guard belgilanadi (oyna davomida takroriy xabar ketmaydi).
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
         patch("main._tarmoqqa_ulan") as mock_ulan, \
         patch("main._tarmoqdan_uzil") as mock_uzil, \
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
    mock_ulan.assert_called_once_with(
        main.RASMLAR_ZAXIRA_YOL, main.RASMLAR_ZAXIRA_FOYDALANUVCHI, main.ZAXIRA_KOMPYUTER_PAROL)
    mock_uzil.assert_called_once_with(main.RASMLAR_ZAXIRA_YOL)


def test_robocopy_xato_kod_bilan_tugasa_false_qaytadi():
    javob = MagicMock()
    javob.returncode = 8  # 8+ = haqiqiy xato
    with patch("main.os.path.isdir", return_value=True), \
         patch("main._rasmlar_zaxira_kompyuter_ishlaydimi", return_value=True), \
         patch("main._tarmoqqa_ulan"), \
         patch("main._tarmoqdan_uzil") as mock_uzil, \
         patch("subprocess.run", return_value=javob):
        natija = main.rasmlar_zaxira_kompyuterga_kochir()
    assert natija is False
    mock_uzil.assert_called_once()  # xato bo'lsa ham ulanish uzilishi kerak


def test_ulanish_muvaffaqiyatsiz_bolsa_robocopy_chaqirilmaydi():
    """Login/parol xato bo'lsa (_tarmoqqa_ulan OSError otsa) - robocopy
    umuman chaqirilmasligi, xato tizim_xatolariga yozilishi kerak."""
    with patch("main.os.path.isdir", return_value=True), \
         patch("main._rasmlar_zaxira_kompyuter_ishlaydimi", return_value=True), \
         patch("main._tarmoqqa_ulan", side_effect=OSError("WNetAddConnection2W xato kod bilan tugadi: 1326")), \
         patch("subprocess.run") as mock_run:
        natija = main.rasmlar_zaxira_kompyuterga_kochir()
    assert natija is False
    mock_run.assert_not_called()


def test_robocopy_ozi_istisno_otsa_ham_ulanish_uziladi():
    """finally bloki subprocess.run() kutilmagan istisno otsa ham
    _tarmoqdan_uzil() chaqirilishini kafolatlaydi - aks holda ulanish
    keyingi urinishlargacha ochiq qolib ketishi mumkin edi."""
    with patch("main.os.path.isdir", return_value=True), \
         patch("main._rasmlar_zaxira_kompyuter_ishlaydimi", return_value=True), \
         patch("main._tarmoqqa_ulan"), \
         patch("main._tarmoqdan_uzil") as mock_uzil, \
         patch("subprocess.run", side_effect=TimeoutError("robocopy 1800s dan oshdi")):
        natija = main.rasmlar_zaxira_kompyuterga_kochir()
    assert natija is False
    mock_uzil.assert_called_once()


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


def test_haqiqiy_xato_bolsa_xato_xabari_yuboriladi_va_guard_belgilanadi(db_session):
    with patch("main.rasmlar_zaxira_kompyuterga_kochir", return_value=False), \
         patch("main.telegram_xabar_yuborish") as mock_telegram:
        natija = main._rasmlar_zaxira_bir_urinish(db_session)
    assert natija is False
    mock_telegram.assert_called_once_with("❌ RASMLAR zaxirasi xato")
    qoldi = db_session.query(Sozlama).filter(
        Sozlama.kalit == main.RASMLAR_ZAXIRA_SOZLAMA_KALIT).first()
    from datetime import date
    # xato bo'lsa ham guard qo'yiladi - bugun qayta urinilmaydi
    assert qoldi is not None and qoldi.qiymat == str(date.today())


def test_butun_oyna_davomida_xato_bolsa_faqat_bitta_telegram_xabar(db_session):
    """Regressiya: 12:05-12:09 oynasi (30 soniyalik siklda ~10 urinish)
    davomida robocopy har safar xato bersa - avval har urinishda "❌"
    ketardi (10 ta xabar). Endi faqat BIRINCHI urinish ishlaydi."""
    with patch("main.rasmlar_zaxira_kompyuterga_kochir", return_value=False) as mock_kochir, \
         patch("main.telegram_xabar_yuborish") as mock_telegram:
        for _ in range(10):
            main._rasmlar_zaxira_bir_urinish(db_session)
    assert mock_kochir.call_count == 1
    mock_telegram.assert_called_once_with("❌ RASMLAR zaxirasi xato")


def test_butun_oyna_davomida_kompyuter_ochiq_bolsa_hech_qanday_telegram_yoq(db_session):
    """Kompyuter o'chiq - oyna davomida jimgina qayta sinaladi (yoqilib
    qolsa ishlashi uchun), lekin birorta ham Telegram xabar ketmaydi."""
    with patch("main.rasmlar_zaxira_kompyuterga_kochir", return_value=None) as mock_kochir, \
         patch("main.telegram_xabar_yuborish") as mock_telegram:
        for _ in range(10):
            main._rasmlar_zaxira_bir_urinish(db_session)
    assert mock_kochir.call_count == 10
    mock_telegram.assert_not_called()


def test_kompyuter_oyna_ortasida_yoqilsa_bir_marta_muvaffaqiyat_xabari(db_session):
    natijalar = [None, None, None, True, True, True]
    with patch("main.rasmlar_zaxira_kompyuterga_kochir", side_effect=natijalar) as mock_kochir, \
         patch("main.telegram_xabar_yuborish") as mock_telegram:
        for _ in range(6):
            main._rasmlar_zaxira_bir_urinish(db_session)
    assert mock_kochir.call_count == 4
    mock_telegram.assert_called_once_with("✅ RASMLAR zaxirasi yuborildi")


def test_guard_commit_yiqilsa_telegram_yuborilmaydi(db_session):
    """Guard Telegram'dan OLDIN saqlanadi - commit yiqilsa xabar ketmaydi
    (aks holda keyingi tsiklda yana urinib, takroriy xabar ketardi)."""
    with patch("main.rasmlar_zaxira_kompyuterga_kochir", return_value=False), \
         patch("main.telegram_xabar_yuborish") as mock_telegram, \
         patch.object(db_session, "commit", side_effect=RuntimeError("db yiqildi")):
        try:
            main._rasmlar_zaxira_bir_urinish(db_session)
        except RuntimeError:
            pass
    mock_telegram.assert_not_called()


def test_kecha_xato_bolgan_bolsa_bugun_qayta_urinadi(db_session):
    from datetime import date, timedelta
    db_session.add(Sozlama(kalit=main.RASMLAR_ZAXIRA_SOZLAMA_KALIT,
                            qiymat=str(date.today() - timedelta(days=1))))
    db_session.commit()
    with patch("main.rasmlar_zaxira_kompyuterga_kochir", return_value=True) as mock_kochir, \
         patch("main.telegram_xabar_yuborish") as mock_telegram:
        natija = main._rasmlar_zaxira_bir_urinish(db_session)
    assert natija is True
    mock_kochir.assert_called_once()
    mock_telegram.assert_called_once_with("✅ RASMLAR zaxirasi yuborildi")


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
