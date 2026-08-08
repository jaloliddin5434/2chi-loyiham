"""CloudflaredTunnel Windows xizmatining LOKAL holatini (tarmoq orqali
EMAS, `sc query` orqali) tekshirib, to'xtab qolsa Telegram orqali (faqat
bir marta, keyin "tuzaldi" xabari bilan) ogohlantirishini tekshiradi.
"""
from unittest.mock import patch, MagicMock


def _holatni_tozala():
    import main
    with main._tunnel_xizmat_holati_qulf:
        main._tunnel_xizmat_holati["ogohlantirilgan"] = False


def _sc_natija(running: bool):
    natija = MagicMock()
    natija.stdout = (
        "SERVICE_NAME: CloudflaredTunnel\n        STATE : 4  RUNNING"
        if running
        else "SERVICE_NAME: CloudflaredTunnel\n        STATE : 1  STOPPED"
    )
    return natija


def test_xizmat_ishlab_turganda_ogohlantirmaydi():
    import main
    _holatni_tozala()
    with patch("subprocess.run", return_value=_sc_natija(True)), \
         patch("main.telegram_xabar_yuborish") as mock_tg:
        main._tunnel_xizmat_bir_tekshiruv()

    mock_tg.assert_not_called()


def test_xizmat_toxtaganda_darhol_ogohlantiradi():
    """HTTP-orqali kuzatuvchidan farqli - bu yerda ketma-ket urinish shart
    emas, chunki xizmat holati tarmoq shovqiniga bog'liq emas (aniq
    binary holat)."""
    import main
    _holatni_tozala()
    with patch("subprocess.run", return_value=_sc_natija(False)), \
         patch("main.telegram_xabar_yuborish") as mock_tg:
        main._tunnel_xizmat_bir_tekshiruv()

    mock_tg.assert_called_once()
    assert "Diqqat" in mock_tg.call_args[0][0]
    assert "CloudflaredTunnel" in mock_tg.call_args[0][0]
    assert main._tunnel_xizmat_holati["ogohlantirilgan"] is True


def test_davom_etayotgan_muammoda_qayta_yubormaydi():
    import main
    _holatni_tozala()
    with patch("subprocess.run", return_value=_sc_natija(False)), \
         patch("main.telegram_xabar_yuborish") as mock_tg:
        main._tunnel_xizmat_bir_tekshiruv()
        main._tunnel_xizmat_bir_tekshiruv()
        main._tunnel_xizmat_bir_tekshiruv()

    assert mock_tg.call_count == 1


def test_tuzalgandan_keyin_tuzaldi_xabari_yuboriladi():
    import main
    _holatni_tozala()
    with patch("main.telegram_xabar_yuborish") as mock_tg:
        with patch("subprocess.run", return_value=_sc_natija(False)):
            main._tunnel_xizmat_bir_tekshiruv()
        assert mock_tg.call_count == 1

        with patch("subprocess.run", return_value=_sc_natija(True)):
            main._tunnel_xizmat_bir_tekshiruv()
        assert mock_tg.call_count == 2
        assert "qayta ishga tushdi" in mock_tg.call_args[0][0]

    assert main._tunnel_xizmat_holati["ogohlantirilgan"] is False


def test_sc_buyrugi_xato_bersa_ham_dastur_qotib_qolmaydi():
    """sc.exe topilmasa/xato bersa - False deb hisoblanadi (xavfsiz
    tomonga xato), lekin dastur qulamaydi."""
    import main
    _holatni_tozala()
    with patch("subprocess.run", side_effect=FileNotFoundError("sc topilmadi")), \
         patch("main.telegram_xabar_yuborish") as mock_tg:
        main._tunnel_xizmat_bir_tekshiruv()

    mock_tg.assert_called_once()
    assert "Diqqat" in mock_tg.call_args[0][0]
