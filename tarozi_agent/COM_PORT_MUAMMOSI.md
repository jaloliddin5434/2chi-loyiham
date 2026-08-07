# Tarozi COM portini topolmayapti — nima qilish kerak

Operator ekranida tarozi doimiy "Uzilgan" ko'rsatsa, va boshqa hamma narsa
(internet, server, Cloudflare Tunnel) ishlab tursa — sabab odatda shu: tarozi
kompyuterga ulangan COM port raqami `.env` faylidagi `TAROZI_PORT`
qiymatidan farq qilib qolgan.

Bu ko'pincha quyidagi holatlarda yuz beradi:
- Tarozi kabeli (USB-RS232 pereхodnik) boshqa USB portga ulanganda.
- Windows yangilanishidan keyin.
- Pereхodnikni almashtirilganda (yangi qurilma = yangi COM raqami).

**Muhim:** agent COM portni **avtomatik qidirmaydi** — u faqat `.env`da
yozilgan raqamni sinab ko'radi. Agar bu raqam noto'g'ri bo'lsa, agent har 3
soniyada bir marta xuddi shu (noto'g'ri) portni qayta-qayta sinab, abadiy
muvaffaqiyatsiz bo'laveradi — o'zi to'xtamaydi, lekin o'zi ham tuzalmaydi.

## Tekshirish qadamlari

### 1. Haqiqiy COM raqamini aniqlash

Windows'da **Device Manager** (Qurilmalar boshqaruvchisi) oching:
- `Win + X` → "Device Manager" tanlang.
- **"Ports (COM & LPT)"** bo'limini oching.
- Tarozi ulangan pereхodnik shu yerda ko'rinishi kerak, masalan:
  `USB-SERIAL CH340 (COM9)` — qavs ichidagi raqam haqiqiy COM nomer.

Agar u yerda umuman ko'rinmasa — kabel/pereхodnik jismonan ulanmagan yoki
drayver o'rnatilmagan degani (COM raqami muammosi emas, bu boshqa muammo).

### 2. `.env` faylini yangilash

`tarozi_agent\.env` faylini oching (Notepad bilan yetarli), `TAROZI_PORT`
qatorini yangi raqamga almashtiring:

```
TAROZI_PORT=COM9
```

(faqat raqamning o'zi o'zgaradi, boshqa qatorlarga tegilmaydi)

### 3. Xizmatni qayta ishga tushirish

`.env` o'zgarishi darhol kuchga kirmaydi — agent process qayta boshlanishi
kerak (chunki `.env` faqat ishga tushishda o'qiladi):

PowerShell'da (Administrator sifatida):
```powershell
Restart-Service TaroziAgent
```

Yoki oddiy `services.msc` orqali: "Hazorasp Tarozi Agenti" xizmatini toping,
o'ng tugma → **Restart**.

### 4. Tekshirish

- `tarozi_agent\agent_stdout.log` faylini oching — oxirgi qatorda
  `"Tarozi (COM9) bilan aloqa o'rnatildi."` ko'rinishi kerak (xatosiz).
- Operator ekranida tarozi holati "Uzilgan"dan "Barqaror"/"Harakatda"ga
  o'tishi kerak (bir necha soniya ichida).

## Agar Device Manager'da hech qanday COM port ko'rinmasa

Bu COM-raqam muammosi emas — ehtimoliy sabablar:
- Kabel jismonan uzilgan yoki noto'g'ri ulangan.
- USB-RS232 pereхodnik drayveri o'rnatilmagan (ayniqsa CH340 chipli arzon
  pereхodniklarda tez-tez uchraydi — ishlab chiqaruvchi saytidan drayver
  yuklab olish kerak).
- Pereхodnikning o'zi ishdan chiqqan.

Bunday holatda tafsilotliroq diagnostika kerak bo'lsa, loyiha tub
papkasidagi (`tarozi_agent\` papkasidan bir daraja yuqorida)
`tarozi_diag_full.py` skripti yordam berishi mumkin (barcha ko'rinayotgan
COM portlarni ro'yxatlaydi va ularni sinab ko'radi):

```
cd ..
python tarozi_diag_full.py
```
