"""telegram_xabar_yuborish() tashqi (Telegram) so'roviga timeout
qo'yilganini tasdiqlaydi. Bu funksiya ba'zan sinxron so'rov ichida
(masalan POST /kamera/rasm) chaqiriladi - timeout bo'lmasa, Telegram
sekinlashganda operatorning kutilmagan ekranda amaliga aloqasi yo'q
so'rovi abadiy osilib qolishi mumkin edi.
"""
from unittest.mock import patch, MagicMock


def test_telegram_sorovida_timeout_bor():
    import main

    sohta_javob = MagicMock()
    sohta_javob.raise_for_status.return_value = None

    with patch("main.req.post", return_value=sohta_javob) as mock_post, \
         patch("config.TELEGRAM_TOKEN", "test-token"), \
         patch("config.TELEGRAM_CHAT_ID", "test-chat"):
        natija = main.telegram_xabar_yuborish("test xabar")

    assert natija is True
    assert mock_post.called
    _, kwargs = mock_post.call_args
    assert "timeout" in kwargs, "req.post() chaqiruvida timeout parametri yo'q!"
    assert 0 < kwargs["timeout"] <= 10, f"timeout qiymati kutilganidan tashqarida: {kwargs['timeout']}"
