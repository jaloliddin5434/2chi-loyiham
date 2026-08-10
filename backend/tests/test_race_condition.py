"""2-band va 4-band: hujjat raqami hisoblagichi va Mashina.davlat_raqami
uchun race-condition tuzatishlari.

Bu testlar ATAYLAB `db_session`/`client` fixturalaridan FOYDALANMAYDI -
ular bitta umumiy ulanish+tranzaksiyani (SAVEPOINT bilan) ishlatadi, bu
esa HAQIQIY, bir-biridan mustaqil ikkita tranzaksiya orasidagi
to'qnashuvni sinash uchun yaramaydi. Buning o'rniga to'g'ridan-to'g'ri
`SessionLocal()` orqali ikkita ALOHIDA ulanish ochiladi - biri "raqib"
tranzaksiya sifatida haqiqatan COMMIT qilinadi, ikkinchisi esa tuzatilgan
funksiyaning o'zi xuddi shu holatga duch kelganda qanday ishlashini
tekshiradi (funksiya to'g'ridan-to'g'ri, HTTP qatlamisiz chaqiriladi).
Testdan keyin yaratilgan qatorlar qo'lda tozalanadi (fixture rollback'i
bu yerga tegishli emas).
"""
from database import SessionLocal
from models import HujjatRaqamHisoblagich, Mashina
from schemas import MashinaCreate


def test_hujjat_raqami_hisoblagich_ikkita_tranzaksiya_toqnashganda_xato_bermaydi():
    """2-band: yangi yil/mahsulot uchun BIRINCHI hujjat raqami so'ralganda,
    agar boshqa (raqib) tranzaksiya AYNAN o'sha paytda hisoblagich
    qatorini ALLAQACHON yaratib, COMMIT qilib ulgurgan bo'lsa -
    keyingi_hujjat_raqami() xato (IntegrityError) bermasdan, mavjud
    qatorni topib, xavfsiz davom etishi kerak."""
    import main

    SINOV_YIL = 88801  # haqiqiy yil bilan hech qachon to'qnashmaydigan qiymat
    SINOV_MAHSULOT_ID = 1

    db_a = SessionLocal()
    db_raqib = SessionLocal()
    try:
        # 1-qadam: "bizning" tranzaksiya (db_a) mavjud hisoblagichni
        # qidiradi - hali yo'q, None qaytadi (lekin hali COMMIT qilinmagan).
        topilgan = db_a.query(HujjatRaqamHisoblagich).filter(
            HujjatRaqamHisoblagich.yil == SINOV_YIL,
            HujjatRaqamHisoblagich.mahsulot_id == SINOV_MAHSULOT_ID,
        ).with_for_update().first()
        assert topilgan is None

        # 2-qadam: RAQIB tranzaksiya (mustaqil ulanish) xuddi shu
        # (yil, mahsulot_id) uchun hisoblagichni yaratib, HAQIQATAN
        # commit qiladi - bu "boshqa operator bizdan oldin ulgurdi"
        # holatini simulyatsiya qiladi.
        raqib_hisoblagich = HujjatRaqamHisoblagich(
            yil=SINOV_YIL, mahsulot_id=SINOV_MAHSULOT_ID, oxirgi_raqam=5)
        db_raqib.add(raqib_hisoblagich)
        db_raqib.commit()

        # 3-qadam: "bizning" tranzaksiya endi keyingi_hujjat_raqami()ning
        # qolgan qismini bajaradi - INSERT'ga urinadi, lekin raqib
        # ALLAQACHON committed qilgani uchun UniqueConstraint'ga uriladi.
        # Tuzatilgan kod buni SAVEPOINT ichida ushlab, mavjud qatorni
        # topib olishi SHART - xato otmasligi kerak.
        raqam = main.keyingi_hujjat_raqami(db_a, SINOV_YIL, SINOV_MAHSULOT_ID)
        db_a.commit()

        # Raqib oxirgi_raqam=5 dan boshlagani uchun, natija shundan
        # KEYINGI (6) bo'lishi kerak - demak ikkalasi HAM bitta
        # hisoblagichni ulashdi, ikkita alohida (mojarolashuvchi) qator
        # YARATILMADI.
        assert raqam == "CHG-88801/006"

        qatorlar_soni = db_a.query(HujjatRaqamHisoblagich).filter(
            HujjatRaqamHisoblagich.yil == SINOV_YIL,
            HujjatRaqamHisoblagich.mahsulot_id == SINOV_MAHSULOT_ID,
        ).count()
        assert qatorlar_soni == 1, "Ikkita mojarolashgan qator qolib ketmasligi kerak"
    finally:
        db_a.rollback()
        db_raqib.query(HujjatRaqamHisoblagich).filter(
            HujjatRaqamHisoblagich.yil == SINOV_YIL,
        ).delete()
        db_raqib.commit()
        db_a.close()
        db_raqib.close()


def test_mashina_davlat_raqami_ikkita_tranzaksiya_toqnashganda_mavjudini_qaytaradi():
    """4-band: ikkita so'rov bir vaqtda BIR XIL davlat_raqami bilan
    mashina yaratmoqchi bo'lsa - raqib tranzaksiya avval commit qilib
    ulgursa, bizning tranzaksiya 500 xato bermasdan, raqib yaratgan
    (mavjud) qatorni qaytarishi kerak. mashina_qoshish() to'g'ridan-
    to'g'ri (HTTP/auth qatlamisiz) chaqiriladi - u oddiy Python
    funksiyasi, FastAPI decoratori shunchaki uni ro'yxatga oladi."""
    import main

    SINOV_RAQAM = "RACE-SINOV-01"

    db_a = SessionLocal()
    db_raqib = SessionLocal()
    try:
        assert db_a.query(Mashina).filter(
            Mashina.davlat_raqami == SINOV_RAQAM).first() is None

        # 1-qadam: "bizning" so'rovimiz "mavjudmi" tekshiruvidan o'tadi -
        # hali yo'q.
        mavjud = db_a.query(Mashina).filter(
            Mashina.davlat_raqami == SINOV_RAQAM).first()
        assert mavjud is None

        # 2-qadam: RAQIB tranzaksiya xuddi shu davlat_raqami bilan
        # mashinani yaratib, HAQIQATAN commit qiladi.
        raqib_mashina = Mashina(
            davlat_raqami=SINOV_RAQAM, turi="FAW",
            shofyor="Raqib Shofyor", firma="Raqib Firma", viloyat="Xorazm")
        db_raqib.add(raqib_mashina)
        db_raqib.commit()

        # 3-qadam: "bizning" tranzaksiya endi mashina_qoshish()ning
        # qolgan qismini (INSERT SAVEPOINT) bajaradi - raqib ALLAQACHON
        # committed qilgani uchun unique indeksga uriladi. Tuzatilgan
        # kod buni ushlab, RAQIB yaratgan qatorni qaytarishi SHART.
        natija = main.mashina_qoshish(
            MashinaCreate(davlat_raqami=SINOV_RAQAM, turi="FAW",
                          shofyor="Bizning Shofyor", firma="Bizning Firma",
                          viloyat="Xorazm"),
            db=db_a,
            current_user={"sub": "test", "role": "admin"},
        )

        assert natija.davlat_raqami == SINOV_RAQAM
        assert natija.id == raqib_mashina.id
        # Bizning ("Bizning Shofyor") emas, RAQIBNING yozuvi qaytishi
        # kerak - ikkinchi (bizning) qator umuman yaratilmadi.
        assert natija.shofyor == "Raqib Shofyor"

        qatorlar_soni = db_a.query(Mashina).filter(
            Mashina.davlat_raqami == SINOV_RAQAM).count()
        assert qatorlar_soni == 1, "Ikkita mojarolashgan qator qolib ketmasligi kerak"
    finally:
        db_a.rollback()
        db_raqib.query(Mashina).filter(Mashina.davlat_raqami == SINOV_RAQAM).delete()
        db_raqib.commit()
        db_a.close()
        db_raqib.close()
