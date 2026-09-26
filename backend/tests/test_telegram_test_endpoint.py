"""POST /telegram/test - avval telegram_xabar_yuborish() natijasini
tekshirmasdan har doim {"status": "ok"} qaytarardi: token/chat_id
sozlanmagan yoki Telegram javob bermagan holatda ham admin "muvaffaqiyat"
ko'rardi. Endi xato holatida {"status": "xato", "xabar": ...} qaytadi.
Haqiqiy Telegram so'rovi yuborilmaydi (telegram_xabar_yuborish mock)."""
from unittest.mock import patch


def test_muvaffaqiyatli_yuborilsa_ok_qaytadi(client, admin_headers):
    with patch("main.telegram_xabar_yuborish", return_value=True) as mock_tg:
        javob = client.post("/telegram/test", headers=admin_headers)
    assert javob.status_code == 200
    assert javob.json() == {"status": "ok"}
    mock_tg.assert_called_once()


def test_yuborilmasa_xato_va_xabar_qaytadi(client, admin_headers):
    with patch("main.telegram_xabar_yuborish", return_value=False):
        javob = client.post("/telegram/test", headers=admin_headers)
    assert javob.status_code == 200
    natija = javob.json()
    assert natija["status"] == "xato"
    assert natija["xabar"]


def test_operator_telegram_test_qila_olmaydi(client, operator_headers):
    with patch("main.telegram_xabar_yuborish") as mock_tg:
        javob = client.post("/telegram/test", headers=operator_headers)
    assert javob.status_code == 403
    mock_tg.assert_not_called()
