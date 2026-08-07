"""Server o'zining ommaviy manziliga (SERVER_ASOSIY_URL/health) davriy
so'rov yuborib, Cloudflare Tunnel/tarmoq ishlamay qolganini
aniqlashini va Telegram orqali (faqat bir marta, keyin "tuzaldi" xabari
bilan) ogohlantirishini tekshiradi.
"""
from unittest.mock import patch, MagicMock


def _holatni_tozala():
    import main
    with main._tunnel_holati_qulf:
        main._tunnel_holati["ketma_ket"] = 0
        main._tunnel_holati["ogohlantirilgan"] = False


def test_bitta_muvaffaqiyatsizlik_hali_ogohlantirmaydi():
    import main
    _holatni_tozala()
    with patch("main.req.get", side_effect=Exception("tarmoq xatosi")), \
         patch("main.telegram_xabar_yuborish") as mock_tg:
        main._tunnel_bir_tekshiruv()

    assert main._tunnel_holati["ketma_ket"] == 1
    mock_tg.assert_not_called()  # chegara (2) hali yetmagan


def test_ketma_ket_ikkinchi_muvaffaqiyatsizlikda_ogohlantiradi():
    import main
    _holatni_tozala()
    with patch("main.req.get", side_effect=Exception("tarmoq xatosi")), \
         patch("main.telegram_xabar_yuborish") as mock_tg:
        main._tunnel_bir_tekshiruv()
        main._tunnel_bir_tekshiruv()

    assert main._tunnel_holati["ketma_ket"] == 2
    assert main._tunnel_holati["ogohlantirilgan"] is True
    mock_tg.assert_called_once()
    assert "Diqqat" in mock_tg.call_args[0][0]


def test_uchinchi_muvaffaqiyatsizlikda_qayta_yubormaydi():
    """Ogohlantirish faqat BIR MARTA - muammo davom etayotganda
    Telegram guruh spam bilan to'lib ketmasligi kerak."""
    import main
    _holatni_tozala()
    with patch("main.req.get", side_effect=Exception("tarmoq xatosi")), \
         patch("main.telegram_xabar_yuborish") as mock_tg:
        main._tunnel_bir_tekshiruv()
        main._tunnel_bir_tekshiruv()
        main._tunnel_bir_tekshiruv()

    assert mock_tg.call_count == 1


def test_tuzalgandan_keyin_tuzaldi_xabari_yuboriladi():
    import main
    _holatni_tozala()
    sohta_javob_xato = MagicMock()
    sohta_javob_xato.status_code = 502
    sohta_javob_ok = MagicMock()
    sohta_javob_ok.status_code = 200

    with patch("main.telegram_xabar_yuborish") as mock_tg:
        with patch("main.req.get", return_value=sohta_javob_xato):
            main._tunnel_bir_tekshiruv()
            main._tunnel_bir_tekshiruv()
        assert mock_tg.call_count == 1  # "diqqat" xabari

        with patch("main.req.get", return_value=sohta_javob_ok):
            main._tunnel_bir_tekshiruv()
        assert mock_tg.call_count == 2  # "tuzaldi" xabari qo'shildi
        assert "qayta ishlay boshladi" in mock_tg.call_args[0][0]

    assert main._tunnel_holati["ketma_ket"] == 0
    assert main._tunnel_holati["ogohlantirilgan"] is False
