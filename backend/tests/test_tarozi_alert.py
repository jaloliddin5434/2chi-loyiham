"""Tarozi agentidan uzoq vaqt ma'lumot kelmasa (backend TIRIK bo'lgan
holatda), Telegram orqali ogohlantirish yuborilishini tekshiradi. Bu
avvalgi faqat operator ekrani so'raganda tekshiriladigan mexanizmga
(GET /tarozi/joriy) qo'shimcha, MUSTAQIL fon tekshiruvi.
"""
import time
from unittest.mock import patch


def _holatni_tozala():
    import main
    with main._tarozi_alert_holati_qulf:
        main._tarozi_alert_holati["ogohlantirilgan"] = False
    main._ogohlantirish_holatini_saqla(main._TAROZI_ALERT_OGOHLANTIRISH_KALITI, False)


def test_yaqinda_yangilangan_bolsa_ogohlantirmaydi():
    import main
    _holatni_tozala()
    with main._tarozi_qulf:
        main._tarozi_oxirgi_yangilanish = time.time()
    with patch("main.telegram_xabar_yuborish") as mock_tg:
        main._tarozi_alert_bir_tekshiruv()
    mock_tg.assert_not_called()


def test_chegaradan_otsa_ogohlantiradi():
    import main
    _holatni_tozala()
    with main._tarozi_qulf:
        main._tarozi_oxirgi_yangilanish = time.time() - (main._TAROZI_ALERT_CHEGARA_SONIYA + 5)
    with patch("main.telegram_xabar_yuborish") as mock_tg:
        main._tarozi_alert_bir_tekshiruv()
    mock_tg.assert_called_once()
    assert "Diqqat" in mock_tg.call_args[0][0]
    assert main._tarozi_alert_holati["ogohlantirilgan"] is True


def test_davom_etayotgan_muammoda_qayta_yubormaydi():
    """Spam bo'lmasligi uchun - muammo davom etsa, ikkinchi marta
    ogohlantirish YUBORILMASLIGI kerak."""
    import main
    _holatni_tozala()
    with main._tarozi_qulf:
        main._tarozi_oxirgi_yangilanish = time.time() - (main._TAROZI_ALERT_CHEGARA_SONIYA + 5)
    with patch("main.telegram_xabar_yuborish") as mock_tg:
        main._tarozi_alert_bir_tekshiruv()
        main._tarozi_alert_bir_tekshiruv()
        main._tarozi_alert_bir_tekshiruv()
    assert mock_tg.call_count == 1


def test_tuzalgandan_keyin_tuzaldi_xabari_va_qayta_ogohlantirish_ishlaydi():
    import main
    _holatni_tozala()

    with main._tarozi_qulf:
        main._tarozi_oxirgi_yangilanish = time.time() - (main._TAROZI_ALERT_CHEGARA_SONIYA + 5)
    with patch("main.telegram_xabar_yuborish") as mock_tg:
        main._tarozi_alert_bir_tekshiruv()
        assert mock_tg.call_count == 1

        # Tuzaldi - yangi ma'lumot keldi.
        with main._tarozi_qulf:
            main._tarozi_oxirgi_yangilanish = time.time()
        main._tarozi_alert_bir_tekshiruv()
        assert mock_tg.call_count == 2
        assert "qayta kela boshladi" in mock_tg.call_args[0][0]
        assert main._tarozi_alert_holati["ogohlantirilgan"] is False

        # Qayta uzilsa - yana bitta yangi ogohlantirish kerak (eski
        # bayroq to'g'ri tozalangan bo'lishi kerak).
        with main._tarozi_qulf:
            main._tarozi_oxirgi_yangilanish = time.time() - (main._TAROZI_ALERT_CHEGARA_SONIYA + 5)
        main._tarozi_alert_bir_tekshiruv()
        assert mock_tg.call_count == 3


def test_serverda_hali_hech_qanday_malumot_kelmagan_bolsa_ham_ishlaydi():
    """_tarozi_oxirgi_yangilanish=0.0 (server hozirgina ishga tushgan,
    agent hali ulanmagan) holatida ham xato bermasligi kerak."""
    import main
    _holatni_tozala()
    with main._tarozi_qulf:
        main._tarozi_oxirgi_yangilanish = 0.0
    with patch("main.telegram_xabar_yuborish") as mock_tg:
        main._tarozi_alert_bir_tekshiruv()
    mock_tg.assert_called_once()


def test_ogohlantirilgan_bayrogi_restartdan_keyin_ham_saqlanadi():
    """2026-08-14 real hodisa: backend "🔴 xabar yubordik, tuzalishini
    kutyapmiz" holatida qayta ishga tushsa, xotiradagi bayroq yo'qolib,
    muammo haqiqatan tuzalganda "✅ tuzaldi" xabari hech qachon kelmasdi.
    Bu yerda jarayonni haqiqatan qayta ishga tushirib bo'lmaydi - shu
    sabab "keyingi safar modul yuklanganda nima o'qiladi" ni
    _ogohlantirish_holatini_yukla()ni to'g'ridan-to'g'ri chaqirib
    tekshiramiz (aynan shu funksiya modul darajasida import paytida
    chaqiriladi - qarang: main.py'dagi `_tarozi_alert_holati = {...}`)."""
    import main
    _holatni_tozala()
    with main._tarozi_qulf:
        main._tarozi_oxirgi_yangilanish = time.time() - (main._TAROZI_ALERT_CHEGARA_SONIYA + 5)
    with patch("main.telegram_xabar_yuborish"):
        main._tarozi_alert_bir_tekshiruv()

    assert main._tarozi_alert_holati["ogohlantirilgan"] is True
    # "Qayta ishga tushirilsa" nima o'qiladi - True bo'lishi SHART.
    assert main._ogohlantirish_holatini_yukla(main._TAROZI_ALERT_OGOHLANTIRISH_KALITI) is True
