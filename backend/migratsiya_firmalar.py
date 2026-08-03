"""
Bir martalik migratsiya skripti:
firmalar jadvalini yaratadi (agar hali yo'q bo'lsa) va hujjatlar/
mashinalar jadvalidagi mavjud (erkin matn) firma nomlaridan noyoblarini
o'sha jadvalga ko'chiradi.

Sabab: Firma endi alohida "tanlov ro'yxati" (operator ekranidagi
autocomplete uchun) sifatida yuritiladi, lekin hujjatlar.firma va
mashinalar.firma ustunlari o'zgarishsiz, erkin matn bo'lib qoladi (FK
yo'q) - bu skript faqat ULARDAN o'qib, Firma jadvaliga QO'SHADI, hech
narsani o'chirmaydi yoki o'zgartirmaydi.
"""
from sqlalchemy import text
from database import engine, Base, SessionLocal
from models import Firma
import models  # noqa: F401 - Base.metadata to'liq bo'lishi uchun barcha modellar yuklanishi kerak


def firmalarni_kochirish():
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    try:
        natija = db.execute(text("""
            SELECT DISTINCT TRIM(firma) AS nom FROM hujjatlar WHERE TRIM(COALESCE(firma, '')) != ''
            UNION
            SELECT DISTINCT TRIM(firma) AS nom FROM mashinalar WHERE TRIM(COALESCE(firma, '')) != ''
        """)).fetchall()

        # Katta-kichik harfga sezgir bo'lmagan holda o'zaro dublikatlarni
        # yig'ish (masalan "Agro" va "agro" bir xil deb hisoblanadi,
        # birinchi uchragan yozilishi saqlanadi).
        noyob_nomlar = {}
        for (nom,) in natija:
            kichik = nom.lower()
            if kichik not in noyob_nomlar:
                noyob_nomlar[kichik] = nom

        qoshildi = 0
        otkazib_yuborildi = 0
        for nom in noyob_nomlar.values():
            mavjud = db.query(Firma).filter(
                Firma.nom.ilike(nom)
            ).first()
            if mavjud:
                otkazib_yuborildi += 1
                continue
            db.add(Firma(nom=nom))
            qoshildi += 1
            print(f"  Qo'shildi: {nom}")

        db.commit()
        print(f"\nJami topilgan noyob nom: {len(noyob_nomlar)}")
        print(f"Yangi qo'shildi: {qoshildi}")
        print(f"Allaqachon mavjud edi (o'tkazib yuborildi): {otkazib_yuborildi}")
    finally:
        db.close()


if __name__ == "__main__":
    firmalarni_kochirish()
    print("Migratsiya tugadi.")
