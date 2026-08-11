"""Tarmoq backup (ikkinchi kompyuterga robocopy) MUVAFFAQIYATSIZ
bo'lganda, avtomatik_backup() sikli avval HAR 30 SONIYADA (asosiy
siklning har qadamida) qayta urinib ko'rardi. Real production'da
(2026-08-02...2026-08-10) ikkinchi kompyuter uzoq vaqt ishlamay
qolganda, bu tizim_xatolari jadvalini ~2100+ ta deyarli bir xil
yozuv bilan to'ldirgan edi - natijada admin panelida ESKI, allaqachon
tuzatilgan xato yangi/dolzarb muammo bilan aralashib, operatorni
chalg'itgan edi. Endi qayta urinish faqat BACKUP_QAYTA_URINISH_DAQIQA
daqiqada bir marta."""


def test_birinchi_marta_urinish_kerak_deb_topiladi(db_session):
    import main
    natija = main._shu_zahoti_urinish_kerakmi(
        db_session, "sinov_urinish_kaliti_1", main.BACKUP_QAYTA_URINISH_DAQIQA)
    assert natija is True


def test_yaqinda_urinilgan_bolsa_qayta_urinilmaydi(db_session):
    import main
    kalit = "sinov_urinish_kaliti_2"
    main._urinish_vaqtini_belgila(db_session, kalit)

    natija = main._shu_zahoti_urinish_kerakmi(
        db_session, kalit, main.BACKUP_QAYTA_URINISH_DAQIQA)
    assert natija is False


def test_throttle_muddati_otgandan_keyin_qayta_urinish_kerak_boladi(db_session):
    import main
    from datetime import datetime, timedelta
    from models import Sozlama

    kalit = "sinov_urinish_kaliti_3"
    eski_vaqt = datetime.now() - timedelta(minutes=main.BACKUP_QAYTA_URINISH_DAQIQA + 1)
    db_session.add(Sozlama(kalit=kalit, qiymat=eski_vaqt.isoformat()))
    db_session.commit()

    natija = main._shu_zahoti_urinish_kerakmi(
        db_session, kalit, main.BACKUP_QAYTA_URINISH_DAQIQA)
    assert natija is True


def test_tarmoq_va_rasmlar_uchun_alohida_kalitlar_ishlatiladi(db_session):
    """Tarmoq (.sql) va rasmlar backup'lari MUSTAQIL kuzatiladi - biri
    throttle qilingan bo'lsa, ikkinchisi bunga bog'liq bo'lmasligi
    kerak (chunki ular alohida-alohida muvaffaqiyatsiz/muvaffaqiyatli
    bo'lishi mumkin)."""
    import main
    assert main.TARMOQ_BACKUP_URINISH_SOZLAMA_KALIT != main.RASMLAR_BACKUP_URINISH_SOZLAMA_KALIT

    main._urinish_vaqtini_belgila(db_session, main.TARMOQ_BACKUP_URINISH_SOZLAMA_KALIT)

    assert not main._shu_zahoti_urinish_kerakmi(
        db_session, main.TARMOQ_BACKUP_URINISH_SOZLAMA_KALIT, main.BACKUP_QAYTA_URINISH_DAQIQA)
    assert main._shu_zahoti_urinish_kerakmi(
        db_session, main.RASMLAR_BACKUP_URINISH_SOZLAMA_KALIT, main.BACKUP_QAYTA_URINISH_DAQIQA)
