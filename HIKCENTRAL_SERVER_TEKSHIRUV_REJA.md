# HikCentral kompyuteriga server ko'chirish - tekshiruv va xavfsizlik rejasi

Bu hujjat - ofisdagi (hali alohida tekshirilmagan) HikCentral kompyuteriga
bizning backend+frontend+PostgreSQL stack'ini o'rnatishdan OLDINGI tayyorgarlik
rejasi. Hech qanday o'rnatish/o'zgartirish HALI amalga oshirilmagan - bu FAQAT
reja va tekshiruv skripti.

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
  (5433 yoki undan yuqori) o'rnatilishi SHART.
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
4. Bizga kerak bo'lishi mumkin bo'lgan portlar (8001, 8080, 5432, 5433, 5000,
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

## 2. Xavfsiz disk joyi hisobi

Bizning REAL o'lchangan og'irligimiz (shu dev-kompyuterdagi mavjud
o'rnatishdan): repo manba kodi ~15-20 MB, PostgreSQL data papkasi hozircha
~78 MB (biznes ma'lumoti bilan sekin o'sadi), backup fayllari ~6 MB (30 kunlik
avtomatik tozalash siyosati bilan chegaralangan - cheksiz o'smaydi), Flutter
veb build ~20-50 MB. **Jami boshlang'ich og'irlik: 1 GB dan kam.**

Shunga qaramay, tavsiya: o'rnatishdan oldin diskda **kamida 20-30 GB bo'sh
joy** borligini tasdiqlang (xavfsizlik marjasi sifatida, HikCentral'ning
o'zi ham vaqt o'tishi bilan ko'proq joy talab qilishi mumkinligi uchun).
Agar HikCentral video arxivi alohida diskda bo'lsa (odatiy amaliyot), bizning
stack'ni o'sha diskka EMAS, tizim diskiga (yoki eng ko'p bo'sh joyi bor
diskka) o'rnatish tavsiya etiladi.

## 3. RAM/CPU xavfsizligi

Bizning stack yengil (Python+PostgreSQL, video kodlash/striming qilmaydi) -
odatda 200-400 MB RAM va past CPU talab qiladi oddiy yuklamada. Lekin
tekshiruv skriptining 10-11 bo'limlari orqali HikCentral kompyuterining
UMUMIY bo'sh RAM/CPU zaxirasini albatta ko'rib chiqish kerak - agar bo'sh RAM
1-2 GB dan kam bo'lsa (shu kalibrlash kompyuterida bo'lgani kabi), bu allaqachon
tor holat va bizning qo'shimchamiz uni yanada torlashtiradi - bunday holatda
o'rnatishdan oldin HikCentral operatoriga/administratoriga xabar berish va
RAM yetarliligini alohida muhokama qilish tavsiya etiladi.

## 4. ROLLBACK REJASI - bosqichma-bosqich, har bosqichdan keyin tekshiruv bilan

O'rnatish HECH QACHON bir yo'la, "hammasini o'rnatib, oxirida tekshirish"
tarzida qilinmaydi. Har bir bosqichdan KEYIN HikCentral barcha xizmatlari
hali ham "Running" holatida ekanligi tasdiqlanadi (tekshiruv skriptining
5-7 bo'limlaridagi xizmatlar ro'yxati - bosqich boshida "boshlang'ich holat"
sifatida saqlanadi, har bosqichdan keyin shu ro'yxat bilan solishtiriladi).

**0-bosqich (o'rnatishdan OLDIN, bir marta):**
- Windows System Restore uchun "System Protection" C: diskda YOQILGANLIGINI
  tasdiqlash (shu kalibrlash kompyuterida bu O'CHIRILGAN edi - hech qanday
  restore point yo'q edi - bu ALBATTA tuzatilishi kerak bo'lgan holat).
- Yangi restore point yaratish (`Checkpoint-Computer` yoki Boshqaruv paneli
  orqali) - bu YAGONA to'liq, OS-darajasidagi orqaga qaytarish tarmog'i.
- HikCentral barcha xizmatlarining "boshlang'ich holati"ni (Running/Stopped
  ro'yxati) faylga yozib olish - keyingi har bir bosqichda solishtirish uchun.

**1-bosqich: Python o'rnatish** → HikCentral xizmatlari holatini qayta
tekshirish (baseline bilan solishtirish).

**2-bosqich: PostgreSQL o'rnatish** - MAJBURIY: HikCentral'ning o'z Postgres
portidan (odatda 5432) FARQLI portda (5433 yoki undan yuqori, tekshiruv
skripti asosida band bo'lmagan port tanlanadi), alohida instance nomi bilan
→ yana holatni tekshirish.

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

Tekshiruv skriptini (`hikcentral_tekshiruv.ps1`) haqiqiy HikCentral
kompyuterida ishga tushirish va natijani (`%TEMP%\hikcentral_tekshiruv_natija_*.txt`)
yuborish kerak. Shundan keyin - real ma'lumotlar asosida - yuqoridagi reja
aniq raqamlar (tanlangan Postgres porti, disk, o'rnatish yo'li) bilan
to'ldiriladi va faqat SIZNING tasdig'ingizdan keyin amalga oshirish
bosqichiga o'tiladi.
