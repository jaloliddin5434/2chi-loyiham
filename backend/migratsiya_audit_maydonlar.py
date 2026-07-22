"""
Bir martalik migratsiya skripti:
1. hujjatlar jadvaliga 10 ta yangi ustun qo'shadi (mashina_raqami, shofyor, firma,
   tiket_raqam, klass, sinf, seleksiya_navi, terim_turi, qabul_qildi, yuk_olindi).
2. tahrir_tarixi jadvalini yaratadi (models.py dagi TahrirTarixi ORM ta'rifidan).
3. Mavjud hujjatlar uchun backfill:
   - mashina_raqami/shofyor/firma - bog'langan Mashina yozuvidan
   - tiket_raqam/klass/sinf/seleksiya_navi/terim_turi - agar shu hujjatga bog'langan
     Navbat yozuvi mavjud bo'lsa va u maydon to'ldirilgan bo'lsa, undan olinadi
     (qabul_qildi/yuk_olindi uchun Navbat'da ham manba yo'q, bo'sh qoladi)
"""
from sqlalchemy import text
from database import engine, Base
import models

YANGI_USTUNLAR = [
    "mashina_raqami", "shofyor", "firma", "tiket_raqam",
    "klass", "sinf", "seleksiya_navi", "terim_turi",
    "qabul_qildi", "yuk_olindi",
]

def ustunlarni_qoshish(conn):
    for ustun in YANGI_USTUNLAR:
        conn.execute(text(f"ALTER TABLE hujjatlar ADD COLUMN IF NOT EXISTS {ustun} VARCHAR"))
    print("Ustunlar qo'shildi (yoki allaqachon mavjud edi):", YANGI_USTUNLAR)

def jadval_yaratish():
    Base.metadata.create_all(bind=engine)
    print("tahrir_tarixi jadvali tayyor (create_all)")

def backfill_mashinadan(conn):
    natija = conn.execute(text("""
        UPDATE hujjatlar h SET
            mashina_raqami = m.davlat_raqami,
            shofyor = m.shofyor,
            firma = m.firma
        FROM mashinalar m
        WHERE h.mashina_id = m.id
          AND h.mashina_raqami IS NULL
    """))
    print(f"Mashina'dan backfill qilindi: {natija.rowcount} qator")

def backfill_navbatdan(conn):
    ustun_juftlar = [
        ("tiket_raqam", "tiket_raqam"),
        ("klass", "klass"),
        ("sinf", "sinf"),
        ("seleksiya_navi", "seleksiya_navi"),
        ("terim_turi", "terim_turi"),
    ]
    for hujjat_ustun, navbat_ustun in ustun_juftlar:
        natija = conn.execute(text(f"""
            UPDATE hujjatlar h SET {hujjat_ustun} = n.{navbat_ustun}
            FROM navbat n
            WHERE n.hujjat_id = h.id
              AND h.{hujjat_ustun} IS NULL
              AND n.{navbat_ustun} IS NOT NULL
              AND n.{navbat_ustun} != ''
        """))
        print(f"Navbat'dan backfill ({hujjat_ustun}): {natija.rowcount} qator")

if __name__ == "__main__":
    jadval_yaratish()
    with engine.begin() as conn:
        ustunlarni_qoshish(conn)
        backfill_mashinadan(conn)
        backfill_navbatdan(conn)
    print("Migratsiya tugadi.")
