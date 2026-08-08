"""Ogohlantirish (telegram_xabar_yuborish) va hisobot
(telegram_hisobot_yuborish) botlari ALOHIDA token/chat_id ishlatishini,
va biri sozlanmagan bo'lsa xato bermay jimgina False qaytarishini
tekshiradi."""
from unittest.mock import patch, MagicMock


def test_ogohlantirish_boti_ozining_tokenidan_foydalanadi():
    import main
    sohta_javob = MagicMock()
    sohta_javob.status_code = 200
    with patch("main.req.post", return_value=sohta_javob) as mock_post, \
         patch("config.TELEGRAM_TOKEN", "OGOH_TOKEN"), \
         patch("config.TELEGRAM_CHAT_ID", "111"):
        natija = main.telegram_xabar_yuborish("test xabar")

    assert natija is True
    yuborilgan_url = mock_post.call_args[0][0]
    yuborilgan_body = mock_post.call_args[1]["json"]
    assert "OGOH_TOKEN" in yuborilgan_url
    assert yuborilgan_body["chat_id"] == "111"


def test_hisobot_boti_ozining_ALOHIDA_tokenidan_foydalanadi():
    import main
    sohta_javob = MagicMock()
    sohta_javob.status_code = 200
    with patch("main.req.post", return_value=sohta_javob) as mock_post, \
         patch("config.TELEGRAM_HISOBOT_TOKEN", "HISOBOT_TOKEN"), \
         patch("config.TELEGRAM_HISOBOT_CHAT_ID", "222"):
        natija = main.telegram_hisobot_yuborish("kunlik hisobot matni")

    assert natija is True
    yuborilgan_url = mock_post.call_args[0][0]
    yuborilgan_body = mock_post.call_args[1]["json"]
    assert "HISOBOT_TOKEN" in yuborilgan_url
    assert yuborilgan_body["chat_id"] == "222"


def test_hisobot_boti_sozlanmagan_bolsa_xato_bermay_False_qaytaradi():
    import main
    with patch("main.req.post") as mock_post, \
         patch("config.TELEGRAM_HISOBOT_TOKEN", None), \
         patch("config.TELEGRAM_HISOBOT_CHAT_ID", None):
        natija = main.telegram_hisobot_yuborish("hali sozlanmagan")

    assert natija is False
    mock_post.assert_not_called()


def test_ogohlantirish_va_hisobot_bir_biriga_ARALASHMAYDI():
    """Hisobot funksiyasi chaqirilganda ogohlantirish tokeni/chat_id
    ISHLATILMASLIGINI aniq tasdiqlaydi - bu ikki botni ajratishning
    butun maqsadi."""
    import main
    sohta_javob = MagicMock()
    sohta_javob.status_code = 200
    with patch("main.req.post", return_value=sohta_javob) as mock_post, \
         patch("config.TELEGRAM_TOKEN", "OGOH_TOKEN"), \
         patch("config.TELEGRAM_CHAT_ID", "111"), \
         patch("config.TELEGRAM_HISOBOT_TOKEN", "HISOBOT_TOKEN"), \
         patch("config.TELEGRAM_HISOBOT_CHAT_ID", "222"):
        main.telegram_hisobot_yuborish("kunlik hisobot")

    yuborilgan_url = mock_post.call_args[0][0]
    assert "OGOH_TOKEN" not in yuborilgan_url
    assert "HISOBOT_TOKEN" in yuborilgan_url
