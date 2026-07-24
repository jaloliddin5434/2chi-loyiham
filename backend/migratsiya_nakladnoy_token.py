"""
Bir martalik migratsiya skripti:
hujjatlar jadvaliga nakladnoy_token ustunini qo'shadi.

Sabab: Nakladnoyga QR kod qo'shiladi - QR kod login talab qilmaydigan
GET /nakladnoy-korish/{token} endpointiga ishora qiladi. Xavfsizlik
uchun hujjat_id (ketma-ket, taxmin qilinadigan) o'rniga tasodifiy,
noyob token ishlatiladi - shunda kimdir ID'larni ketma-ket sinab
boshqa hujjatlarni ko'ra olmaydi (IDOR oldi olinadi). Token birinchi
nakladnoy saqlanganda "lazy" generatsiya qilinadi va saqlanadi.
"""
from sqlalchemy import text
from database import engine


def ustun_qoshish(conn):
    conn.execute(text(
        "ALTER TABLE hujjatlar ADD COLUMN IF NOT EXISTS nakladnoy_token VARCHAR"
    ))
    mavjud = conn.execute(text("""
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'hujjatlar'::regclass
          AND conname = 'uq_hujjatlar_nakladnoy_token'
    """)).first()
    if not mavjud:
        conn.execute(text(
            "ALTER TABLE hujjatlar ADD CONSTRAINT uq_hujjatlar_nakladnoy_token UNIQUE (nakladnoy_token)"
        ))
        print("Unique cheklov (nakladnoy_token) qo'shildi")
    else:
        print("Unique cheklov (nakladnoy_token) allaqachon mavjud")

    mavjud_index = conn.execute(text("""
        SELECT 1 FROM pg_indexes
        WHERE tablename = 'hujjatlar' AND indexname = 'ix_hujjatlar_nakladnoy_token'
    """)).first()
    if not mavjud_index:
        conn.execute(text(
            "CREATE INDEX ix_hujjatlar_nakladnoy_token ON hujjatlar (nakladnoy_token)"
        ))
        print("Indeks (nakladnoy_token) qo'shildi")
    else:
        print("Indeks (nakladnoy_token) allaqachon mavjud")

    print("Ustun qo'shildi (yoki allaqachon mavjud edi): nakladnoy_token")


if __name__ == "__main__":
    with engine.begin() as conn:
        ustun_qoshish(conn)
    print("Migratsiya tugadi.")
