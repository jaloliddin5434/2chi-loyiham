"""
Bir martalik migratsiya skripti:
Hujjat raqami hisoblagichini "yil" bo'yicha umumiy hisobdan "yil + mahsulot"
bo'yicha alohida hisobga o'tkazadi (har bir mahsulot o'z mustaqil ketma-ketligiga
ega bo'lishi uchun - CHG-2026/001, CHN-2026/001 va h.k.).

1. hujjat_raqam_hisoblagich jadvaliga yangi ustunlar qo'shadi: id (surrogate PK),
   mahsulot_id (nullable - eski umumiy qator uchun NULL bo'lib qoladi).
2. Eski primary key (yil ustunida)ni yangi id ustuniga ko'chiradi.
3. (yil, mahsulot_id) bo'yicha unique cheklov qo'shadi.

Eslatma: eski qator (yil=2026, mahsulot_id=NULL, oxirgi_raqam=<eski qiymat>)ga
HECH QANDAY tegilmaydi - u tarixiy ma'lumot sifatida bazada qoladi, endi
ishlatilmaydi. Mavjud hujjatlarning "raqam" ustuniga ham bu skript tegmaydi.
"""
from sqlalchemy import text
from database import engine


def ustunlarni_qoshish(conn):
    conn.execute(text(
        "ALTER TABLE hujjat_raqam_hisoblagich ADD COLUMN IF NOT EXISTS mahsulot_id INTEGER"
    ))
    conn.execute(text(
        "ALTER TABLE hujjat_raqam_hisoblagich ADD COLUMN IF NOT EXISTS id SERIAL"
    ))
    print("Ustunlar qo'shildi (yoki allaqachon mavjud edi): mahsulot_id, id")


def primary_key_kochirish(conn):
    mavjud = conn.execute(text("""
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'hujjat_raqam_hisoblagich'::regclass
          AND contype = 'p'
          AND conname = 'hujjat_raqam_hisoblagich_pkey'
          AND conkey = (
              SELECT array_agg(attnum) FROM pg_attribute
              WHERE attrelid = 'hujjat_raqam_hisoblagich'::regclass AND attname = 'id'
          )
    """)).first()

    if mavjud:
        print("Primary key allaqachon 'id' ustunida - o'tkazib yuborildi")
        return

    conn.execute(text(
        "ALTER TABLE hujjat_raqam_hisoblagich DROP CONSTRAINT IF EXISTS hujjat_raqam_hisoblagich_pkey"
    ))
    conn.execute(text(
        "ALTER TABLE hujjat_raqam_hisoblagich ADD PRIMARY KEY (id)"
    ))
    print("Primary key 'yil' dan 'id' ustuniga ko'chirildi")


def unique_cheklov_qoshish(conn):
    mavjud = conn.execute(text("""
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'hujjat_raqam_hisoblagich'::regclass
          AND conname = 'uq_hujjat_raqam_hisoblagich_yil_mahsulot'
    """)).first()

    if mavjud:
        print("Unique cheklov (yil, mahsulot_id) allaqachon mavjud - o'tkazib yuborildi")
        return

    conn.execute(text(
        "ALTER TABLE hujjat_raqam_hisoblagich "
        "ADD CONSTRAINT uq_hujjat_raqam_hisoblagich_yil_mahsulot UNIQUE (yil, mahsulot_id)"
    ))
    print("Unique cheklov (yil, mahsulot_id) qo'shildi")


if __name__ == "__main__":
    with engine.begin() as conn:
        ustunlarni_qoshish(conn)
        primary_key_kochirish(conn)
        unique_cheklov_qoshish(conn)
    print("Migratsiya tugadi.")
