"""Server o'zining ommaviy manziliga (TUNNEL_TEKSHIRUV_URL, masalan
https://api.smart-tarozi.uz/health) davriy so'rov yuborib, Cloudflare
Tunnel/tarmoq ishlamay qolganini aniqlashini va Telegram orqali (faqat
bir marta, keyin "tuzaldi" xabari bilan) ogohlantirishini tekshiradi.

DIQQAT: bu ATAYLAB SERVER_ASOSIY_URL emas - u mahalliy tarmoq (LAN)
manzili, shu bilan tekshirish Cloudflare Tunnel uzilishini hech qachon
aniqlay olmasdi (real productionda topilgan monitoring teshigi,
2026-08-10 - qarang: test_togri_ommaviy_urlga_sorov_yuboradi).

2026-08-13: status_code==200'ning o'zi ham YETARLI EMASLIGI aniqlandi -
agar shu tunnelga begona (qoldiq) connector ham ulangan bo'lsa, so'rov
BOSHQA backend nusxasiga tushib, baribir 200 qaytarishi mumkin edi, shu
sabab shu ANIQ jarayonning shu ANIQ nusxasi javob berganini `instance_id`
orqali ham tasdiqlash qo'shildi - qarang: test_boshqa_nusxa_javob_bersa_muvaffaqiyatsiz."""
from unittest.mock import patch, MagicMock


def _holatni_tozala():
    import main
    with main._tunnel_holati_qulf:
        main._tunnel_holati["ketma_ket"] = 0
        main._tunnel_holati["ogohlantirilgan"] = False
    main._ogohlantirish_holatini_saqla(main._TUNNEL_OGOHLANTIRISH_KALITI, False)


def _sohta_javob(status_code=200, instance_id="_MOS_KELADIGAN_"):
    """`req.get(...)`ning o'rnini bosuvchi soxta javob - `instance_id`
    parametri `main._SERVER_INSTANCE_ID`ning o'ziga moslashtiriladi,
    aks holda chaqiruvchi aniq (masalan begona) qiymat berishi mumkin."""
    import main
    javob = MagicMock()
    javob.status_code = status_code
    javob.json.return_value = {
        "status": "ok",
        "instance_id": (
            main._SERVER_INSTANCE_ID
            if instance_id == "_MOS_KELADIGAN_"
            else instance_id
        ),
    }
    return javob


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
    xabar_matni = mock_tg.call_args[0][0]
    assert "Diqqat" in xabar_matni
    # Regressiya: xabar matni HAM to'g'ri (ommaviy) manzilni ko'rsatishi
    # kerak - avval bu yerda SERVER_ASOSIY_URL (LAN manzili) chiqib,
    # operatorlarni chalg'itardi, garchi haqiqiy tekshiruv boshqa
    # (to'g'ri) manzilga so'rov yuborayotgan bo'lsa ham.
    assert main.TUNNEL_TEKSHIRUV_URL in xabar_matni
    assert "10.112.30.77" not in xabar_matni


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
    sohta_javob_xato = _sohta_javob(status_code=502)
    sohta_javob_ok = _sohta_javob(status_code=200)

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


def test_togri_ommaviy_urlga_sorov_yuboradi():
    """Asosiy regressiya testi: tekshiruv SERVER_ASOSIY_URL (mahalliy
    LAN manzili) ga EMAS, TUNNEL_TEKSHIRUV_URL (haqiqiy ommaviy domen)
    ga so'rov yuborishi kerak - aks holda Cloudflare Tunnel uzilishini
    hech qachon aniqlay olmaydi (real productionda topilgan xato)."""
    import main
    _holatni_tozala()
    sohta_javob = _sohta_javob(status_code=200)

    with patch("main.req.get", return_value=sohta_javob) as mock_get:
        main._tunnel_bir_tekshiruv()

    chaqirilgan_url = mock_get.call_args[0][0]
    assert chaqirilgan_url == main.TUNNEL_TEKSHIRUV_URL
    assert chaqirilgan_url.startswith("https://api.smart-tarozi.uz")
    assert "10.112.30.77" not in chaqirilgan_url


def test_boshqa_nusxa_javob_bersa_muvaffaqiyatsiz():
    """2026-08-13 haqiqiy hodisa: shu tunnelga begona (qoldiq)
    cloudflared connector ham ulangan bo'lsa, so'rov BOSHQA backend
    nusxasiga tushib, baribir HTTP 200 qaytarishi mumkin edi - shu sabab
    aynan shu kuni tekshiruv hech qachon muvaffaqiyatsizlikni sezmadi
    (na "to'xtadi", na "tuzaldi" xabari kelmadi). Endi status_code==200
    bo'lsa ham, `instance_id` boshqacha bo'lsa - bu MUVAFFAQIYATSIZ deb
    hisoblanishi kerak."""
    import main
    _holatni_tozala()
    begona_javob = _sohta_javob(status_code=200, instance_id="BOSHQA-JARAYON-ID")

    with patch("main.req.get", return_value=begona_javob), \
         patch("main.telegram_xabar_yuborish") as mock_tg:
        main._tunnel_bir_tekshiruv()
        main._tunnel_bir_tekshiruv()

    assert main._tunnel_holati["ketma_ket"] == 2
    mock_tg.assert_called_once()


def test_ogohlantirilgan_bayrogi_restartdan_keyin_ham_saqlanadi():
    """2026-08-14 real hodisa: backend "🔴 xabar yubordik" holatida qayta
    ishga tushsa, xotiradagi bayroq yo'qolib, tuzalganda "✅ tuzaldi"
    xabari hech qachon kelmasdi. Jarayonni haqiqatan qayta ishga
    tushirib bo'lmagani uchun "keyingi safar modul yuklanganda nima
    o'qiladi"ni _ogohlantirish_holatini_yukla() orqali tekshiramiz."""
    import main
    _holatni_tozala()
    sohta_javob_xato = _sohta_javob(status_code=502)

    with patch("main.req.get", return_value=sohta_javob_xato), \
         patch("main.telegram_xabar_yuborish"):
        main._tunnel_bir_tekshiruv()
        main._tunnel_bir_tekshiruv()

    assert main._tunnel_holati["ogohlantirilgan"] is True
    assert main._ogohlantirish_holatini_yukla(main._TUNNEL_OGOHLANTIRISH_KALITI) is True


def test_instance_id_maydoni_yoq_eski_nusxa_ham_muvaffaqiyatsiz():
    """Agar begona nusxa ESKI kodni ishlatsa (hali `instance_id`
    maydonini bilmaydi), `.json()` bu maydonni umuman qaytarmaydi -
    `.get("instance_id")` shunda `None` qaytaradi, bu HAM shu jarayonning
    haqiqiy `_SERVER_INSTANCE_ID`iga (hech qachon `None` bo'lmaydigan
    UUID) teng bo'lmagani uchun to'g'ri ravishda muvaffaqiyatsiz
    hisoblanadi."""
    import main
    _holatni_tozala()
    eski_javob = MagicMock()
    eski_javob.status_code = 200
    eski_javob.json.return_value = {"status": "ok"}  # instance_id yo'q

    with patch("main.req.get", return_value=eski_javob), \
         patch("main.telegram_xabar_yuborish") as mock_tg:
        main._tunnel_bir_tekshiruv()
        main._tunnel_bir_tekshiruv()

    assert main._tunnel_holati["ketma_ket"] == 2
    mock_tg.assert_called_once()
