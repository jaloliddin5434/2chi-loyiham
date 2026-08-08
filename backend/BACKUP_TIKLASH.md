# Baza zaxira nusxasini tiklash (restore) — runbook

Bu hujjat **real falokat holatida** (server ishdan chiqqan, baza
shikastlangan, yangi kompyuterga migratsiya qilinayotganda) bazani
`backup/`dagi `.sql` fayldan tiklash uchun qadam-baqadam yo'riqnoma.

**2026-08-07'da sinovdan o'tkazilgan:** eng so'nggi backup (`backup_2026-08-07_08-43-17.sql`,
468 KB) alohida test bazaga **528 ms** ichida, hech qanday xatosiz tiklandi;
sxema (`models.py` bilan) va ma'lumotlar production bilan to'liq mos
chiqdi. Quyidagi buyruqlar shu sinov asosida yozilgan.

## Muhim texnik fakt

Backup fayllar **oddiy matn SQL** formatida (`pg_dump`, standart `-Fp`,
`-F` bayrog'isiz) — bu degani tiklash **`pg_restore` orqali EMAS**,
balki **`psql -f fayl.sql`** orqali bo'ladi. (`pg_restore` faqat
custom/tar/directory formatlar uchun — bizda ular yo'q.)

Fayllar `\restrict ...` buyrug'ini o'z ichiga oladi (PostgreSQL 18'ning
xavfsizlik belgisi) — shu sabab tiklash **PostgreSQL 18 `psql`** bilan
qilinishi shart (eskiroq versiya buni tushunmaydi).

## Zarurlar

- PostgreSQL 18 o'rnatilgan (`psql.exe`, `createdb.exe`, `dropdb.exe` —
  odatda `C:\Program Files\PostgreSQL\18\bin\`).
- `backup\` papkasidagi kerakli `.sql` fayl.
- `backend\.env`dagi `DATABASE_URL`dan foydalanuvchi/parol/port/baza nomini
  bilish (masalan `postgresql+psycopg2://postgres:XXXXXX@localhost:47432/hazorasp_tarozi`
  — bu yerda foydalanuvchi=`postgres`, port=`47432`, baza nomi=`hazorasp_tarozi`).
- Windows Administrator huquqi shart emas (agar Postgres xizmati allaqachon
  ishlab tursa) — faqat Postgres foydalanuvchi paroli kerak.

## A) Yangi (bo'sh) serverga birinchi marta tiklash

Bu — server migratsiyasi paytidagi holat (baza hali umuman yo'q).

1. Yangi, bo'sh baza yaratish:
   ```
   createdb -U postgres -p 47432 hazorasp_tarozi
   ```
2. Tanlangan backup faylni yuklash (eng so'nggisi tavsiya etiladi):
   ```
   psql -U postgres -p 47432 -d hazorasp_tarozi -f "C:\hazorasp_tarozi\backup\backup_ENG_SONGGI.sql"
   ```
3. Pastdagi **"Tiklashdan keyingi tekshiruv"** bo'limiga o'ting.

## B) Mavjud, ishlayotgan (lekin buzilgan/shubhali) bazani tiklash

⚠️ **ESKI BAZANI DARHOL O'CHIRMANG** — avval nomini o'zgartiring, shunda
xato bo'lsa orqaga qaytish imkoni qoladi:

1. Backend'ni to'xtating (aks holda u eski bazaga ulanishda davom etadi):
   xizmat sifatida ishlayotgan bo'lsa `Stop-Service`, yoki `uvicorn`
   oynasini yoping.
2. Buzilgan bazani **o'chirmasdan**, boshqa nomga o'zgartiring:
   ```
   psql -U postgres -p 47432 -d postgres -c "ALTER DATABASE hazorasp_tarozi RENAME TO hazorasp_tarozi_buzilgan_2026_08_08;"
   ```
   (agar faol ulanishlar bo'lgani uchun bu buyruq xato bersa — avval
   backend/boshqa hech kim ulanmaganini tasdiqlang, kerak bo'lsa
   `SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='hazorasp_tarozi';`
   bilan mavjud ulanishlarni yoping.)
3. Yangi, toza nom bilan asl bazani qayta yaratish va tiklash — yuqoridagi
   **A) bo'limi 1-2-qadamlarini** aynan bajaring.
4. Tekshiruvdan (pastda) muvaffaqiyatli o'tgach, backend'ni qayta ishga
   tushiring.
5. Bir necha kun kuzatib, hammasi to'g'ri ishlashiga ishonch hosil
   qilgach, eski (`_buzilgan_...` nomli) bazani `dropdb` bilan
   o'chirishingiz mumkin — shoshilmang.

## Tiklashdan keyingi tekshiruv (HAR IKKALA stsenariyda ham)

1. **`.env` to'g'riligini tasdiqlash** — `backend\.env`dagi `DATABASE_URL`
   tiklangan baza nomiga to'g'ri ishora qilishini tekshiring.
2. **Qator sonlarini solishtirish** — agar eski (yoki boshqa nusxadagi)
   ma'lumot bilan solishtirish imkoni bo'lsa:
   ```sql
   SELECT COUNT(*) FROM hujjatlar;
   SELECT COUNT(*) FROM olchovlar;
   SELECT COUNT(*) FROM users;
   ```
   Tiklangan baza backup OLINGAN VAQTGACHA bo'lgan ma'lumotni aks
   ettiradi — agar backup bir necha soat/kun oldin olingan bo'lsa,
   son biroz KAMROQ bo'lishi **kutilgan holat**, xato emas.
3. **Sxema to'liqligini tasdiqlash** (ixtiyoriy, lekin tavsiya etiladi) —
   `backend\`dan turib:
   ```
   python -c "
   from sqlalchemy import create_engine, inspect
   from database import Base
   import models
   e = create_engine('postgresql+psycopg2://postgres:PAROL@localhost:47432/hazorasp_tarozi')
   insp = inspect(e)
   db = set(insp.get_table_names())
   model = set(Base.metadata.tables.keys())
   print('Farq (bazada yo\'q):', model - db)
   print('Farq (modelda yo\'q):', db - model)
   "
   ```
   Ikkala qator ham bo'sh chiqishi kerak.
4. **Backend'ni ishga tushirish** (`start.bat` yoki xizmat orqali) va
   xatosiz ko'tarilishini tasdiqlash.
5. **Brauzerda yakuniy tasdiqlash** — login qilib, bir nechta hujjatni
   ochib ko'ring (masalan `GET /hujjatlar` ro'yxati to'g'ri chiqayotganini).

## Vaqt taxmini

Hozirgi baza hajmida (~10 MB) butun texnik tiklash jarayoni **1 soniyadan
kam** vaqt oladi (sinovda 528 ms). Baza kelajakda kattalashsa (masalan
yuzlab MB/bir necha GB), bu vaqt oshadi — lekin `psql -f` jarayoni baribir
odatda daqiqalar (soatlar emas) darajasida qoladi. Butun runbook (baza
yaratish + tiklash + tekshiruv + backend qayta ishga tushirish) — hozirgi
hajmda **15-20 daqiqa**, asosiy vaqt tekshiruv qadamlariga ketadi.
