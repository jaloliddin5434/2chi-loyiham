#requires -Version 5.1
<#
  backend_yangilash.ps1

  SERVER kompyuteri uchun (Flutter O'RNATILMAGAN) faqat-backend yangilash
  skripti. Ofis mashinasidagi to'liq `yangilash.ps1` frontend'ni ham
  build qiladi - serverda esa Flutter yo'q, shu sabab bu qisqartirilgan,
  backend-only variant.

  Ishlash tartibi:
    1) Oldindan tekshiruv: git repo, ishchi nusxa toza, HazoraspBackend
       xizmati o'rnatilgan
    2) git fetch + git pull --ff-only origin main  (xizmat hali ishlab turibdi)
    3) pip install -r requirements.txt              (xizmat hali ishlab turibdi)
    4) Alembic BOSHLANG'ICH holati tekshiruvi - `alembic_version` jadvali
       bormi? Yo'q bo'lsa: BIR MARTALIK qo'lda `alembic stamp` kerak
       (pastdagi izohga qarang) - skript to'xtaydi, kodni orqaga qaytaradi
    5) HazoraspBackend to'xtatiladi
    6) python -m alembic upgrade head
    7) HazoraspBackend ishga tushiriladi + 47001 porti ochilishini kutish
    8) GET /health -> {"status":"ok"} tekshiruvi
    9) 5-8 orasida xato bo'lsa: ORQAGA QAYTARISH
       (git reset --hard <eski> + xizmatni qayta ko'tarish + Telegram)

  NEGA 4-QADAM KERAK (MUHIM):
    main.py ishga tushganda `Base.metadata.create_all()` chaqiradi - bu
    YANGI JADVALLARNI avtomatik yaratadi, lekin mavjud jadvalga USTUN/
    INDEKS QO'SHMAYDI. Agar serverda `alembic upgrade head` hech qachon
    ishlamagan bo'lsa, `alembic_version` jadvali yo'q va migratsiya BOSHIDAN
    (base'dan) yugurishga urinadi - `qora_royxat_tokenlar` jadvali esa
    create_all() tomonidan ALLAQACHON yaratilgan bo'lgani uchun
    `53511474c2bd` migratsiyasi "relation already exists" xatosi bilan
    yiqiladi.

    Yechim - BIR MARTA, serverda qo'lda (backend papkasida):
        python -m alembic stamp head
    Bu hech qanday DDL bajarmaydi, faqat "joriy sxema head'ga teng" deb
    belgilaydi. Shundan keyin bu skript har safar faqat YANGI (bu
    nuqtadan keyingi) migratsiyalarni qo'llaydi.

    Eslatma: `alembic stamp head` `be4513d4facd` (2 ta indeks) va
    `800816102139` (mashinalar.davlat_raqami unique) o'zgarishlarini
    O'TKAZIB YUBORADI. Ular MOS KELMASLIGI (performance indeks / ilova
    darajasida allaqachon ushlangan unikallik) - kritik emas, keyin
    qo'lda qo'shsa bo'ladi:
        python -m alembic upgrade be4513d4facd  (agar indekslar yo'q bo'lsa)

  DIQQAT (yangilash.ps1 / frontend_yangilash.ps1 bilan bir xil qoida):
    bu faylda ATAYLAB emoji/lotin-bo'lmagan belgi TO'G'RIDAN-TO'G'RI
    yozilmaydi - Windows PowerShell 5.1 BOM'siz UTF-8 .ps1 faylidagi
    ko'p-baytli belgilarni tizim kodlashi bilan noto'g'ri o'qib, skriptni
    parse qila olmay qolishi mumkin. Kerakli belgilar runtime'da Unicode
    kod nuqtasidan yig'iladi.

  ISHGA TUSHIRISH (serverda, administrator PowerShell):
    powershell -ExecutionPolicy Bypass -File C:\hazorasp_tarozi\backend_yangilash.ps1
#>

[CmdletBinding()]
param(
    [string]$RepoRoot   = "C:\hazorasp_tarozi",
    [string]$XizmatNomi = "HazoraspBackend",
    [int]$Port          = 47001,
    [string]$Branch     = "main"
)

$ErrorActionPreference = "Stop"

$BackendDir = Join-Path $RepoRoot "backend"
$LogFayl    = Join-Path $RepoRoot "backend_yangilash.log"
$BaseUrl    = "http://127.0.0.1:$Port"

$QizilDoira  = [char]::ConvertFromUtf32(0x1F534)
$YashilBelgi = [char]::ConvertFromUtf32(0x2705)

function Log($matn) {
    $q = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $matn
    Write-Host $q
    try { Add-Content -Path $LogFayl -Value $q -Encoding UTF8 } catch { }
}

# Tashqi buyruqni (git/pip/alembic) xavfsiz bajaradi: buyruq TOPILMASA
# PowerShell to'xtatuvchi xato otadi (oddiy $LASTEXITCODE tekshiruvi bunga
# yetib bormaydi) - shu sabab try/catch ichida, ikkala xato turi ham bir
# xil $false natijaga olib keladi (yangilash.ps1'dagi real sinov darsi).
function Buyruq-Ok([scriptblock]$Buyruq) {
    try {
        & $Buyruq
        return ($LASTEXITCODE -eq 0)
    } catch {
        Log "Buyruq bajarilmadi: $_"
        return $false
    }
}

function Telegram-Xabar($matn) {
    try {
        $envQatorlar = Get-Content (Join-Path $BackendDir ".env") -Encoding UTF8
        $token  = ($envQatorlar | Where-Object { $_ -match "^TELEGRAM_TOKEN=" })   -replace "^TELEGRAM_TOKEN=", ""
        $chatId = ($envQatorlar | Where-Object { $_ -match "^TELEGRAM_CHAT_ID=" }) -replace "^TELEGRAM_CHAT_ID=", ""
        if ($token -and $chatId) {
            Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/sendMessage" -Method Post -Body @{
                chat_id    = $chatId
                text       = $matn
                parse_mode = "HTML"
            } -TimeoutSec 10 | Out-Null
        }
    } catch {
        Log "OGOHLANTIRISH: Telegram xabar yuborilmadi: $_"
    }
}

function Xizmatni-Toxtatish {
    try {
        $x = Get-Service -Name $XizmatNomi -ErrorAction Stop
        if ($x.Status -ne "Stopped") {
            Log "$XizmatNomi to'xtatilmoqda..."
            Stop-Service -Name $XizmatNomi -Force -ErrorAction Stop
            (Get-Service -Name $XizmatNomi).WaitForStatus("Stopped", (New-TimeSpan -Seconds 30))
        }
    } catch {
        Log "OGOHLANTIRISH: $XizmatNomi to'xtatishda xato: $_"
    }
    Start-Sleep -Seconds 2
}

function Xizmatni-Ishga-Tushirish {
    try {
        Log "$XizmatNomi ishga tushirilmoqda..."
        Start-Service -Name $XizmatNomi -ErrorAction Stop
    } catch {
        Log "XATOLIK: $XizmatNomi ishga tushirishda xato: $_"
    }
    $ochildi = $false
    for ($i = 0; $i -lt 20 -and -not $ochildi; $i++) {
        Start-Sleep -Seconds 2
        $ochildi = [bool](Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
            Select-Object -First 1)
    }
    Log "Port $Port ochildi: $ochildi"
    return $ochildi
}

function Soglik-Tekshir {
    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Seconds 2
        try {
            $j = Invoke-RestMethod -Uri "$BaseUrl/health" -TimeoutSec 5
            if ($j.status -eq "ok") { return $true }
        } catch { }
    }
    return $false
}

function Orqaga-Qaytarish($eskiCommit) {
    Log "===== ORQAGA QAYTARISH BOSHLANDI ($eskiCommit) ====="
    Xizmatni-Toxtatish
    try {
        Set-Location $RepoRoot
        git reset --hard $eskiCommit | Out-Null
        Log "Kod eski holatga qaytarildi: $eskiCommit"
    } catch {
        Log "OGOHLANTIRISH: git reset xato: $_ - baribir xizmat ishga tushiriladi."
    }
    # Migratsiya SXEMASI ataylab orqaga qaytarilmaydi - loyihadagi barcha
    # migratsiyalar faqat qo'shimcha (yangi ustun/jadval/indeks), eski kod
    # ularga tegmasdan ishlayveradi (yangilash.ps1'dagi bir xil qaror).
    $ishladi = $false
    try { $ishladi = Xizmatni-Ishga-Tushirish } catch { Log "OGOHLANTIRISH: ishga tushirishda xato: $_" }
    $sog = $false
    try { $sog = Soglik-Tekshir } catch { }
    if ($ishladi -and $sog) {
        Log "Orqaga qaytarish MUVAFFAQIYATLI - eski versiya ($eskiCommit) qayta ishlamoqda."
        Telegram-Xabar "$QizilDoira <b>Backend yangilanishi MUVAFFAQIYATSIZ - avtomatik orqaga qaytarildi.</b>`nEski versiya ($eskiCommit) tiklandi. Sabab: backend_yangilash.log"
    } else {
        Log "JIDDIY: orqaga qaytarishdan keyin ham /health javob bermayapti - QO'LDA ARALASHUV KERAK!"
        Telegram-Xabar "$QizilDoira$QizilDoira <b>JIDDIY: Backend yangilanishi MUVAFFAQIYATSIZ va orqaga qaytarish ham yordam bermadi!</b>`nDARHOL serverni tekshiring (backend_yangilash.log)."
    }
}

# ============================ ASOSIY OQIM ============================
Log "===== BACKEND YANGILASH BOSHLANDI ====="

# 1) Oldindan tekshiruv
if (-not (Test-Path (Join-Path $RepoRoot ".git"))) {
    Log "XATOLIK: $RepoRoot git repositoriyasi emas."
    exit 1
}
if (-not (Get-Service -Name $XizmatNomi -ErrorAction SilentlyContinue)) {
    Log "XATOLIK: '$XizmatNomi' Windows xizmati topilmadi - avval backend\install_service.bat bilan o'rnating."
    exit 1
}
Set-Location $RepoRoot
if (git status --porcelain) {
    Log "XATOLIK: saqlanmagan lokal o'zgarishlar bor - avval 'git status' bilan hal qiling. Yangilash BOSHLANMADI."
    exit 1
}
$eskiCommit = (git rev-parse HEAD).Trim()
Log "Joriy versiya: $eskiCommit"

# 2) git pull (xizmat hali eski kod bilan ishlab turibdi)
Log "--- git fetch + pull --ff-only origin $Branch ---"
if (-not (Buyruq-Ok { git fetch origin })) {
    Log "XATOLIK: git fetch muvaffaqiyatsiz (tarmoq). Hech narsaga tegilmadi."
    exit 1
}
if (-not (Buyruq-Ok { git pull --ff-only origin $Branch })) {
    Log "XATOLIK: git pull muvaffaqiyatsiz (fast-forward emas yoki tarmoq). Hech narsaga tegilmadi."
    exit 1
}
$yangiCommit = (git rev-parse HEAD).Trim()
if ($yangiCommit -eq $eskiCommit) {
    Log "Yangilanish yo'q - allaqachon eng so'nggi versiyada ($eskiCommit). Chiqilmoqda."
    exit 0
}
Log "Yangi versiya olindi: $yangiCommit"

# 3) Backend bog'liqliklari
Log "--- pip install -r requirements.txt ---"
Set-Location $BackendDir
if (-not (Buyruq-Ok { python -m pip install -r requirements.txt })) {
    Log "XATOLIK: pip install muvaffaqiyatsiz. Kod eski holatga qaytarilmoqda (xizmatga tegilmadi)."
    Set-Location $RepoRoot
    try { git reset --hard $eskiCommit | Out-Null } catch { Log "OGOHLANTIRISH: git reset xato: $_" }
    exit 1
}

# 4) Alembic BOSHLANG'ICH holati - `alembic_version` jadvali bormi?
#    (yuqoridagi "NEGA 4-QADAM KERAK" izohiga qarang)
Log "--- Alembic boshlang'ich holati tekshirilmoqda ---"
$alembicBaza = @'
import sqlalchemy as sa
from config import DATABASE_URL
e = sa.create_engine(DATABASE_URL)
with e.connect() as c:
    if not sa.inspect(e).has_table("alembic_version"):
        raise SystemExit(3)
    n = c.execute(sa.text("select count(*) from alembic_version")).scalar()
    raise SystemExit(0 if n else 3)
'@
$bazaOk = Buyruq-Ok { $alembicBaza | python - }
if (-not $bazaOk) {
    Log "======================================================================"
    Log "  TO'XTATILDI: serverda 'alembic_version' jadvali yo'q (yoki bo'sh)."
    Log "  Migratsiyani BOSHIDAN yugurtirsa, create_all() allaqachon yaratgan"
    Log "  jadvallar bilan to'qnashadi ('relation already exists')."
    Log ""
    Log "  BIR MARTA, shu (backend) papkada qo'lda bajaring:"
    Log "      python -m alembic stamp head"
    Log "  Bu hech qanday jadval/ustun o'zgartirmaydi - faqat 'joriy sxema"
    Log "  head'ga teng' deb belgilaydi. Keyin bu skriptni qayta ishga tushiring."
    Log "======================================================================"
    Set-Location $RepoRoot
    try { git reset --hard $eskiCommit | Out-Null } catch { Log "OGOHLANTIRISH: git reset xato: $_" }
    Log "Kod eski holatga qaytarildi ($eskiCommit) - bir martalik 'stamp'dan keyin qayta urinib ko'ring."
    exit 1
}
Log "Alembic boshlang'ich holati OK - upgrade qilinadi."

# 5) Xizmatni to'xtatish - SHU YERDAN boshlab to'xtash vaqti
Log "--- $XizmatNomi to'xtatilmoqda ---"
Xizmatni-Toxtatish

# 6) Migratsiya
Log "--- python -m alembic upgrade head ---"
Set-Location $BackendDir
$migratsiyaOk = Buyruq-Ok { python -m alembic upgrade head }
Set-Location $RepoRoot
if (-not $migratsiyaOk) {
    Log "XATOLIK: migratsiya muvaffaqiyatsiz!"
    Orqaga-Qaytarish $eskiCommit
    exit 1
}
Log "Migratsiya muvaffaqiyatli."

# 7) Xizmatni qayta ishga tushirish
Log "--- $XizmatNomi qayta ishga tushirilmoqda ---"
$ishladi = $false
try { $ishladi = Xizmatni-Ishga-Tushirish } catch { Log "XATOLIK: kutilmagan xato: $_" }
if (-not $ishladi) {
    Log "XATOLIK: $XizmatNomi porti ($Port) kutilgan vaqtda ochilmadi!"
    Orqaga-Qaytarish $eskiCommit
    exit 1
}

# 8) Sog'lomlikni tekshirish
Start-Sleep -Seconds 3
$sog = $false
try { $sog = Soglik-Tekshir } catch { }
if (-not $sog) {
    Log "XATOLIK: yangi versiya ishga tushdi-yu, lekin /health javob bermayapti!"
    Orqaga-Qaytarish $eskiCommit
    exit 1
}

Log "===== BACKEND YANGILANISHI MUVAFFAQIYATLI: $eskiCommit -> $yangiCommit ====="
Telegram-Xabar "$YashilBelgi <b>Backend muvaffaqiyatli yangilandi (server).</b>`n$eskiCommit -> $yangiCommit"
exit 0
