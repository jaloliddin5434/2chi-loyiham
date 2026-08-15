# Hazorasp Tekstil — Tarozi Tizimi

Paxta (chigit, chiganoq, chiganoq po'chog'i, patoz) qabul qilish va
tortish jarayonini boshqaruvchi ichki tizim: navbat, tarozi o'qish,
hujjat/nakladnoy yuritish, statistika va moliyaviy hisobot.

Loyiha [Hazorasp Tekstil](https://smart-tarozi.uz) korxonasi uchun
maxsus yozilgan, ichki foydalanish uchun mo'ljallangan.

## Mundarija

- [Arxitektura](#arxitektura)
- [Texnologiyalar](#texnologiyalar)
- [Repozitoriya tuzilishi](#repozitoriya-tuzilishi)
- [Mahalliy ishga tushirish](#mahalliy-ishga-tushirish)
- [Testlar](#testlar)
- [Baza migratsiyalari (Alembic)](#baza-migratsiyalari-alembic)
- [Production joylashtirish](#production-joylashtirish)
- [Backup va tiklash](#backup-va-tiklash)
- [Qo'shimcha hujjatlar](#qoshimcha-hujjatlar)
- [Ishlab chiqish konventsiyalari](#ishlab-chiqish-konventsiyalari)

## Arxitektura

Tizim uchta mustaqil qismdan iborat, ikkita jismonan alohida
kompyuterda ishlaydi (ofis va tarozixona bir xil LAN'da, lekin turli
mashinalar):

```
Tarozixona PC                          Ofis PC (server)
------------------                     -----------------------------
tarozi_agent.py         --- HTTP --->  backend/ (FastAPI)
(KLAS XK3190-A9+                            |
 RS232 orqali)                              v
                                        PostgreSQL 18

                                        frontend/build/web
                                        (python -m http.server)
                                             |
                                        Cloudflare Tunnel
                                             |
                                   smart-tarozi.uz / api.smart-tarozi.uz
                                     (masofadan/telefon kirish)
```

- **backend/** — FastAPI + PostgreSQL. Hujjat/navbat/o'lchov
  boshqaruvi, statistika, moliyaviy hisobot, Excel/nakladnoy
  generatsiyasi, avtomatik backup, Telegram ogohlantirish.
- **frontend/** — Flutter web ilovasi (operator, admin va telefon
  ekranlari). `flutter build web` bilan statik fayllarga
  kompilyatsiya qilinib, oddiy HTTP server orqali beriladi.
- **tarozi_agent/** — tarozixonadagi alohida kompyuterda ishlaydigan
  mustaqil Python dasturi. Tarozini (RS232/COM port) o'qib, tarmoq
  orqali backend'ga yuboradi — backend'ning o'zi tarozi bilan
  to'g'ridan-to'g'ri ishlamaydi (jismonan boshqa kompyuterda).
- **Cloudflare Tunnel** — ofis tashqarisidan (telefon, uy) xavfsiz
  kirish uchun; ofis ichida esa frontend to'g'ridan-to'g'ri mahalliy
  tarmoq (LAN) manzili orqali ochiladi — internetga bog'liq emas.

## Texnologiyalar

| Qism | Texnologiya |
|---|---|
| Backend | Python 3.11, FastAPI, SQLAlchemy 2, Pydantic 2, Alembic |
| Baza | PostgreSQL 18 |
| Frontend | Flutter (Dart, web target) |
| Tarozi agenti | Python (pyserial) |
| Autentifikatsiya | JWT (python-jose), qora ro'yxat orqali logout |
| Fon vazifalari | Python `threading` (backup, Telegram, tunnel monitoring) |
| Tashqi kirish | Cloudflare Tunnel + NSSM (Windows xizmatlari) |
| CI | GitHub Actions — pytest, flutter test, pip-audit |

## Repozitoriya tuzilishi

```
backend/            FastAPI backend
  main.py           Barcha API endpointlari + fon vazifalari
  models.py         SQLAlchemy modellari
  schemas.py        Pydantic so'rov/javob sxemalari
  auth.py           JWT autentifikatsiya
  config.py         .env orqali sozlanadigan barcha qiymatlar
  alembic/          Baza migratsiyalari
  tests/            pytest test to'plami (150+)
  BACKUP_TIKLASH.md Zaxira nusxadan tiklash yo'riqnomasi

frontend/           Flutter web ilovasi
  lib/screens/      Operator, admin, login va h.k. ekranlar
  lib/services/     API mijozi, offline navbat, sinxronizatsiya
  test/             Unit testlar
  integration_test/ Qo'lda ishga tushiriladigan integratsion testlar

tarozi_agent/        Tarozixona kompyuteridagi mustaqil dastur
  tarozi_agent.py
  install_service.bat / uninstall_service.bat   (NSSM orqali)

.github/workflows/  CI konfiguratsiyasi
start.bat           Backend + frontend'ni bitta buyruq bilan ishga tushirish
```

## Mahalliy ishga tushirish

### Talablar

- Python 3.11+
- PostgreSQL 18
- Flutter SDK 3.44+ (Dart SDK `^3.5.0`)
- Windows (production muhit Windows'ga moslashtirilgan — Win32 tarmoq
  API'lari, NSSM, COM port kabi joylar; Linux/macOS'da backend/testlar ishlaydi,
  lekin tarozi agenti va ba'zi backup skriptlari Windows-specific)

### Backend

1. Bazani yarating va `backend/.env` faylini to'ldiring (namuna
   sifatida [`backend/.env.example`](backend/.env.example)ga qarang —
   har bir o'zgaruvchi izohi bilan `backend/config.py`da ham
   ko'rsatilgan). Eng kamida:

   ```
   DATABASE_URL=postgresql+psycopg2://postgres:PAROL@localhost:5432/hazorasp_tarozi?client_encoding=utf8
   SECRET_KEY=<tasodifiy, uzun maxfiy satr>
   TAROZI_AGENT_KEY=<tarozi_agent/.env bilan bir xil qiymat>
   ```

   Telegram xabarnomalari, kamera integratsiyasi, tarmoq backup kabi
   qo'shimcha funksiyalar o'zlarining `.env` o'zgaruvchilari
   to'ldirilmasa, xato bermay, shunchaki o'chiq holda ishlaydi.

2. Bog'liqliklarni o'rnating va serverni ishga tushiring:

   ```
   cd backend
   pip install -r requirements.txt
   uvicorn main:app --host 0.0.0.0 --port 47001 --forwarded-allow-ips=
   ```

   `--forwarded-allow-ips=` bayrog'i ATAYLAB bo'sh — Cloudflare
   Tunnel orqasida ishlaganda `X-Forwarded-For` sarlavhasi orqali
   tezlik-cheklovini chetlab o'tish zaifligini yopadi (qarang:
   `main.py`dagi `_mijoz_ip()` izohi).

3. Bo'sh bazada birinchi marta `POST /setup` so'rovini yuboring —
   standart `admin`/`admin123` va `operator`/`operator123`
   hisoblarini hamda asosiy mahsulotlarni (Chigit, Chiganoq,
   Chiganoq po'chog'i, Patoz) yaratadi. **Darhol standart parollarni
   almashtiring.**

### Frontend

```
cd frontend
flutter pub get
flutter build web --release
cd build/web && python -m http.server 47080
```

Ishlab chiqish paytida tezroq iteratsiya uchun `flutter run -d chrome`
ham ishlatish mumkin (`lib/services/api_service.dart`dagi `baseUrl`
manzilini mahalliy backend'ingizga mos sozlang).

### Ikkalasini birga (production PC'da)

`start.bat` — backend va frontend serverini bitta buyruq bilan
(alohida oynalarda) ishga tushiradi. Production'da bu ikkalasi NSSM
orqali Windows xizmati sifatida ham o'rnatilishi mumkin (qarang:
`tarozi_agent/install_service.bat` — xuddi shu naqsh backend/frontend
uchun ham qo'llanilgan).

### Tarozi agenti (faqat tarozixona kompyuterida)

```
cd tarozi_agent
pip install -r requirements.txt
copy .env.example .env   # TAROZI_PORT, SERVER_URL, TAROZI_AGENT_KEY'ni to'ldiring
python tarozi_agent.py
```

Doimiy ishlashi uchun `install_service.bat` orqali Windows xizmati
sifatida o'rnatiladi (Administrator huquqi bilan ishga tushirilishi
kerak). Muammolar uchun `COM_PORT_MUAMMOSI.md`ga qarang.

## Testlar

**Backend** (pytest, alohida `hazorasp_tarozi_test` bazasida —
production bazaga hech qachon tegilmaydi):

```
cd backend
pytest tests/ -v
```

**Frontend** (unit testlar, `frontend/test/`):

```
cd frontend
flutter test
```

`frontend/integration_test/`dagi testlar ATAYLAB avtomatik CI'ga
kirmaydi — ular real, ishlab turgan backend'ga (ofis LAN) ulanib
sinaydigan, qo'lda ishga tushiriladigan tekshiruvlar.

CI (GitHub Actions) har bir push/PR'da ikkala test to'plamini, hamda
backend bog'liqliklarini `pip-audit` bilan xavfsizlik bo'yicha
skanerlaydi (`.github/workflows/tests.yml`).

## Baza migratsiyalari (Alembic)

Sxema o'zgarishlari Alembic orqali boshqariladi:

```
cd backend
alembic revision --autogenerate -m "o'zgarish tavsifi"
# generatsiya qilingan faylni ko'rib chiqing (ayniqsa avtogenerate
# ba'zan daxlsiz, tasodifiy farqlarni ham qo'shib yuboradi)
alembic upgrade head
```

`alembic/versions/`dagi ilk migratsiya (`boshlangich sxema`) ATAYLAB
bo'sh — u faqat mavjud production bazasini "shu nuqtadan boshlanadi"
deb belgilash (`alembic stamp head`) uchun yaratilgan, hech qanday DDL
bajarmaydi.

## Production joylashtirish

Joriy production — **HikCentral** nomli Windows kompyuter
(host nomi: `WIN-G8VAAPDMF64`, LAN manzili: `10.112.21.54`). Bu —
loyihaning boshqa (dev/build) kompyuteridan (`AKT`) butunlay alohida,
jismonan boshqa mashina — ular orasidagi farqni chalkashtirmaslik
2026-08-15dagi tekshiruv sabab bo'lgan bir nechta soatlik chalkashlikdan
keyin alohida ta'kidlanmoqda. Agar production boshqa kompyuterga
ko'chirilsa, shu bo'lim (hostname, IP) VA
`frontend/lib/services/api_service.dart`dagi `_lanBaseUrl` YANGILANISHI
SHART (qarang: o'sha faylning izohi).

- **Backend** — `uvicorn`, port `47001`.
- **Frontend** — `python -m http.server`, port `47080`.
- **PostgreSQL 18** — mahalliy, port `47432`.
- **Cloudflare Tunnel** (`cloudflared.exe`, NSSM xizmati sifatida —
  Cloudflare'ning o'zining Windows xizmat rejimi bu muhitda ishlamagani
  uchun) quyidagi manzillarni oshkor qiladi:
  - `smart-tarozi.uz`, `app.smart-tarozi.uz` -> `localhost:47080`
    (frontend)
  - `api.smart-tarozi.uz` -> `localhost:47001` (backend)
- Ofis ichidagi kompyuterlar frontend'ni **to'g'ridan-to'g'ri
  mahalliy tarmoq manzili** (`http://<server-ip>:47080`) orqali
  ochadi — bu holda API so'rovlari ham avval mahalliy backend'ga
  urinadi, faqat u javob bermasa Cloudflare domeniga o'tadi (qarang:
  `frontend/lib/services/api_service.dart`dagi `baseUrlniAniqlash()`)
  — shu bilan ofis ishi internetdan mustaqil bo'lib qoladi.
- Ikki qatlamli monitoring: backend o'zi (Cloudflare Tunnel/tarozi
  aloqasini) kuzatadi, va tarozi agenti ham backend/tarmoqni mustaqil
  kuzatadi — ikkalasi ham muammo bo'lsa Telegram orqali ogohlantiradi.

## Backup va tiklash

- Baza har kuni avtomatik zaxiralanadi (`backend/main.py`dagi
  `avtomatik_backup()` fon vazifasi) — mahalliy `backup/` papkasiga
  VA (sozlangan bo'lsa) ikkinchi kompyuterdagi tarmoq ulashuviga.
  30 kundan eski nusxalar avtomatik tozalanadi.
- Tortish tasdiqlovchi rasmlar/nakladnoy fayllari (`C:/RASMLAR`,
  standart) ham kunlik tarmoqqa zaxiralanadi.
- **Tiklash** uchun to'liq, sinovdan o'tgan qadam-baqadam yo'riqnoma:
  [`backend/BACKUP_TIKLASH.md`](backend/BACKUP_TIKLASH.md).

## Qo'shimcha hujjatlar

- [`backend/BACKUP_TIKLASH.md`](backend/BACKUP_TIKLASH.md) — baza
  zaxira nusxasini tiklash runbook'i.
- [`tarozi_agent/COM_PORT_MUAMMOSI.md`](tarozi_agent/COM_PORT_MUAMMOSI.md)
  — tarozi COM port ulanish muammolarini bartaraf etish.
- [`tarozi_agent/TAROZI_AGENT_KEY_ROTATSIYASI.md`](tarozi_agent/TAROZI_AGENT_KEY_ROTATSIYASI.md)
  — tarozi agenti maxfiy kalitini almashtirish tartibi.
- [`HIKCENTRAL_SERVER_TEKSHIRUV_REJA.md`](HIKCENTRAL_SERVER_TEKSHIRUV_REJA.md)
  — kamera (HikCentral) integratsiyasi bo'yicha tekshiruv rejasi.

## Ishlab chiqish konventsiyalari

- **Til**: barcha kod, izoh, xato xabarlari, commit xabarlari — o'zbek
  tilida (funksiya/o'zgaruvchi nomlari ham). README ham shu
  konventsiyaga amal qiladi.
- **Real sinov birinchi**: har bir o'zgarish nazariy mulohaza emas,
  real HTTP so'rov/real baza holati/real fayl tizimi bilan
  tasdiqlanadi — testlar shu falsafani aks ettiradi (masalan
  `tests/test_race_condition.py` haqiqiy, mustaqil ikkita DB
  ulanishi orasidagi to'qnashuvni sinaydi, mock emas).
- **Izohlar — "nima" emas, "nega"**: kod o'zi nima qilishini
  ko'rsatadi; izohlar faqat nozik cheklov, tarixiy sabab yoki
  keyingi o'zgaruvchiga ogohlantirish kerak bo'lganda yoziladi.
- **Xavfsizlik**: har qanday maxfiy ma'lumot (parol, kalit) faqat
  `.env` orqali (hech qachon kodga qattiq yozilmaydi va hech qachon
  process argumenti yoki konsol orqali uzatilmaydi — qarang:
  `_tarmoqqa_ulan()` funksiyasi, `WNetAddConnection2W` Win32 API'ni
  ctypes orqali to'g'ridan-to'g'ri chaqiradi, parol hech qanday
  subprocess argumentida yoki konsolda ko'rinmaydi).
