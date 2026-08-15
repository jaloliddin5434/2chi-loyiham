"""C:/RASMLAR (kamera rasmlari, nakladnoy fayllar) ikkinchi kompyuterga
zaxiralanishini tekshiradi - avval bu umuman zaxiralanmasdi, faqat
baza (.sql) zaxiralanardi.
"""
from unittest.mock import patch, MagicMock


def test_rasmlar_papkasi_yoq_bolsa_muvaffaqiyat_deb_qaytadi():
    import main
    with patch("main.os.path.isdir", return_value=False), \
         patch("subprocess.run") as mock_run:
        natija = main.rasmlar_tarmoqqa_backup_yubor()
    assert natija is True
    mock_run.assert_not_called()


def test_robocopy_muvaffaqiyatli_bolsa_togri_argumentlar_bilan_chaqiriladi():
    import main
    sohta_natija = MagicMock(returncode=1)  # robocopy: 1 = fayllar ko'chirildi (muvaffaqiyat)
    with patch("main.os.path.isdir", return_value=True), \
         patch("main._tarmoqqa_ulan"), \
         patch("main.TARMOQ_BACKUP_IP", "10.0.0.99"), \
         patch("main.TARMOQ_BACKUP_SHARE", "Backup"), \
         patch("main.TARMOQ_BACKUP_FOYDALANUVCHI", "u"), \
         patch("main.TARMOQ_BACKUP_PAROL", "p"), \
         patch("subprocess.run", return_value=sohta_natija) as mock_run:
        natija = main.rasmlar_tarmoqqa_backup_yubor()

    assert natija is True
    robocopy_chaqiruv = mock_run.call_args_list[0]
    args = robocopy_chaqiruv[0][0]
    assert args[0] == "robocopy"
    assert args[1] == r"C:\RASMLAR"
    assert args[2] == r"\\10.0.0.99\Backup\RASMLAR"
    assert "/E" in args


def test_robocopy_xato_kod_bilan_tugasa_muvaffaqiyatsiz_deb_qaytadi():
    import main
    sohta_natija = MagicMock(returncode=16)  # 16 = jiddiy xato
    with patch("main.os.path.isdir", return_value=True), \
         patch("main._tarmoqqa_ulan"), \
         patch("subprocess.run", return_value=sohta_natija):
        natija = main.rasmlar_tarmoqqa_backup_yubor()
    assert natija is False


def test_ulanish_xato_bersa_muvaffaqiyatsiz_deb_qaytadi_va_robocopy_chaqirilmaydi():
    """Xavfsizlik/ishonchlilik: avval SMB ulanish `net use ... *` orqali
    parolni interaktiv so'rov + stdin bilan uzatardi - bu real
    production'da PAROLNI TO'G'RI YETKAZMASLIGI tasdiqlangan ("System
    error 86: network password is not correct", to'g'ri parol bilan
    ham), natijada 2026-08-12 dan buyon HAR BIR tarmoq backup urinishi
    robocopy 16-xato bilan muvaffaqiyatsiz tugagan. Endi ulanish Win32
    WNetAddConnection2W API orqali (ctypes, subprocess'siz) amalga
    oshiriladi - parol hech qachon biror jarayon argv'ida yoki
    konsolida ko'rinmaydi va konsolga bog'liq emas. Agar ulanishning
    o'zi (masalan noto'g'ri parol) muvaffaqiyatsiz bo'lsa, robocopy
    umuman chaqirilmasligi kerak."""
    import main
    with patch("main.os.path.isdir", return_value=True), \
         patch("main._tarmoqqa_ulan", side_effect=OSError("WNetAddConnection2W xato kod bilan tugadi: 1326")), \
         patch("subprocess.run") as mock_run:
        natija = main.rasmlar_tarmoqqa_backup_yubor()

    assert natija is False
    mock_run.assert_not_called()
