"""POST /olchovlar - race condition tuzatildi.

Muammo edi: bir xil (hujjat_id, arava_raqam) uchun ikkita so'rov deyarli
bir vaqtda kelsa (masalan operator TARA bosgandan keyin tarozi/frontend
BRUTTO'ni juda tez orqasidan yuborsa), ikkalasi ham "mavjud qator yo'q"
deb ko'rib, IKKITA alohida Olchov qatori yaratardi - natijada netto
(tara bitta qatorda, brutto ikkinchisida qolib) HECH QAYSI qatorda
hisoblanmay qolardi (SELECT-then-INSERT atomik emas edi).

Tuzatish: endi Hujjat qatoriga `FOR UPDATE` qulfi olinadi (main.py,
olchov_saqlash()) - shu qulf COMMIT'gacha ushlab turiladi. Ikkinchi
parallel so'rov DB darajasida HAQIQATAN to'xtab, birinchisi commit
qilgandan keyingina davom etadi va ENDI mavjud qatorni ko'rib, uni
YANGILAYDI (yangi qator yaratmaydi).

DIQQAT (test dizayni haqida): oddiy `threading.Barrier` bilan ikkita
threadni "bir vaqtda" ishga tushirish YETARLI EMAS EDI - sinovdan
o'tkazilganda, Python GIL/thread-jadvallash tufayli ikkinchi thread
odatda birinchisi TUGAGANDAN keyin ishga tushardi, hatto qulf UMUMAN
bo'lmasa ham (test noto'g'ri kodda ham "muvaffaqiyatli" o'tib ketardi -
soxta xavfsizlik). Shu sabab bu yerda A ning COMMIT'i ATAYLAB (Event
bilan) ushlab turiladi - shu orqali "A hali tranzaksiyasini
yakunlamagan" holat VAQTGA/tasodifga emas, balki to'g'ridan-to'g'ri
nazoratga tayanib, DETERMINISTIK simulyatsiya qilinadi.
"""
import threading
import time

from database import SessionLocal
from models import Hujjat, Mahsulot, Mashina, Olchov, HujjatHolati
from schemas import OlchovCreate


def test_parallel_olchov_saqlash_faqat_bitta_qator_yaratadi():
    import main

    db_tayyorlash = SessionLocal()
    try:
        mahsulot = Mahsulot(nom="RACE-OLCHOV-Mahsulot", konditsiya_bor=False, is_active=True)
        db_tayyorlash.add(mahsulot)
        db_tayyorlash.flush()

        mashina = Mashina(davlat_raqami="RACE-OLCHOV-01", turi="FAW",
                           shofyor="Sinov Shofyor", firma="Sinov Firma", viloyat="Xorazm")
        db_tayyorlash.add(mashina)
        db_tayyorlash.flush()

        hujjat = Hujjat(mahsulot_id=mahsulot.id, mashina_id=mashina.id,
                         raqam="RACE-OLCHOV-HUJJAT-001", holat=HujjatHolati.JARAYON,
                         firma="Sinov Firma", shofyor="Sinov Shofyor")
        db_tayyorlash.add(hujjat)
        db_tayyorlash.commit()
        hujjat_id = hujjat.id
        mahsulot_id = mahsulot.id
        mashina_id = mashina.id
    finally:
        db_tayyorlash.close()

    # --- A: birinchi parallel so'rov (TARA) - commit'i ataylab ushlab turiladi ---
    db_a = SessionLocal()
    a_qulflab_boldi = threading.Event()  # A endi FOR UPDATE qulfini olib, commit()ga yetdi
    a_commit_qilsin = threading.Event()  # test shu Event orqali A ga "endi commit qil" deydi
    asl_commit = db_a.commit

    def kechiktirilgan_commit():
        a_qulflab_boldi.set()
        a_commit_qilsin.wait(timeout=5)
        asl_commit()

    db_a.commit = kechiktirilgan_commit

    # --- B: ikkinchi parallel so'rov (BRUTTO) - haqiqiy alohida ulanish/thread ---
    db_b = SessionLocal()
    b_boshladi = threading.Event()
    b_tugadi = threading.Event()
    natijalar = {}
    xatolar = []

    def a_harakati():
        try:
            natija = main.olchov_saqlash(
                OlchovCreate(hujjat_id=hujjat_id, arava_raqam=1, tara=18000),
                db=db_a, current_user={"sub": "test_operator", "role": "operator"})
            natijalar["A"] = natija.id
        except Exception as e:  # noqa: BLE001
            xatolar.append(("A", e))

    def b_harakati():
        try:
            b_boshladi.set()
            natija = main.olchov_saqlash(
                OlchovCreate(hujjat_id=hujjat_id, arava_raqam=1, brutto=23000),
                db=db_b, current_user={"sub": "test_operator", "role": "operator"})
            natijalar["B"] = natija.id
        except Exception as e:  # noqa: BLE001
            xatolar.append(("B", e))
        finally:
            b_tugadi.set()

    try:
        t_a = threading.Thread(target=a_harakati)
        t_a.start()
        # A endi FOR UPDATE qulfini olib, (kechiktirilgan) commit() ichida
        # to'xtab turishini KUTAMIZ - bu aniq, vaqtga tayanmagan sinxronizatsiya.
        assert a_qulflab_boldi.wait(timeout=5), "A commit() nuqtasiga yetmadi"

        t_b = threading.Thread(target=b_harakati)
        t_b.start()
        assert b_boshladi.wait(timeout=5), "B ishga tushmadi"
        # A hali COMMIT QILMAGAN (qulf hamon uning qo'lida) - shu holatda
        # B qisqa muddat ichida hech qachon TUGAMASLIGI kerak, chunki
        # B ning o'z FOR UPDATE so'rovi DB darajasida A ni kutib turishi
        # kerak. (0.4s - B chindan ham bloklanganini ko'rsatish uchun
        # yetarli, ammo testni sekinlashtirmaydigan bufer.)
        time.sleep(0.4)

        assert not b_tugadi.is_set(), (
            "B - A hali commit qilmasdan TURIB tugadi! FOR UPDATE qulfi "
            "ishlamayapti (POST /olchovlar race condition tuzatilmagan)."
        )

        # Endi A ga commit qilishga ruxsat beramiz - B shundan keyingina
        # (A ning qatorini ko'rib) davom etishi kerak.
        a_commit_qilsin.set()
        t_a.join(timeout=5)
        t_b.join(timeout=5)

        assert not xatolar, f"Kutilmagan xatolar: {xatolar}"
        assert natijalar.get("A") is not None and natijalar.get("B") is not None, (
            "Ikkala so'rov ham muvaffaqiyatli yakunlanishi kerak edi"
        )
        # ASOSIY TEKSHIRUV: ikkita ALOHIDA qator EMAS, faqat BITTASI -
        # B A yaratgan qatorni TOPIB, o'shani yangilashi kerak.
        assert natijalar["A"] == natijalar["B"], (
            "A va B bir xil Olchov qatorini yangilashi kerak edi, lekin "
            "ikkita alohida qator yaratilgan - race condition bor!"
        )

        tekshiruv = SessionLocal()
        try:
            qatorlar = tekshiruv.query(Olchov).filter(
                Olchov.hujjat_id == hujjat_id, Olchov.arava_raqam == 1).all()
            assert len(qatorlar) == 1, (
                f"Bitta Olchov qatori kutilgan edi, {len(qatorlar)} ta topildi - "
                "race condition bor!"
            )
            qator = qatorlar[0]
            # Ikkala parallel yozuv BIRLASHGAN bo'lishi kerak - tara HAM,
            # brutto HAM saqlanib qolgan (hech biri yo'qolmagan), va shu
            # ikkalasidan netto to'g'ri hisoblangan.
            assert qator.tara == 18000
            assert qator.brutto == 23000
            assert qator.netto == 5000, (
                "netto ikkala parallel yozuv BIRLASHGANDAN keyin "
                "hisoblanishi kerak edi"
            )
        finally:
            tekshiruv.close()
    finally:
        db_a.close()
        db_b.close()
        tozalash = SessionLocal()
        try:
            tozalash.query(Olchov).filter(Olchov.hujjat_id == hujjat_id).delete()
            tozalash.query(Hujjat).filter(Hujjat.id == hujjat_id).delete()
            tozalash.query(Mashina).filter(Mashina.id == mashina_id).delete()
            tozalash.query(Mahsulot).filter(Mahsulot.id == mahsulot_id).delete()
            tozalash.commit()
        finally:
            tozalash.close()
