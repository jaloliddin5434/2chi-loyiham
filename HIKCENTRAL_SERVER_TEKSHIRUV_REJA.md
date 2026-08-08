# HikCentral kompyuteriga server ko'chirish - tekshiruv va xavfsizlik rejasi

Bu hujjat - ofisdagi HikCentral kompyuteriga bizning backend+frontend+PostgreSQL
stack'ini o'rnatishdan OLDINGI tayyorgarlik rejasi. Hech qanday o'rnatish/
o'zgartirish HALI amalga oshirilmagan - bu FAQAT reja va tekshiruv natijasi.

## YAKUNIY XULOSA (2026-08-08, haqiqiy HikCentral kompyuterida tekshirilgan)

**O'RNATISH XAVFSIZ - hech qanday to'siq topilmadi.** Barcha 15 bo'lim
haqiqiy HikCentral kompyuterida (Windows 10 Pro, build 19041, oxirgi qayta
yuklanish 2026-08-01) tekshirildi:

| Ko'rsatkich | Natija | Xulosa |
|---|---|---|
| Portlar (8001, 8080) | Barchasi BO'SH | To'qnashuv yo'q |
| Port 5432 | HikCentral'ning o'z PostgreSQL'i band | Kutilgan, bizga aloqasi yo'q |
| Port 5544 (Postgres uchun tanlangan yangi port) | **HALI TEKSHIRILMAGAN** | Dastlabki tekshiruvda faqat 5433 tekshirilgan edi - 5544'ni alohida tasdiqlash kerak (pastga qarang) |
| Disk C: | 237,9 GB jami, **187,1 GB bo'sh (78,7%)** | Sog'lom - bizning ~1 GB'lik og'irligimiz uchun katta marja |
| RAM | 15,7 GB jami, **8 GB bo'sh (51%)** | Sog'lom marja |
| CPU | Eng og'ir jarayonlar - HikCentral'ning o'zi (media/BeeGuard/SYS) | Kutilgan (video striming), bizga bog'liq emas |
| Python/Git/PostgreSQL | Uchalasi ham O'RNATILMAGAN | Toza muhit - versiya to'qnashuvi xavfi yo'q |
| Firewall | 3 profil ham yoqilgan, 503 qoida | HikCentral uchun mavjud qoidalar bor - namuna sifatida foydalanish mumkin |
| System Restore | **FAOL** - so'nggi 3 checkpoint: 2026-07-19, 2026-07-28, 2026-08-06 | Rollback tarmog'i ALLAQACHON ishlaydi (kalibrlash kompyuteridan farqli o'laroq) |

**Port qarori yangilandi**: dastlab Postgres uchun 5433 taklif qilingan edi,
lekin HikCentral'ning o'z portidan (5432) yanada aniqroq, uzoqroq
ajratilishi uchun **5544** portiga o'tildi. 5544 dastlabki tekshiruvda
tekshirilmagan edi - o'rnatishdan oldin pastdagi buyruq bilan alohida
tasdiqlanishi shart.

Yagona diqqat talab qiladigan nuqta: video arxiv joyi alohida diskda emas,
`C:\Program Files (x86)\HikCentral` ichida, ya'ni C: diskning o'zida
saqlanadi. Bu muammo emas (C: da 187 GB bo'sh), lekin shuni bildiradiki -
bizning stack ham, HikCentral'ning video arxivi ham BIR XIL diskni
ulashadi - kelajakda video arxiv o'sishi C: diskning bo'sh joyini
kamaytirib borishini davriy nazorat qilish tavsiya etiladi (masalan disk
bo'sh joyini oylik tekshirib turish).

## Kalibrlash: nima kutish mumkinligi haqida real ma'lumot

`hikcentral_tekshiruv.ps1` skriptini (quyida) dastlab **shu dev-kompyuterda**
ishga tushirdik - chunki bu kompyuterda ham (boshqa, ammo o'xshash) HikCentral
Professional 3.0.1 allaqachon o'rnatilgan va bizning stack (backend:8001,
frontend:8080, PostgreSQL 18:5433) bir necha kundan beri u bilan yonma-yon,
muvaffaqiyatli ishlab turibdi. Bu haqiqiy o'rnatishga TEGISHLI EMAS (haqiqiy
kompyuter boshqa), lekin HikCentral Professional nima ishlatishi mumkinligi
haqida qimmatli, real namuna berdi:

- HikCentral Professional **PostgreSQL'ning o'z instansiyasini** o'rnatadi
  (odatda port **5432**) - shu sabab bizning Postgres albatta BOSHQA portda
  (5544 - HikCentral'ning 5432'sidan aniq uzoq) o'rnatilishi SHART.
- HikCentral juda ko'p portdan foydalanadi: Nginx (80, 443, 18001-18010),
  Streaming Gateway/media (83, 554, 559, 1935), SYS core xizmati (6000-10000+
  oralig'ida o'nlab dinamik port), BeeAgent va boshqa "Bee*" nomli ichki
  komponentlar (5208, 6208, 7208, 8208 kabi).
- Bizning odatiy portlarimiz (8001, 8080) HikCentral bilan hech qachon
  to'qnashmagan - lekin bu HAR BIR o'rnatishda alohida tasdiqlanishi kerak,
  chunki HikCentral versiyasi/sozlamalariga qarab portlar farq qilishi mumkin.
- **Muhim ogohlantirish**: shu kalibrlash kompyuterida C: diskda atigi 6,6%
  (7,9 GB) bo'sh joy qolgan edi - bu HikCentral+dev vositalari yig'indisi
  natijasi. Bu HAQIQIY o'rnatish kompyuterida ham tekshirilishi SHART,
  taxmin qilib bo'lmaydi.

## 1. Tekshiruv skripti

`hikcentral_tekshiruv.ps1` - **100% faqat-o'qish** (hech qanday `Set-`/`New-`/
`Remove-`/`Stop-`/`Start-`/`Install-` buyrug'i yo'q), HikCentral kompyuteriga
hech qanday iz qoldirmasdan quyidagilarni aniqlaydi:

1. Tizim asosiy ma'lumotlari (OS, uptime)
2. BARCHA tinglayotgan TCP portlar - to'liq exe yo'li va kompaniya nomi bilan
3. BARCHA tinglayotgan UDP portlar
4. Bizga kerak bo'lishi mumkin bo'lgan portlar (8001, 8080, 5432, 5544, 5000,
   8000, 3000, 8888) band-bandligi
5. BARCHA nostandart (Microsoft'dan boshqa) xizmatlar to'liq ro'yxati -
   nafaqat "Hik" nomi bilan, balki Redis/Mongo/RabbitMQ/Nginx/Postgres kabi
   HikCentral bilan birga o'rnatiladigan yordamchi komponentlarni ham
6-7. Hik*/iSecure/Postgres/SQL Server nomli xizmatlarni tezkor filtrlash
8. Har bir diskning bo'sh joyi
9. HikCentral/video arxiv joylashgan joyni topishga urinish
10. RAM - umumiy va eng ko'p ishlatayotgan 15 ta jarayon
11. CPU - 5 soniyalik real namuna + eng og'ir 10 ta jarayon
12. Barcha o'rnatilgan dasturlar (versiyalari bilan)
13. Python/Git/PostgreSQL allaqachon o'rnatilganmi
14. Firewall holati va qoidalar soni
15. Windows System Restore holati (mavjud checkpoint'lar)

**Ishga tushirish**: skriptni HikCentral kompyuteriga nusxalab, PowerShell'ni
"Run as Administrator" bilan ochib, ishga tushiring. Natija avtomatik
`%TEMP%\hikcentral_tekshiruv_natija_*.txt` fayliga ham saqlanadi - shu faylni
menga yuboring.

## 2. Disk joyi - TASDIQLANDI XAVFSIZ

Haqiqiy HikCentral kompyuterida C: diskda **187,1 GB bo'sh (78,7%)**.
Bizning REAL o'lchangan og'irligimiz (dev-kompyuterdagi mavjud
o'rnatishdan): repo manba kodi ~15-20 MB, PostgreSQL data papkasi hozircha
~78 MB (biznes ma'lumoti bilan sekin o'sadi), backup fayllari ~6 MB (30 kunlik
avtomatik tozalash siyosati bilan chegaralangan - cheksiz o'smaydi), Flutter
veb build ~20-50 MB. **Jami boshlang'ich og'irlik: 1 GB dan kam** - 187 GB
bo'sh joy oldida bu deyarli sezilmaydigan miqdor. Xavotir yo'q.

Video arxiv ham C: diskda joylashgan (alohida disk yo'q) - shuning uchun
kelajakda ikkalasi (HikCentral video arxivi + bizning ma'lumotlar) bir xil
diskni ulashadi. Tavsiya: disk bo'sh joyini oylik nazorat qilib turish.

## 3. RAM/CPU xavfsizligi - TASDIQLANDI XAVFSIZ

Haqiqiy HikCentral kompyuterida **15,7 GB RAM, 8 GB bo'sh (51%)**. Bizning
stack yengil (Python+PostgreSQL, video kodlash/striming qilmaydi) - odatda
200-400 MB RAM va past CPU talab qiladi oddiy yuklamada - 8 GB bo'sh joy
oldida bu ahamiyatsiz qo'shimcha yuklama. CPU'da eng og'ir jarayonlar
HikCentral'ning o'zi (media striming, BeeGuard, SYS) - bu kutilgan, video
kuzatuv tizimi uchun normal holat, bizning qo'shimchamizga bog'liq emas.

## 4. ROLLBACK REJASI - bosqichma-bosqich, har bosqichdan keyin tekshiruv bilan

O'rnatish HECH QACHON bir yo'la, "hammasini o'rnatib, oxirida tekshirish"
tarzida qilinmaydi. Har bir bosqichdan KEYIN HikCentral barcha xizmatlari
hali ham "Running" holatida ekanligi tasdiqlanadi (tekshiruv skriptining
5-7 bo'limlaridagi xizmatlar ro'yxati - bosqich boshida "boshlang'ich holat"
sifatida saqlanadi, har bosqichdan keyin shu ro'yxat bilan solishtiriladi).

**0-bosqich (o'rnatishdan OLDIN, bir marta):**
- Haqiqiy HikCentral kompyuterida System Protection ALLAQACHON yoqilgan va
  ishlamoqda - so'nggi 3 avtomatik checkpoint mavjud (2026-07-19, 2026-07-28,
  2026-08-06). Shunga qaramay, o'rnatishdan bevosita OLDIN yangi, aniq
  "bizning o'zgarishlardan oldingi" checkpoint qo'lda yaratiladi (pastdagi
  4-bandga qarang) - eng so'nggi avtomatik checkpoint bir necha kun oldin
  bo'lgani uchun.
- HikCentral barcha xizmatlarining "boshlang'ich holati"ni (Running/Stopped
  ro'yxati) faylga yozib olish - keyingi har bir bosqichda solishtirish uchun.

**1-bosqich: Python o'rnatish** → HikCentral xizmatlari holatini qayta
tekshirish (baseline bilan solishtirish).

**2-bosqich: PostgreSQL o'rnatish** - MAJBURIY: port **5544**da (HikCentral'ning
o'z Postgres'i 5432'da - 5544 undan aniq, chalkashmaydigan darajada uzoq),
alohida instance nomi bilan. Boshlashdan oldin 5544 bo'shligini quyidagi
buyruq bilan tasdiqlang:
```powershell
Get-NetTCPConnection -LocalPort 5544 -State Listen -ErrorAction SilentlyContinue
```
(Hech narsa chiqmasa - port bo'sh, xavfsiz davom etish mumkin.) → yana
holatni tekshirish.

**3-bosqich: repo joylashtirish + `.env` sozlash + backend/frontend'ni
QO'LDA (hali xizmat sifatida EMAS) ishga tushirib tekshirish** → yana
holatni tekshirish.

**4-bosqich: NSSM orqali Windows xizmati qilib o'rnatish** - aniq, boshqa
hech qanday Hik*/Bee* xizmati bilan bir xil bo'lmagan nom bilan (masalan
"HazoraspTaroziBackend") → yana holatni tekshirish.

**5-bosqich: Cloudflare Tunnel** (agar shu kompyuterda kerak bo'lsa) →
yana holatni tekshirish.

Har bir bosqichda: agar HikCentral xizmatlaridan BIRORTASI "Stopped"ga
aylangan bo'lsa - DARHOL to'xtash, faqat O'SHA BOSQICHDA qo'shilgan narsani
orqaga qaytarish (oldingi bosqichlarga tegmasdan), sababini aniqlab, keyin
davom etish haqida qaror qabul qilish.

## 5. ENG YOMON HOLAT (worst-case) rejasi

| Stsenariy | Javob |
|---|---|
| Bizning Postgres/backend HikCentral egallagan portga to'qnashib qoldi | Tekshiruv skripti buni OLDINDAN aniqlaydi (2-bo'lim to'liq port xaritasi). Agar shunga qaramay to'qnashsa - bizning tomonimiz to'liq configurable (`.env` DATABASE_URL porti, backend porti) - darhol boshqa portga o'tkaziladi. |
| O'rnatish paytida disk to'lib qoldi | 0-bosqichda kamida 20-30 GB bo'sh joy oldindan tasdiqlangan bo'ladi. Agar baribir yuz bersa - bizning yagona o'sadigan qismimiz (backup fayllari) 30 kunlik avtomatik tozalash siyosati bilan chegaralangan, darhol qo'lda ham tozalanishi/boshqa diskka ko'chirilishi mumkin - HikCentral'ga bog'liq emas. |
| HikCentral xizmati/kamera striming tasodifan to'xtab qoldi | Bosqichma-bosqich tekshiruv (4-band) buni DARHOL aniqlaydi - qaysi bosqichda yuz bergani aniq ma'lum bo'ladi. HECH QACHON avtomatik qayta ishga tushirishga urinilmaydi - avval sabab aniqlanadi, keyin HikCentral xizmati o'zining rasmiy boshqaruv vositasi orqali (Windows Services, "Running" holatiga) qaytariladi. |
| Windows umuman beqaror bo'lib qoldi / qayta yuklanishga majbur bo'ldi | 0-bosqichda yaratilgan System Restore checkpoint orqali BUTUN tizim (HikCentral ham, bizning qo'shganlarimiz ham) o'rnatishdan OLDINGI holatga qaytariladi - bu eng keng qamrovli, oxirgi chora. |
| Loyihadan butunlay voz kechish, HAMMA narsani zararsiz olib tashlash kerak | Pastdagi "To'liq olib tashlash" ro'yxatiga qarang. |

### To'liq, zararsiz olib tashlash (rollback) - checklist

Barchasi ANIQ NOM/YO'L bo'yicha, hech qachon keng qidiruv yoki wildcard bilan
EMAS:

1. NSSM xizmatlarini aniq nomi bilan to'xtatish va o'chirish
   (`nssm stop HazoraspTaroziBackend`, `nssm remove HazoraspTaroziBackend confirm`
   - va boshqa aniq o'rnatilgan xizmat nomlari uchun xuddi shunday).
2. PostgreSQL'ni Windows "Dasturlar va imkoniyatlar" orqali RASMIY
   uninstaller bilan olib tashlash (fayllarni qo'lda o'chirish EMAS - bu
   registry'da iz qoldiradi va keyingi o'rnatishlarga xalaqit berishi mumkin).
3. Python'ni xuddi shunday rasmiy uninstaller orqali olib tashlash.
4. Bizning repo papkasini (masalan `C:\hazorasp_tarozi`) butunlay o'chirish.
5. Bizning firewall qoidalarimizni (aniq nom bilan yaratilgan bo'lsa) o'chirish.
6. Yakuniy tasdiqlash: HikCentral barcha xizmatlari hali ham "Running", barcha
   asl portlari (2-bo'lim boshlang'ich ro'yxati bilan solishtirib) o'zgarishsiz.

Bu jarayon HikCentral'ga MUTLAQO tegmaydi - faqat bizning o'zimiz qo'shgan,
aniq nomlangan narsalarni olib tashlaydi.

## Keyingi qadam

Tekshiruv YAKUNLANDI - xulosa: **o'rnatish xavfsiz**. Endi navbat amalga
oshirish bosqichiga - lekin bu FAQAT sizning aniq tasdig'ingizdan keyin
boshlanadi. Amalga oshirish quyidagi tartibda bo'ladi (4-band, "ROLLBACK
REJASI"da tavsiflangan bosqichlar bo'yicha, har bosqichdan keyin HikCentral
holatini tekshirib):

0. Yangi System Restore checkpoint yaratish (buyruq yuqorida berilgan).
1. Python o'rnatish.
2. Port 5544 bo'shligini tasdiqlash, so'ng PostgreSQL'ni port **5544**da
   o'rnatish (5432 - HikCentral'niki, band).
3. Repo'ni joylashtirish, `.env` sozlash (`DATABASE_URL`da port 5544),
   qo'lda ishga tushirib tekshirish.
4. NSSM orqali Windows xizmati qilib o'rnatish.
5. Kerak bo'lsa, Cloudflare Tunnel.

Boshlashdan oldin: qaysi kunda/soatda amalga oshirish qulay (HikCentral
operatorlari band bo'lmagan payt tavsiya etiladi) va davom etishga
tasdiqingizni kutaman.
