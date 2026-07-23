"""
Bir martalik migratsiya skripti:
hujjatlar jadvaliga 2 ta yangi ustun qo'shadi: dostaverka, dostaverka_vaqt.

Sabab: Nakladnoy PDF generatsiyasi endi to'liq bazadan (frontend ekran
holatidan mustaqil) o'qiydi. "Dostaverna No" va "Muddat" maydonlari avval
hech qanday jadvalda saqlanmagan, faqat frontend formasida yashagan - shu
sababli bu ustunlar qo'shildi.
"""
from sqlalchemy import text
from database import engine

YANGI_USTUNLAR = ["dostaverka", "dostaverka_vaqt"]


def ustunlarni_qoshish(conn):
    for ustun in YANGI_USTUNLAR:
        conn.execute(text(f"ALTER TABLE hujjatlar ADD COLUMN IF NOT EXISTS {ustun} VARCHAR"))
    print("Ustunlar qo'shildi (yoki allaqachon mavjud edi):", YANGI_USTUNLAR)


if __name__ == "__main__":
    with engine.begin() as conn:
        ustunlarni_qoshish(conn)
    print("Migratsiya tugadi.")
