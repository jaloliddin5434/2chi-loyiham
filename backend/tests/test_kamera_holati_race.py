"""_kamera_holati global holati ko'p thread'dan bir vaqtda
o'zgartirilganda (masalan ikki operator stansiyasi bir vaqtda kamera
rasmi so'rasa) hisoblagich yo'qolib qolmasligini (lost update) va
ogohlantirish faqat BIR MARTA yuborilishini tasdiqlaydi.
"""
import threading
from unittest.mock import patch


def test_parallel_xatolar_hisoblagichi_togri_sanaydi():
    import main

    # Har testda toza holatdan boshlaymiz.
    test_ip = "10.99.99.99"
    with main._kamera_holati_qulf:
        main._kamera_holati[test_ip] = {"ketma_ket": 0, "ogohlantirilgan": False}

    yuborilgan_xabarlar = []

    def sohta_telegram(matn):
        yuborilgan_xabarlar.append(matn)
        return True

    THREAD_SONI = 50

    def bitta_xato():
        main.kamera_xatosi_ogohlantirish(
            "Test Kamera", test_ip, {"status": "error", "message": "test xato"},
            "01A123BB", "Chigit", "tara")

    with patch("main.telegram_xabar_yuborish", side_effect=sohta_telegram):
        threadlar = [threading.Thread(target=bitta_xato) for _ in range(THREAD_SONI)]
        for t in threadlar:
            t.start()
        for t in threadlar:
            t.join()

    # Barcha 50 ta chaqiruv hisoblanishi kerak - lock bo'lmasa, ba'zi
    # "+= 1" operatsiyalari yo'qolib, THREAD_SONI'dan kamroq chiqar edi.
    assert main._kamera_holati[test_ip]["ketma_ket"] == THREAD_SONI, (
        f"Hisoblagich noto'g'ri: {main._kamera_holati[test_ip]['ketma_ket']} "
        f"(kutilgan: {THREAD_SONI}) - race condition bor!")

    # Chegaradan (3) o'tgandan keyin ogohlantirish FAQAT BIR MARTA
    # yuborilishi kerak, lock bo'lmasa bir nechta thread bir vaqtda
    # "ogohlantirilgan=False" ko'rib, hammasi xabar yuborib yuborishi
    # mumkin edi.
    assert len(yuborilgan_xabarlar) == 1, (
        f"Ogohlantirish {len(yuborilgan_xabarlar)} marta yuborildi (kutilgan: 1)!")
