"""POST /nakladnoy/saqlash - xato yuz berganda, xato xabari LOGGA
XAVFSIZ yozilishini tekshiradi.

Real production'da (2026-08-11, HazoraspBackend NSSM xizmati sifatida
o'rnatilgandan keyin) Nakladnoy PDF generatsiyasi muvaffaqiyatsiz
bo'lganda, except blokidagi oddiy `print(f"XATO: {e}")` O'ZI
UnicodeEncodeError bilan yiqilib (xizmat konsoli/logi cp1251 kabi
UTF-8 bo'lmagan kodalashda edi), ASL xatoni butunlay yashirib
qo'ygan edi - operator "500 xato" ko'rar edi-yu, log faylida HECH
QANDAY tashxis ma'lumoti qolmasdi."""
from unittest.mock import patch


def test_xato_matnida_lotin_bolmagan_belgi_bolsa_ham_togri_500_qaytaradi(
        client, admin_headers, db_session, mashina, mahsulot_chigit):
    from models import Hujjat, HujjatHolati
    hujjat = Hujjat(raqam="TEST-NAKLADNOY-999", mashina_id=mashina.id,
                     mahsulot_id=mahsulot_chigit.id, holat=HujjatHolati.TUGALLANDI)
    db_session.add(hujjat)
    db_session.commit()
    db_session.refresh(hujjat)

    # Ataylab kirill/lotin-bo'lmagan belgilar - aynan shu turdagi matn
    # (masalan Windows/Playwright'ning o'z xato xabarlari) real hodisani
    # keltirib chiqargan edi.
    xato_matni = "Хатолик: файл топилмади ЁЁЁ"
    with patch("main.nakladnoy_uchun_malumot", side_effect=RuntimeError(xato_matni)):
        javob = client.post("/nakladnoy/saqlash", json={"hujjat_id": hujjat.id},
                             headers=admin_headers)

    # Eng muhimi: so'rov MUVAFFAQIYATLI 500 bilan tugashi kerak (print()
    # o'zi yiqilib, javobni butunlay "osilib" qoldirmasligi kerak).
    assert javob.status_code == 500
    assert xato_matni in javob.json()["detail"]
