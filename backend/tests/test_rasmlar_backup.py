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
         patch("main.TARMOQ_BACKUP_IP", "10.0.0.99"), \
         patch("main.TARMOQ_BACKUP_SHARE", "Backup"), \
         patch("main.TARMOQ_BACKUP_FOYDALANUVCHI", "u"), \
         patch("main.TARMOQ_BACKUP_PAROL", "p"), \
         patch("subprocess.run", return_value=sohta_natija) as mock_run:
        natija = main.rasmlar_tarmoqqa_backup_yubor()

    assert natija is True
    # Ikkinchi chaqiruv (birinchisi "net use") - robocopy manzillari va
    # /E bayrog'ini tekshiramiz.
    robocopy_chaqiruv = mock_run.call_args_list[1]
    args = robocopy_chaqiruv[0][0]
    assert args[0] == "robocopy"
    assert args[1] == r"C:\RASMLAR"
    assert args[2] == r"\\10.0.0.99\Backup\RASMLAR"
    assert "/E" in args


def test_robocopy_xato_kod_bilan_tugasa_muvaffaqiyatsiz_deb_qaytadi():
    import main
    sohta_natija = MagicMock(returncode=16)  # 16 = jiddiy xato
    with patch("main.os.path.isdir", return_value=True), \
         patch("subprocess.run", return_value=sohta_natija):
        natija = main.rasmlar_tarmoqqa_backup_yubor()
    assert natija is False


def test_net_use_parol_process_argumentida_korinmaydi():
    """Xavfsizlik: avval TARMOQ_BACKUP_PAROL `net use` buyrug'iga
    to'g'ridan-to'g'ri PROCESS ARGUMENTI sifatida uzatilardi - bu buyruq
    ishlab turgan payt davomida boshqa har qanday dasturga (Task Manager,
    `Get-CimInstance Win32_Process`) ko'rinib turardi. Endi parol FAQAT
    stdin (`input=`) orqali, `*` maxsus belgisi bilan uzatiladi - argv
    ichida umuman bo'lmasligi kerak."""
    import main
    SINOV_PAROL = "juda-maxfiy-sinov-parol-XYZ"
    sohta_natija = MagicMock(returncode=1)
    with patch("main.os.path.isdir", return_value=True), \
         patch("main.TARMOQ_BACKUP_IP", "10.0.0.99"), \
         patch("main.TARMOQ_BACKUP_SHARE", "Backup"), \
         patch("main.TARMOQ_BACKUP_FOYDALANUVCHI", "sinov_user"), \
         patch("main.TARMOQ_BACKUP_PAROL", SINOV_PAROL), \
         patch("subprocess.run", return_value=sohta_natija) as mock_run:
        main.rasmlar_tarmoqqa_backup_yubor()

    net_use_chaqiruv = mock_run.call_args_list[0]
    argv = net_use_chaqiruv[0][0]
    kwargs = net_use_chaqiruv[1]

    assert SINOV_PAROL not in argv, "Parol argv ichida ko'rinib qoldi!"
    assert SINOV_PAROL not in " ".join(argv), "Parol argv ichida ko'rinib qoldi!"
    # Parol shu o'rniga stdin (`input=`) orqali uzatilishi kerak.
    assert kwargs.get("input") is not None and SINOV_PAROL in kwargs["input"]
    assert "*" in argv, "net use parolni interaktiv so'rashi uchun '*' bo'lishi kerak"
