#requires -Version 5.1
<#
  frontend_yangilash.ps1

  AKT (dev/build) mashinada tayyor turgan Flutter web build'ni
  (C:\hazorasp_tarozi\frontend\build\web) 10.112.21.54 serveriga
  ko'chiradi va HazoraspFrontend xizmatini qayta ishga tushiradi.

  Ishlash tartibi:
    1) Oldindan tekshiruv (lokal build/web + index.html bor; uzoq share
       ochiq) + masofadan boshqaruv (WinRM) mavjudmi - aniqlash
    2) HazoraspFrontend to'xtatiladi (Invoke-Command -ComputerName orqali)
    3) Uzoqdagi joriy 'web' -> 'web_zaxira_<vaqt>' (robocopy nusxa) -
       rollback uchun
    4) robocopy /MIR : lokal build\web  ->  uzoq share\web
    5) HazoraspFrontend ishga tushiriladi (Invoke-Command)
    6) http://10.112.21.54:47080/  ->  HTTP 200 tekshiruvi
    7) 3-6 orasida xato bo'lsa: zaxira qaytariladi, xizmat qayta
       ko'tariladi, natija log/ekranga yoziladi

  MASOFADAN BOSHQARUV (xizmat stop/start):
    Invoke-Command -ComputerName 10.112.21.54 { ... }  (WinRM /
    PowerShell Remoting) orqali bajariladi.
    Agar WinRM ISHLAMASA (TrustedHosts, firewall, huquq yetmasligi) -
    skript baribir FAYLLARNI KO'CHIRADI, xizmat stop/start'ni O'TKAZIB
    YUBORADI va oxirida "Server da HazoraspFrontend ni qayta ishga
    tushiring" deb ogohlantiradi (keyin qo'lda restart qilinadi).

    WinRM'ni yoqish (bir marta):
      - Server (10.112.21.54) da, admin PowerShell:  Enable-PSRemoting -Force
      - Bu (AKT) mashinada, admin PowerShell:
          Set-Item WSMan:\localhost\Client\TrustedHosts -Value 10.112.21.54 -Concatenate -Force
      (domendan tashqari IP bilan ulanish uchun TrustedHosts kerak)

  DIQQAT (yangilash.ps1'dagi bir xil qoida): bu faylda ATAYLAB
  emoji/lotin-bo'lmagan belgi ishlatilmaydi - Windows PowerShell 5.1
  BOM'siz UTF-8 .ps1 faylidagi ko'p-baytli belgilarni tizim kodlashi
  bilan noto'g'ri o'qib, skriptni parse qila olmay qolishi mumkin.

  TALABLAR:
    - Bu skript AKT (Flutter bor) mashinada ishga tushiriladi.
    - Uzoq share (\\10.112.21.54\frontend_build) yozish uchun ochiq.
      Kerak bo'lsa bir marta:
        cmdkey /add:10.112.21.54 /user:SERVER\deploy /pass:PAROL
    - Avtomatik restart uchun: WinRM yoqilgan + ishga tushiruvchi hisob
      serverda administrator. Bo'lmasa - restart qo'lda qilinadi.

  ISHGA TUSHIRISH:
    powershell -ExecutionPolicy Bypass -File C:\hazorasp_tarozi\frontend_yangilash.ps1
    (ixtiyoriy: -Build  bayrog'i avval "flutter build web --release" ni ham bajaradi)
#>

[CmdletBinding()]
param(
    [string]$LokalWebDir = "C:\hazorasp_tarozi\frontend\build\web",

    # DIQQAT: bu skript uzoq share = ...\frontend\build deb hisoblaydi
    # (serverga beriladigan papka - shu share ICHIDAGI 'web'; zaxiralar
    # 'web' yonida turadi). Agar share TO'G'RIDAN-TO'G'RI ...\build\web
    # ga ishora qilsa, ikkala yo'lni ham moslang (yaxshisi share'ni
    # ...\build ga qayta yo'naltiring - aks holda zaxira 'web' ichida
    # yotadi va /MIR uni o'chirib yuboradi).
    [string]$UzoqWebDir      = "\\10.112.21.54\frontend_build\web",
    [string]$UzoqZaxiraIldiz = "\\10.112.21.54\frontend_build",

    [string]$KompyuterNomi = "10.112.21.54",
    [string]$XizmatNomi    = "HazoraspFrontend",
    [int]$Port             = 47080,
    [int]$ZaxiraSoni       = 5,

    # -Build berilsa, ko'chirishdan oldin "flutter build web --release"
    # bajariladi (frontend papkasida).
    [switch]$Build
)

$ErrorActionPreference = "Stop"
$LogFayl     = "C:\hazorasp_tarozi\frontend_yangilash.log"
$FrontendDir = Split-Path -Parent (Split-Path -Parent $LokalWebDir)

# WinRM orqali uzoq xizmatni boshqarib bo'ladimi - startda aniqlanadi.
$script:Masofa = $false

# WinRM ulanish sozlamasi - ulanish yo'q bo'lsa TEZ (8s) xato bersin,
# standart (bir necha daqiqa) kutmasin.
$script:PSO = New-PSSessionOption -OpenTimeout 8000 -OperationTimeout 60000 -CancelTimeout 5000

function Log($matn) {
    $q = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $matn
    Write-Host $q
    try { Add-Content -Path $LogFayl -Value $q -Encoding UTF8 } catch { }
}

function URL() { return ("http://{0}:{1}/" -f $KompyuterNomi, $Port) }

# robocopy: 0-7 = muvaffaqiyat (1 = fayllar ko'chirildi, 3 = ko'chirildi
# + ortiqchasi o'chirildi - hammasi NORMAL); 8 va undan katta = xato.
function Robocopy-Ishla($manba, $maqsad) {
    $roboArgs = @($manba, $maqsad, "/MIR", "/R:3", "/W:3", "/NFL", "/NDL", "/NP", "/NJH", "/NJS")
    & robocopy @roboArgs | Out-Null
    $kod = $LASTEXITCODE
    if ($kod -ge 8) { Log "robocopy XATO kodi: $kod ($manba -> $maqsad)"; return $false }
    return $true
}

# WinRM (Invoke-Command -ComputerName) ishlaydimi - bir marta tekshiradi.
function Masofani-Aniqla {
    try {
        $nom = Invoke-Command -ComputerName $KompyuterNomi -SessionOption $script:PSO -ScriptBlock { $env:COMPUTERNAME } -ErrorAction Stop
        $script:Masofa = $true
        Log "Masofadan boshqaruv (WinRM) OK - uzoq kompyuter: $nom"
    } catch {
        $script:Masofa = $false
        Log "OGOHLANTIRISH: WinRM (Invoke-Command) ishlamadi: $($_.Exception.Message)"
        Log "  -> Xizmat AVTOMATIK restart QILINMAYDI: fayllar ko'chiriladi, keyin serverda QO'LDA restart kerak."
        Log "  -> Yoqish: serverda 'Enable-PSRemoting -Force'; bu mashinada 'Set-Item WSMan:\localhost\Client\TrustedHosts -Value $KompyuterNomi -Concatenate -Force'"
    }
}

# Uzoq xizmatni Invoke-Command orqali boshqaradi. $amal = "Stop" | "Start".
# $script:Masofa false bo'lsa - hech narsa qilmaydi, $false qaytaradi.
function Uzoq-Xizmat($amal) {
    if (-not $script:Masofa) { return $false }
    try {
        $holat = Invoke-Command -ComputerName $KompyuterNomi -SessionOption $script:PSO -ArgumentList $XizmatNomi, $amal -ErrorAction Stop -ScriptBlock {
            param($nom, $amal)
            $s = Get-Service -Name $nom -ErrorAction Stop
            if ($amal -eq "Stop") {
                if ($s.Status -ne "Stopped") { $s | Stop-Service -Force -ErrorAction Stop }
                $s.WaitForStatus("Stopped", (New-TimeSpan -Seconds 30))
            } else {
                if ($s.Status -ne "Running") { $s | Start-Service -ErrorAction Stop }
                $s.WaitForStatus("Running", (New-TimeSpan -Seconds 30))
            }
            (Get-Service -Name $nom).Status.ToString()
        }
        Log "Uzoq xizmat '$amal' -> holat: $holat"
        return $true
    } catch {
        Log "XATOLIK: uzoq xizmat '$amal' bajarilmadi: $($_.Exception.Message)"
        return $false
    }
}

function Soglik-Tekshir {
    for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep -Seconds 2
        try {
            $j = Invoke-WebRequest -Uri (URL) -UseBasicParsing -TimeoutSec 5
            if ($j.StatusCode -eq 200) { return $true }
        } catch { }
    }
    return $false
}

function Qolda-Restart-Xabari {
    Log "======================================================================"
    Log "  DIQQAT: Server da HazoraspFrontend ni QO'LDA qayta ishga tushiring."
    Log "  10.112.21.54 da administrator sifatida:   Restart-Service HazoraspFrontend"
    Log "  (yoki:  nssm restart HazoraspFrontend )"
    Log "======================================================================"
    Write-Host ""
    Write-Host "  >>> Server da HazoraspFrontend ni QO'LDA qayta ishga tushiring <<<" -ForegroundColor Yellow
    Write-Host "      Restart-Service HazoraspFrontend" -ForegroundColor Yellow
    Write-Host ""
}

# Zaxira tarkibini 'web' ga so'zsiz robocopy /MIR bilan qaytaradi
# (yangilash.ps1 darsi: oraliq holatga ishonmaslik, yakuniy natijani
# ta'minlash). Yaroqli zaxira bo'lmasa - ogohlantiradi.
function Zaxiradan-Tiklash($zaxiraYoli) {
    if ($zaxiraYoli -and (Test-Path (Join-Path $zaxiraYoli "index.html"))) {
        if (-not (Test-Path $UzoqWebDir)) { New-Item -ItemType Directory -Path $UzoqWebDir -Force | Out-Null }
        Robocopy-Ishla $zaxiraYoli $UzoqWebDir | Out-Null
        if (Test-Path (Join-Path $UzoqWebDir "index.html")) {
            Log "Eski build tiklandi: $zaxiraYoli"; return $true
        }
        Log "JIDDIY: eski build tiklanmadi - QO'LDA aralashing: $zaxiraYoli"; return $false
    }
    Log "JIDDIY: yaroqli zaxira topilmadi - 'web' ni QO'LDA tiklang."; return $false
}

# ============================ ASOSIY OQIM ============================
Log "===== FRONTEND YANGILASH BOSHLANDI ====="

# 0) Ixtiyoriy: build
if ($Build) {
    Log "--- flutter build web --release ---"
    Push-Location $FrontendDir
    & flutter build web --release
    $buildKod = $LASTEXITCODE
    Pop-Location
    if ($buildKod -ne 0) { Log "XATOLIK: flutter build muvaffaqiyatsiz (kod $buildKod). To'xtatildi."; exit 1 }
    Log "Build tayyor."
}

# 1) Oldindan tekshiruv
if (-not (Test-Path (Join-Path $LokalWebDir "index.html"))) {
    Log "XATOLIK: $LokalWebDir\index.html topilmadi - avval 'flutter build web --release' bajaring (yoki -Build bilan ishga tushiring)."
    exit 1
}
if (-not (Test-Path $UzoqZaxiraIldiz)) {
    Log "XATOLIK: uzoq share ochilmadi yoki yo'q: $UzoqZaxiraIldiz"
    exit 1
}
Log "Lokal build : $LokalWebDir"
Log "Uzoq maqsad : $UzoqWebDir"

Masofani-Aniqla

# 2) Xizmatni to'xtatish (faqat WinRM bor bo'lsa)
if ($script:Masofa) {
    if (-not (Uzoq-Xizmat "Stop")) {
        Log "OGOHLANTIRISH: xizmat to'xtatilmadi - masofasiz (qo'lda restart) rejimiga o'tilmoqda."
        $script:Masofa = $false
    } else {
        Start-Sleep -Seconds 2
    }
}

# 3) Zaxira (robocopy nusxa - xizmat ishlab tursa ham xavfsiz)
$ts = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$zaxiraYoli = Join-Path $UzoqZaxiraIldiz ("web_zaxira_" + $ts)
$zaxiraOk = $false
if (Test-Path (Join-Path $UzoqWebDir "index.html")) {
    if (Robocopy-Ishla $UzoqWebDir $zaxiraYoli) {
        $zaxiraOk = $true
        Log "Joriy build zaxiraga olindi: $zaxiraYoli"
    } else {
        Log "OGOHLANTIRISH: zaxira olinmadi - rollback cheklangan bo'ladi."
    }
} else {
    Log "Eslatma: uzoqda hali build yo'q (birinchi joylashtirish) - zaxira o'tkazib yuborildi."
}

# Eski zaxiralarni tozalash - so'nggi $ZaxiraSoni tasidan boshqasi
try {
    Get-ChildItem $UzoqZaxiraIldiz -Directory -Filter "web_zaxira_*" -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -Skip $ZaxiraSoni |
        ForEach-Object { Remove-Item -Recurse -Force $_.FullName -ErrorAction SilentlyContinue }
} catch { }

# 4) Ko'chirish
Log "--- robocopy /MIR ---"
if (-not (Robocopy-Ishla $LokalWebDir $UzoqWebDir)) {
    Log "XATOLIK: robocopy muvaffaqiyatsiz!"
    if ($zaxiraOk) { Zaxiradan-Tiklash $zaxiraYoli | Out-Null }
    if ($script:Masofa) { Uzoq-Xizmat "Start" | Out-Null } else { Qolda-Restart-Xabari }
    exit 1
}
if (-not (Test-Path (Join-Path $UzoqWebDir "index.html"))) {
    Log "XATOLIK: ko'chirishdan keyin ham $UzoqWebDir\index.html yo'q!"
    if ($zaxiraOk) { Zaxiradan-Tiklash $zaxiraYoli | Out-Null }
    if ($script:Masofa) { Uzoq-Xizmat "Start" | Out-Null } else { Qolda-Restart-Xabari }
    exit 1
}
Log "Fayllar ko'chirildi."

# 5) Masofa bor bo'lsa: restart + sog'liq + rollback
if ($script:Masofa) {
    if ((Uzoq-Xizmat "Start") -and (Soglik-Tekshir)) {
        Log ("===== YANGILASH MUVAFFAQIYATLI - {0} 200 qaytardi =====" -f (URL))
        exit 0
    }
    Log "XATOLIK: yangi build ishga tushmadi yoki sayt 200 qaytarmadi - orqaga qaytarilmoqda."
    Uzoq-Xizmat "Stop" | Out-Null
    Start-Sleep -Seconds 2
    Zaxiradan-Tiklash $zaxiraYoli | Out-Null
    $qaytaOk = (Uzoq-Xizmat "Start") -and (Soglik-Tekshir)
    if ($qaytaOk) {
        Log "Orqaga qaytarish MUVAFFAQIYATLI - eski versiya ishlamoqda."
    } else {
        Log "JIDDIY: orqaga qaytarishdan keyin ham sayt sog'lom EMAS."
        Qolda-Restart-Xabari
    }
    exit 1
}

# 6) Masofasiz rejim: fayllar ko'chirildi, xizmat stop/start QILINMADI
Log "Fayllar serverga ko'chirildi, lekin xizmat masofadan boshqarilmadi (WinRM yo'q)."
Log "Eslatma: 'python -m http.server' keshsiz - odatda restart'siz ham yangi fayllarni beradi,"
Log "         lekin izchillik uchun (yarim-yangi to'plamdan qochish) restart tavsiya etiladi."
Qolda-Restart-Xabari
if (Soglik-Tekshir) { Log "Eslatma: sayt hozir (restart'siz) 200 qaytaryapti." }
else               { Log "Eslatma: sayt hozir 200 qaytarmadi - QO'LDA restart'dan keyin tekshiring." }
exit 0
