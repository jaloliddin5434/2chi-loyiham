# TAROZI_AGENT_KEY'ni almashtirish (rotatsiya)

`TAROZI_AGENT_KEY` — tarozixona kompyuteridagi Tarozi agenti bilan ofisdagi
serverni bir-biriga tanitadigan **umumiy sir** (statik kalit). Agent har
`POST /tarozi/yubor` so'rovida uni `X-Tarozi-Agent-Key` sarlavhasida
yuboradi; server esa o'zining `backend/.env`dagi qiymati bilan solishtiradi
— mos kelmasa so'rovni 401 bilan rad etadi.

**Muhim cheklov:** tizim bir vaqtning o'zida faqat **BITTA** kalitni to'g'ri
deb biladi (eski va yangi kalitni parallel qabul qilish imkoniyati yo'q).
Shu sabab rotatsiya paytida **qisqa (bir necha soniyalik) uzilish** kutilgan
holat — bu xato emas, pastdagi qadamlarni to'g'ri tartibda bajarsangiz,
tarozi ko'rsatkichi bir necha soniyada o'zi tiklanadi (server 10 soniyalik
"jimlik" oralig'idan keyingina "Uzilgan" deb ko'rsatadi).

## Qachon almashtirish kerak

- Kalit qandaydir tarzda oshkor bo'lgan deb gumon qilinsa (masalan noto'g'ri
  joyga yuborilgan, ekranga tasodifan chiqib qolgan va h.k.).
- Davriy xavfsizlik amaliyoti sifatida (masalan yiliga bir marta).
- Tarozixona kompyuteri almashtirilganda/qayta o'rnatilganda (ixtiyoriy,
  lekin yaxshi imkoniyat).

## Qadamlar

### 1. Yangi kalit generatsiya qilish

Har qanday kompyuterda (Python o'rnatilgan bo'lsa yetarli):

```
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

Natija — 43 ta belgidan iborat tasodifiy matn, masalan:
`yIzpH7SIjswQNTtadJRRPUKrZWlKiDWbvZ8ms9zt4iw`

Bu qiymatni vaqtincha xavfsiz joyga (masalan parol menejeriga) yozib qo'ying
— keyingi ikkala qadamda ham AYNAN shu qiymat kerak bo'ladi.

### 2. Ikkala `.env` faylini yangilash

**Ofis serverida** — `backend\.env`:
```
TAROZI_AGENT_KEY=<yangi_kalit>
```

**Tarozixona kompyuterida** — `tarozi_agent\.env`:
```
TAROZI_AGENT_KEY=<yangi_kalit>
```

Ikkalasida ham **aynan bir xil** qiymat bo'lishi shart — bittasida xato
bo'lsa, agent 401 bilan rad etilaveradi.

### 3. Ikkala tomonni qayta ishga tushirish

`.env` o'zgarishi darhol kuchga kirmaydi — process qayta boshlanishi kerak.

**Ofis serverida** (backend'ni qayta ishga tushirish — qanday qilib
ishga tushirilgan bo'lsa, o'sha usulda: `start.bat` orqali qayta yoki
xizmat sifatida o'rnatilgan bo'lsa xizmatni restart qilish).

**Tarozixona kompyuterida:**
```powershell
Restart-Service TaroziAgent
```
(yoki `services.msc` orqali "Hazorasp Tarozi Agenti" xizmatini qo'lda
qayta ishga tushirish)

**Tavsiya etilgan tartib:** avval serverni, keyin agentni qayta ishga
tushiring — shunda agent birinchi urinishdayoq yangi kalit bilan
muvaffaqiyatli ulanadi (aksincha tartibda ham ishlayveradi, faqat agent
server yangilanguncha bir necha soniya 401 olib turadi — zararsiz, chunki
u avtomatik qayta urinishda davom etadi).

### 4. Tekshirish

- `tarozi_agent\agent_stdout.log`da endi `"TAROZI_AGENT_KEY mos
  kelmayapti (401)"` xabari qayta chiqmasligi kerak.
- Operator ekranida tarozi holati bir necha soniya ichida "Barqaror"/
  "Harakatda"ga qaytishi kerak.
- Ofis serverining log faylida `POST /tarozi/yubor` so'rovlari `200 OK`
  bilan davom etayotganini ko'rish mumkin (401 emas).

## Diqqat — xavfsizlik

- Yangi kalitni hech qachon Git'ga (yoki boshqa versiyalash tizimiga)
  committ qilmang — `.env` fayllari `.gitignore`da, shunday qolishi kerak.
- Eski kalitni biror joyda (masalan shu hujjatda, chat tarixida) qoldirmang
  — rotatsiyadan keyin eski qiymat butunlay unutilishi kerak.
