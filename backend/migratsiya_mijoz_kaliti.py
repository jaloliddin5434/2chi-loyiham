"""
Bir martalik migratsiya skripti:
hujjatlar jadvaliga mijoz_kaliti (client_ref) ustunini qo'shadi.

Sabab: operator ekranida OFFLINE yaratilgan hujjatlar uchun frontend
mahalliy noyob kalit generatsiya qiladi va uni shu ustunga yuboradi.
Agar tarmoq javobi yo'qolib, frontend so'rovni qayta yuborsa,
POST /hujjatlar avval "shu mijoz_kaliti bilan hujjat allaqachon bormi?"
tekshiradi - bo'lsa, YANGISINI YARATMASDAN mavjudini qaytaradi (xuddi
mashinalar jadvalidagi davlat_raqami bo'yicha idempotentlik kabi).
"""
from sqlalchemy import text
from database import engine


def ustun_qoshish(conn):
    conn.execute(text(
        "ALTER TABLE hujjatlar ADD COLUMN IF NOT EXISTS mijoz_kaliti VARCHAR"
    ))
    mavjud = conn.execute(text("""
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'hujjatlar'::regclass
          AND conname = 'uq_hujjatlar_mijoz_kaliti'
    """)).first()
    if not mavjud:
        conn.execute(text(
            "ALTER TABLE hujjatlar ADD CONSTRAINT uq_hujjatlar_mijoz_kaliti UNIQUE (mijoz_kaliti)"
        ))
        print("Unique cheklov (mijoz_kaliti) qo'shildi")
    else:
        print("Unique cheklov (mijoz_kaliti) allaqachon mavjud")
    print("Ustun qo'shildi (yoki allaqachon mavjud edi): mijoz_kaliti")


if __name__ == "__main__":
    with engine.begin() as conn:
        ustun_qoshish(conn)
    print("Migratsiya tugadi.")
