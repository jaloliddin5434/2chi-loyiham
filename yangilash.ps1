#requires -Version 5.1
# Hazorasp Tekstil Tarozi Tizimi - avtomatik yangilash skripti.
#
# Ishlash tartibi (batafsil reja avval REJA sifatida tasdiqlangan):
#   1) Oldindan tekshiruv (git holati toza, git repo ekanligi)
#   2) Zaxira (haqiqiy DB backup /backup orqali + frontend build nusxasi) -
#      HALI HECH NARSAGA TEGILMAGAN, xizmatlar ishlab turibdi
#   3) git pull --ff-only origin main - xizmatlar hali ishlab turibdi
#   4) pip install -r requirements.txt - xizmatlar hali ishlab turibdi
#   5) pytest (backend) - xizmatlar hali ishlab turibdi
#   6) Foydalanuvchidan tasdiq (H/Y = Ha, boshqa har narsa = Yo'q)
#   7) Xizmatlarni to'xtatish - SHU YERDAN BOSHLAB to'xtash vaqti
#   8) alembic upgrade head
#   9) flutter build web --release
#   10) Xizmatlarni qayta ishga tushirish (start.bat orqali - bir xil
#       mexanizm, ikki joyda takrorlanmasin)
#   11) GET /health orqali sog'lomlikni tekshirish
#
# 6-11 orasidagi ISTALGAN qadamda xato chiqsa - Orqaga-Qaytarish
# chaqiriladi: git reset --hard <eski-commit> + frontend build zaxirasi
# tiklanadi + xizmatlar ESKI kod bilan qayta ishga tushiriladi + Telegram
# orqali ogohlantirish yuboriladi. Migratsiya SXEMASI ataylab orqaga
# QAYTARILMAYDI - loyihadagi barcha migratsiyalar hozirgacha faqat
# QO'SHIMCHA (yangi ustun/jadval), shu sabab eski kod ularga tegmasdan
# ishlayveradi; downgrade skriptlariga ishonch darajasi kodni reset
# qilishga qaraganda pastroq.
#
# MA'LUM CHEKLOV (real sinovda topilgan): orqaga qaytarishda KOD va
# XIZMATLAR har doim tiklanadi va sog'lomligi tasdiqlanadi (bu - asosiy
# xavfsizlik kafolati). Lekin frontend build/web papkasini zaxiradan
# ALMASHTIRISH bosqichi ba'zan (disk/antivirus band bo'lganda) fayl
# tutqichi hali bo'shamagani sabab muvaffaqiyatsiz bo'lishi mumkin - bu
# holatda log'da aniq OGOHLANTIRISH yoziladi va zaxira nusxa
# (web_zaxira_*) YONIDA qoldiriladi, xizmatlar esa BARIBIR ishga
# tushiriladi (garchi frontend eski emas, joriy build bilan). Bunday
# holatda kerak bo'lsa web_zaxira_* papkasini qo'lda build/web'ga
# nusxalash kifoya.

$ErrorActionPreference = "Stop"

$RepoRoot = "C:\hazorasp_tarozi"
$BackendDir = "$RepoRoot\backend"
$FrontendDir = "$RepoRoot\frontend"
$LogFile = "$RepoRoot\yangilash_tarixi.log"
$BaseUrl = "http://127.0.0.1:47001"
$WebDir = "$FrontendDir\build\web"

# DIQQAT: bu faylda ATAYLAB hech qanday emoji/lotin-bo'lmagan belgi
# to'g'ridan-to'g'ri yozilmaydi - Windows PowerShell 5.1, BOM'siz UTF-8
# .ps1 faylini o'qiganda, shu kabi ko'p-baytli belgilarni tizim
# kodalash usuli (masalan cp1251) bilan noto'g'ri talqin qilib, skriptning
# O'ZINI parse qila olmay qoladi (xuddi shu turdagi xato avval
# tarozi_agent.py'da - Telegram xabaridagi emoji konsolga chiqishda -
# topilgan edi, bu yerda esa fayl PARSE bosqichida yuz beradi). Shu
# sabab kerakli belgilar quyida Unicode kod nuqtasidan runtime'da
# yig'iladi - fayl matni har doim toza ASCII bo'lib qoladi.
$QizilDoira = [char]::ConvertFromUtf32(0x1F534)
$YashilBelgi = [char]::ConvertFromUtf32(0x2705)

function Log($matn) {
    $vaqt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $qator = "[$vaqt] $matn"
    Write-Host $qator
    Add-Content -Path $LogFile -Value $qator -Encoding UTF8
}

# Tashqi buyruqni (pip/pytest/git/alembic/flutter) xavfsiz bajaradi va
# muvaffaqiyat/muvaffaqiyatsizlikni BIR XIL, ishonchli tarzda qaytaradi.
#
# MUHIM (real sinovda topilgan haqiqiy xato): buyruq TOPILMASA (masalan
# PATH'dan yo'qolgan bo'lsa) PowerShell buni har doim TO'XTATUVCHI
# (terminating) xato sifatida otadi - oddiy "$LASTEXITCODE -ne 0"
# tekshiruvi bu holatga UMUMAN YETIB BORMAYDI, alembic.exe vaqtincha
# yo'q qilingan real sinovda skriptning o'zi to'xtab qolgan va xizmatlar
# ISHGA TUSHIRILMAY qolib ketgan edi (orqaga qaytarish chaqirilmagan).
# Shu sabab HAR bir tashqi buyruq ATAYLAB shu funksiya orqali, try/catch
# ichida chaqiriladi - ikkala xato turi (yomon exit-kod HAM, chaqirishning
# o'zi otilgan xato HAM) bir xil "$false" natijaga olib keladi.
function Buyruq-Muvaffaqiyatlimi([scriptblock]$Buyruq) {
    try {
        & $Buyruq
        return ($LASTEXITCODE -eq 0)
    } catch {
        Log "Buyruq bajarilmadi: $_"
        return $false
    }
}

function Telegram-Xabar($matn) {
    # Mavjud "asosiy" (ogohlantirish) bot - tunnel/tarozi/kamera
    # xabarlari bilan bir xil kanal, chunki bu ham operatsion hodisa.
    try {
        $envQatorlar = Get-Content "$BackendDir\.env" -Encoding UTF8
        $token = ($envQatorlar | Where-Object { $_ -match "^TELEGRAM_TOKEN=" }) -replace "^TELEGRAM_TOKEN=", ""
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

function Xizmat-Portini-Topish($port) {
    return (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty OwningProcess)
}

function Xizmatlarni-Toxtatish {
    $backendPid = Xizmat-Portini-Topish 47001
    $frontendPid = Xizmat-Portini-Topish 47080
    if ($backendPid) {
        Log "Backend jarayoni to'xtatilmoqda (PID $backendPid)..."
        Stop-Process -Id $backendPid -Force -ErrorAction SilentlyContinue
    }
    if ($frontendPid) {
        Log "Frontend jarayoni to'xtatilmoqda (PID $frontendPid)..."
        Stop-Process -Id $frontendPid -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 2
}

function Xizmatlarni-Ishga-Tushirish {
    # Aynan start.bat orqali - qo'lda ishga tushirishdagi bilan bir xil
    # mexanizm, ikki joyda (bu yerda va start.bat'da) takrorlanmasin.
    Log "Xizmatlar ishga tushirilmoqda (start.bat)..."
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$RepoRoot\start.bat`"" -WindowStyle Minimized | Out-Null

    $urinish = 0
    $backendOchildi = $false
    $frontendOchildi = $false
    while ($urinish -lt 20 -and (-not ($backendOchildi -and $frontendOchildi))) {
        Start-Sleep -Seconds 2
        if (-not $backendOchildi) { $backendOchildi = [bool](Xizmat-Portini-Topish 47001) }
        if (-not $frontendOchildi) { $frontendOchildi = [bool](Xizmat-Portini-Topish 47080) }
        $urinish++
    }
    Log "Portlar holati: backend(47001)=$backendOchildi, frontend(47080)=$frontendOchildi"
    return ($backendOchildi -and $frontendOchildi)
}

function Sogliqni-Tekshirish {
    try {
        $javob = Invoke-RestMethod -Uri "$BaseUrl/health" -TimeoutSec 5
        return ($javob.status -eq "ok")
    } catch {
        return $false
    }
}

function Orqaga-Qaytarish($eskiCommit, $webZaxiraYoli) {
    # DIQQAT: bu funksiya "so'nggi chora" - shu sabab HAR bir ichki qadam
    # o'z alohida try/catch'iga ega: kodni/build'ni tiklash muvaffaqiyatsiz
    # bo'lsa ham, xizmatlarni ISHGA TUSHIRISHGA baribir urinilishi kerak
    # (mavjud, garchi to'liq tiklanmagan holatda ishlash - umuman
    # ishlamaslikdan afzal).
    Log "===== ORQAGA QAYTARISH BOSHLANDI ($eskiCommit) ====="
    Xizmatlarni-Toxtatish

    try {
        Set-Location $RepoRoot
        git reset --hard $eskiCommit | Out-Null
        if ($webZaxiraYoli -and (Test-Path $webZaxiraYoli)) {
            # Xizmatlarni-Toxtatish endigina chaqirilgan bo'lsa-da, Windows
            # ba'zan fayl tutqichlarini (file handle) DARHOL bo'shatmaydi -
            # real sinovda aynan shu sabab Remove-Item "fayl boshqa jarayon
            # tomonidan ishlatilmoqda" xatosi bilan bir marta muvaffaqiyatsiz
            # bo'lgan edi. Shu sabab bir necha marta, orada kutib qayta
            # urinib ko'riladi.
            $tozalandi = $false
            for ($i = 0; $i -lt 10 -and -not $tozalandi; $i++) {
                try {
                    if (Test-Path $WebDir) { Remove-Item -Recurse -Force $WebDir -ErrorAction Stop }
                    $tozalandi = $true
                } catch {
                    Start-Sleep -Seconds 3
                }
            }
            if (-not $tozalandi -and (Test-Path $WebDir)) {
                Log "OGOHLANTIRISH: eski build/web papkasi band bo'lgani uchun tozalanmadi - zaxira NUSXA sifatida yonida qoldiriladi, qo'lda almashtirish kerak bo'lishi mumkin: $webZaxiraYoli"
            } else {
                Copy-Item -Recurse $webZaxiraYoli $WebDir
                Log "Frontend build zaxiradan tiklandi: $webZaxiraYoli"
            }
        }
    } catch {
        Log "OGOHLANTIRISH: kod/build tiklashda xato: $_ - baribir xizmatlarni ishga tushirishga urinilmoqda."
    }

    $ishga_tushdi = $false
    try {
        $ishga_tushdi = Xizmatlarni-Ishga-Tushirish
    } catch {
        Log "OGOHLANTIRISH: xizmatlarni ishga tushirishda xato: $_"
    }
    Start-Sleep -Seconds 2

    $sogPmi = $false
    try { $sogPmi = Sogliqni-Tekshirish } catch { }

    if ($ishga_tushdi -and $sogPmi) {
        Log "Orqaga qaytarish MUVAFFAQIYATLI - eski versiya ($eskiCommit) qayta ishlamoqda."
        Telegram-Xabar "$QizilDoira <b>Yangilanish MUVAFFAQIYATSIZ - avtomatik orqaga qaytarildi.</b>`nEski, ishlaydigan versiya ($eskiCommit) qayta tiklandi. Sabab uchun: yangilash_tarixi.log"
    } else {
        Log "JIDDIY OGOHLANTIRISH: orqaga qaytarishdan keyin ham xizmat sog'lom emas - QO'LDA ARALASHUV KERAK!"
        Telegram-Xabar "$QizilDoira$QizilDoira <b>JIDDIY: Yangilanish MUVAFFAQIYATSIZ va orqaga qaytarish ham to'liq yordam bermadi!</b>`nDARHOL kompyuterni tekshiring (yangilash_tarixi.log)."
    }
}

# ============ ASOSIY OQIM ============

Log "===== YANGILASH BOSHLANDI ====="
Set-Location $RepoRoot

# 1) Oldindan tekshiruv
if (-not (Test-Path "$RepoRoot\.git")) {
    Log "XATOLIK: $RepoRoot git repositoriyasi emas."
    exit 1
}
$iflosHolat = git status --porcelain
if ($iflosHolat) {
    Log "XATOLIK: saqlanmagan lokal o'zgarishlar bor - avval 'git status' bilan tekshiring va hal qiling. Yangilash BOSHLANMADI."
    exit 1
}
$eskiCommit = (git rev-parse HEAD).Trim()
Log "Joriy versiya: $eskiCommit"

# 2) Zaxira - HALI hech narsaga tegilmagan
Log "--- Zaxira olinmoqda (xizmatlar hali ishlab turibdi) ---"
Write-Host ""
Write-Host "Baza zaxirasini olish uchun ADMIN login/parolni kiriting:"
$adminLogin = Read-Host "Login"
$adminParolSecure = Read-Host "Parol" -AsSecureString
$adminParolBSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminParolSecure)
$adminParol = [Runtime.InteropServices.Marshal]::PtrToStringAuto($adminParolBSTR)

try {
    $loginTanasi = @{ username = $adminLogin; password = $adminParol; role = "admin" } | ConvertTo-Json
    $loginJavob = Invoke-RestMethod -Uri "$BaseUrl/login" -Method Post -ContentType "application/json" -Body $loginTanasi
    $adminToken = $loginJavob.access_token
} catch {
    Log "XATOLIK: admin sifatida kirib bo'lmadi - zaxira olinmadi. Yangilash BOSHLANMADI, xizmatlarga tegilmadi."
    exit 1
}

try {
    $backupJavob = Invoke-RestMethod -Uri "$BaseUrl/backup" -Method Post `
        -Headers @{Authorization = "Bearer $adminToken" } -TimeoutSec 300
    if ($backupJavob.status -ne "ok") {
        Log "XATOLIK: baza zaxirasi muvaffaqiyatsiz: $($backupJavob.message). Yangilash BOSHLANMADI."
        exit 1
    }
    Log "Baza zaxirasi olindi: $($backupJavob.fayl) ($($backupJavob.hajm))"
} catch {
    Log "XATOLIK: /backup so'roviga javob bo'lmadi: $_. Yangilash BOSHLANMADI."
    exit 1
}

$vaqtBelgisi = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$webZaxiraYoli = "$FrontendDir\build\web_zaxira_$vaqtBelgisi"
if (Test-Path $WebDir) {
    Copy-Item -Recurse $WebDir $webZaxiraYoli
    Log "Frontend build zaxirasi olindi: $webZaxiraYoli"
} else {
    $webZaxiraYoli = $null
    Log "OGOHLANTIRISH: $WebDir topilmadi - frontend zaxirasi olinmadi (birinchi marta ishga tushirilayotgan bo'lishi mumkin)."
}

# Eski zaxira papkalarini tozalash - so'nggi 5 tasidan boshqasi.
Get-ChildItem "$FrontendDir\build" -Directory -Filter "web_zaxira_*" -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending | Select-Object -Skip 5 |
    ForEach-Object { Remove-Item -Recurse -Force $_.FullName -ErrorAction SilentlyContinue }

# 3) git pull
Log "--- git pull ---"
if (-not (Buyruq-Muvaffaqiyatlimi { git fetch origin })) {
    Log "XATOLIK: git fetch muvaffaqiyatsiz (tarmoq xatosi). Hech narsaga tegilmadi, xizmatlar o'zgarishsiz ishlab turibdi."
    exit 1
}
if (-not (Buyruq-Muvaffaqiyatlimi { git pull --ff-only origin main })) {
    Log "XATOLIK: git pull muvaffaqiyatsiz (fast-forward emas yoki tarmoq xatosi). Hech narsaga tegilmadi, xizmatlar o'zgarishsiz ishlab turibdi."
    exit 1
}
$yangiCommit = (git rev-parse HEAD).Trim()
if ($yangiCommit -eq $eskiCommit) {
    Log "Yangilanish yo'q - allaqachon eng so'nggi versiyada ($eskiCommit). Chiqilmoqda."
    exit 0
}
Log "Yangi versiya olindi: $yangiCommit"

# 4) Backend bog'liqliklari
Log "--- pip install -r requirements.txt ---"
Set-Location $BackendDir
if (-not (Buyruq-Muvaffaqiyatlimi { pip install -r requirements.txt })) {
    Log "XATOLIK: pip install muvaffaqiyatsiz. Kod eski holatga qaytarilmoqda (xizmatlarga tegilmadi - ular hali eski kod bilan ishlab turibdi)."
    Set-Location $RepoRoot
    try { git reset --hard $eskiCommit | Out-Null } catch { Log "OGOHLANTIRISH: git reset xato: $_" }
    exit 1
}

# 5) Testlar
Log "--- Backend testlari ishga tushirilmoqda ---"
if (-not (Buyruq-Muvaffaqiyatlimi { pytest tests/ -q })) {
    Log "XATOLIK: testlar o'tmadi - yangilanish BEKOR QILINDI. Kod eski holatga qaytarildi, xizmatlarga tegilmadi."
    Set-Location $RepoRoot
    try { git reset --hard $eskiCommit | Out-Null } catch { Log "OGOHLANTIRISH: git reset xato: $_" }
    exit 1
}
Log "Testlar muvaffaqiyatli o'tdi."
Set-Location $RepoRoot

# 6) Foydalanuvchi tasdig'i
Write-Host ""
Write-Host "===================================================================="
Write-Host " Testlar o'tdi: $eskiCommit -> $yangiCommit"
Write-Host " Endi xizmatlar VAQTINCHA TO'XTATILADI, migratsiya va build boshlanadi."
Write-Host "===================================================================="
$tasdiq = Read-Host "Davom etasizmi? (H yoki Y = Ha, boshqa har qanday tugma = Yo'q)"
if ($tasdiq -notmatch '^[HhYy]') {
    Log "Foydalanuvchi bekor qildi - kod eski holatga qaytarilmoqda, xizmatlarga tegilmadi."
    try { git reset --hard $eskiCommit | Out-Null } catch { Log "OGOHLANTIRISH: git reset xato: $_" }
    exit 0
}

# 7) Xizmatlarni to'xtatish - SHU YERDAN boshlab to'xtash vaqti
Log "--- Xizmatlar to'xtatilmoqda ---"
Xizmatlarni-Toxtatish

# 8) Migratsiya
Log "--- alembic upgrade head ---"
Set-Location $BackendDir
$migratsiyaOk = Buyruq-Muvaffaqiyatlimi { alembic upgrade head }
Set-Location $RepoRoot
if (-not $migratsiyaOk) {
    Log "XATOLIK: migratsiya muvaffaqiyatsiz!"
    Orqaga-Qaytarish $eskiCommit $webZaxiraYoli
    exit 1
}
Log "Migratsiya muvaffaqiyatli."

# 9) Flutter build
Log "--- flutter build web --release ---"
Set-Location $FrontendDir
$buildOk = Buyruq-Muvaffaqiyatlimi { flutter build web --release }
Set-Location $RepoRoot
if (-not $buildOk) {
    Log "XATOLIK: flutter build muvaffaqiyatsiz!"
    Orqaga-Qaytarish $eskiCommit $webZaxiraYoli
    exit 1
}
Log "Flutter build muvaffaqiyatli."

# 10) Xizmatlarni qayta ishga tushirish
Log "--- Xizmatlar qayta ishga tushirilmoqda ---"
$ishga_tushdi = $false
try {
    $ishga_tushdi = Xizmatlarni-Ishga-Tushirish
} catch {
    Log "XATOLIK: xizmatlarni ishga tushirishda kutilmagan xato: $_"
}
if (-not $ishga_tushdi) {
    Log "XATOLIK: xizmatlar portlari kutilgan vaqtda ochilmadi!"
    Orqaga-Qaytarish $eskiCommit $webZaxiraYoli
    exit 1
}

# 11) Sog'lomlikni tekshirish
Start-Sleep -Seconds 3
$sogPmi2 = $false
try { $sogPmi2 = Sogliqni-Tekshirish } catch { }
if (-not $sogPmi2) {
    Log "XATOLIK: yangi versiya ishga tushdi-yu, lekin /health javob bermayapti!"
    Orqaga-Qaytarish $eskiCommit $webZaxiraYoli
    exit 1
}

Log "===== YANGILANISH MUVAFFAQIYATLI: $eskiCommit -> $yangiCommit ====="
Telegram-Xabar "$YashilBelgi <b>Tizim muvaffaqiyatli yangilandi.</b>`n$eskiCommit -> $yangiCommit"
exit 0
