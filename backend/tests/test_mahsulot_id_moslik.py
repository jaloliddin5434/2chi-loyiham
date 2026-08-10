"""3-band: server ishga tushganda Mahsulot jadvalidagi ID'lar backend/
frontend'ning qattiq yozilgan taxminiga (id=1=Chigit/konditsiyali,
id={1,2,3,4} mavjud) mos kelishini tekshiradi - mos kelmasa,
tizim_xatolari jadvaliga yozadi (Telegram chaqiruvi monkeypatch bilan
zararsizlantiriladi - haqiqiy tarmoq so'rovi yubormasligi kerak).

DIQQAT: `_mahsulot_id_moslik_tekshiruvi(db)` sinov uchun ATAYLAB `db`
parametrini qabul qiladi - shu bilan test o'zining `db_session`
fixturasini to'g'ridan-to'g'ri uzatadi (funksiya o'z ichida yangi,
ALOHIDA ulanish ochsa, u db_session'ning hali commit qilinmagan
o'zgarishlarini ko'ra olmas edi)."""
from models import Mahsulot, TizimXatosi


def test_hammasi_togri_bolsa_xato_yozilmaydi(db_session, monkeypatch):
    import main

    yuborilgan = []
    monkeypatch.setattr(
        "main.telegram_xabar_yuborish", lambda matn: yuborilgan.append(matn) or True)

    # Haqiqiy productiondagi kabi: id=1 konditsiyali (Chigit), 2/3/4
    # konditsiyasiz - taxmin buzilmagan.
    db_session.add_all([
        Mahsulot(id=1, nom="Chigit", konditsiya_bor=True, is_active=True),
        Mahsulot(id=2, nom="Chiganoq", konditsiya_bor=False, is_active=True),
        Mahsulot(id=3, nom="Chiganoq po'chog'i", konditsiya_bor=False, is_active=True),
        Mahsulot(id=4, nom="Patoz", konditsiya_bor=False, is_active=True),
    ])
    db_session.flush()

    main._mahsulot_id_moslik_tekshiruvi(db_session)
    assert yuborilgan == []


def test_id1_konditsiyasiz_bolsa_ogohlantirish_yoziladi(db_session, monkeypatch):
    import main

    yuborilgan = []
    monkeypatch.setattr(
        "main.telegram_xabar_yuborish", lambda matn: yuborilgan.append(matn) or True)

    # id=1 ANIQ (avtomatik emas) belgilanadi - backend/frontend "id=1 =
    # Chigit = konditsiyali" deb taxmin qiladi, bu yerda ATAYLAB buziladi.
    m1 = Mahsulot(id=1, nom="Notogri Mahsulot", konditsiya_bor=False, is_active=True)
    db_session.add(m1)
    db_session.flush()

    main._mahsulot_id_moslik_tekshiruvi(db_session)

    assert len(yuborilgan) == 1, "Notogri holatda Telegram ogohlantirish yuborilishi kerak edi"
    assert "id=1" in yuborilgan[0]

    xato = db_session.query(TizimXatosi).filter(
        TizimXatosi.turi == "mahsulot_id_moslik").order_by(TizimXatosi.id.desc()).first()
    assert xato is not None
    assert "konditsiya_bor=False" in xato.xabar


def test_yetishmayotgan_id_ogohlantirish_yoziladi(db_session, monkeypatch):
    """MAHSULOT_RAQAM_PREFIKS'da kutilgan {1,2,3,4} ichidan biror ID
    Mahsulotlar jadvalida umuman topilmasa ham ogohlantirish yozilishi
    kerak (masalan faqat 1 va 2 mavjud bo'lsa)."""
    import main

    yuborilgan = []
    monkeypatch.setattr(
        "main.telegram_xabar_yuborish", lambda matn: yuborilgan.append(matn) or True)

    m1 = Mahsulot(id=1, nom="Chigit", konditsiya_bor=True, is_active=True)
    m2 = Mahsulot(id=2, nom="Chiganoq", konditsiya_bor=False, is_active=True)
    db_session.add_all([m1, m2])
    db_session.flush()

    main._mahsulot_id_moslik_tekshiruvi(db_session)

    assert len(yuborilgan) == 1
    assert "id=3" in yuborilgan[0] and "id=4" in yuborilgan[0]


def test_bosh_jadvalda_tekshirilmaydi(db_session, monkeypatch):
    """Baza hali /setup orqali urug'lanmagan (mahsulotlar jadvali bo'sh)
    holatda - tekshiruv jimgina o'tkazib yuborilishi kerak, xato
    yozmasligi kerak."""
    import main

    yuborilgan = []
    monkeypatch.setattr(
        "main.telegram_xabar_yuborish", lambda matn: yuborilgan.append(matn) or True)

    assert db_session.query(Mahsulot).count() == 0
    main._mahsulot_id_moslik_tekshiruvi(db_session)
    assert yuborilgan == []
