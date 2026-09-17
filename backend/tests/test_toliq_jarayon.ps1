# To'liq operator jarayoni - QO'LDA ISHGA TUSHIRILADIGAN TUTUN TESTI
# (smoke test), pytest emas.
#
# DIQQAT: bu skript HAQIQIY, ishlab turgan backendga (odatda
# http://127.0.0.1:47001 - HazoraspBackend NSSM xizmati) ulanadi va
# HAQIQIY ma'lumotlar bazasiga yozadi - alohida "test bazasi" ishlatmaydi
# (backend\tests\*.py pytest testlaridan farqli o'laroq). Natijada:
#   - "99 TEST 99" nomli haqiqiy Mashina/Hujjat/Navbat qatori yaratiladi;
#   - C:\RASMLAR\Chigit\hisobot_Chigit_<yil>.xlsx jurnaliga HAQIQIY qator
#     qo'shiladi (mavsum hisobotiga aralashadi);
#   - C:\RASMLAR\Chigit\... papkasida haqiqiy nakladnoy.pdf yaratiladi.
# Bu qatorlar avtomatik TOZALANMAYDI - agar kerak bo'lsa, keyinroq admin
# panel orqali qo'lda o'chiring/bekor qiling.
#
# Ishlatilishi:  .\test_toliq_jarayon.ps1  [-BaseUrl "http://127.0.0.1:47001"]

param(
    [string]$BaseUrl = "http://127.0.0.1:47001"
)

$ErrorActionPreference = "Stop"
$umumiyXatoBormi = $false

function Bosqich {
    param(
        [string]$Raqam,
        [string]$Tavsif,
        [bool]$Muvaffaqiyat,
        [string]$Qoshimcha = ""
    )
    $matn = "[$Raqam] "
    if ($Muvaffaqiyat) {
        $matn += "✅ YAXSHI - $Tavsif"
        if ($Qoshimcha) { $matn += " ($Qoshimcha)" }
        Write-Host $matn -ForegroundColor Green
    } else {
        $matn += "❌ XATO - $Tavsif"
        if ($Qoshimcha) { $matn += " -- $Qoshimcha" }
        Write-Host $matn -ForegroundColor Red
        $script:umumiyXatoBormi = $true
        Write-Host "`nSkript to'xtatildi (keyingi qadamlar shu natijaga bog'liq)." -ForegroundColor Yellow
        exit 1
    }
}

function XavfsizPapkaNomi {
    # backend\utils.py xavfsiz_papka_nomi() bilan bir xil (soddalashtirilgan)
    # mantiq - faqat shu skriptda ishlatiladigan, oldindan ma'lum matnlar
    # ("Chigit", "99_TEST_99") uchun; umumiy path-traversal himoyasi emas.
    param([string]$Matn)
    return ($Matn -replace '[\\/:*?"<>|]', '_').Trim(". ")
}

Write-Host "=== To'liq operator jarayoni sinovi ($BaseUrl) ===" -ForegroundColor Cyan
Write-Host ""

# --- 1. Operator login ---
Write-Host "Operator login ma'lumotlarini kiriting:"
$Username = Read-Host "Login"
$ParolSecure = Read-Host "Parol" -AsSecureString
$ParolBSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($ParolSecure)
$Parol = [Runtime.InteropServices.Marshal]::PtrToStringAuto($ParolBSTR)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ParolBSTR)

$token = $null
try {
    $loginTanasi = @{ username = $Username; password = $Parol; role = "operator" } | ConvertTo-Json
    $loginJavob = Invoke-RestMethod -Uri "$BaseUrl/login" -Method Post -ContentType "application/json" -Body $loginTanasi
    $token = $loginJavob.access_token
    Bosqich -Raqam 1 -Tavsif "Operator login ($Username)" -Muvaffaqiyat ($null -ne $token)
} catch {
    Bosqich -Raqam 1 -Tavsif "Operator login ($Username)" -Muvaffaqiyat $false -Qoshimcha $_.Exception.Message
}
$headers = @{ Authorization = "Bearer $token" }

# --- 2. Mashina yaratish ---
# DIQQAT: MashinaCreate uchun firma/viloyat ham SHART (foydalanuvchi
# so'rovida ko'rsatilmagan) - shu sabab bu ikkisiga qadam matnida
# ko'rsatilgan oqilona standart qiymat beriladi.
$mashina = $null
try {
    $mashinaTanasi = @{
        davlat_raqami = "99 TEST 99"
        turi           = "Kamaz"
        shofyor        = "Test Shofyor"
        firma          = "Test Firma"
        viloyat        = "Xorazm"
    } | ConvertTo-Json
    $mashina = Invoke-RestMethod -Uri "$BaseUrl/mashinalar" -Method Post -ContentType "application/json" -Headers $headers -Body $mashinaTanasi
    Bosqich -Raqam 2 -Tavsif "Mashina yaratish (99 TEST 99)" -Muvaffaqiyat ($null -ne $mashina.id) -Qoshimcha "id=$($mashina.id)"
} catch {
    Bosqich -Raqam 2 -Tavsif "Mashina yaratish (99 TEST 99)" -Muvaffaqiyat $false -Qoshimcha $_.Exception.Message
}

# --- 3. Hujjat yaratish (aravalar_soni=2, mahsulot_id=1 - Chigit) ---
$hujjat = $null
try {
    $hujjatTanasi = @{
        mashina_id    = $mashina.id
        mahsulot_id   = 1
        aravalar_soni = 2
    } | ConvertTo-Json
    $hujjat = Invoke-RestMethod -Uri "$BaseUrl/hujjatlar" -Method Post -ContentType "application/json" -Headers $headers -Body $hujjatTanasi
    Bosqich -Raqam 3 -Tavsif "Hujjat yaratish (aravalar_soni=2)" -Muvaffaqiyat ($hujjat.aravalar_soni -eq 2) -Qoshimcha "id=$($hujjat.id), raqam=$($hujjat.raqam)"
} catch {
    Bosqich -Raqam 3 -Tavsif "Hujjat yaratish (aravalar_soni=2)" -Muvaffaqiyat $false -Qoshimcha $_.Exception.Message
}

# --- 4. 1-arava TARA ---
try {
    $tara1Tanasi = @{ hujjat_id = $hujjat.id; arava_raqam = 1; tara = 18000 } | ConvertTo-Json
    $tara1 = Invoke-RestMethod -Uri "$BaseUrl/olchovlar" -Method Post -ContentType "application/json" -Headers $headers -Body $tara1Tanasi
    Bosqich -Raqam 4 -Tavsif "1-arava tara o'lchash (18000 kg)" -Muvaffaqiyat ($tara1.tara -eq 18000)
} catch {
    Bosqich -Raqam 4 -Tavsif "1-arava tara o'lchash (18000 kg)" -Muvaffaqiyat $false -Qoshimcha $_.Exception.Message
}

# --- 5. 2-arava TARA ---
try {
    $tara2Tanasi = @{ hujjat_id = $hujjat.id; arava_raqam = 2; tara = 17500 } | ConvertTo-Json
    $tara2 = Invoke-RestMethod -Uri "$BaseUrl/olchovlar" -Method Post -ContentType "application/json" -Headers $headers -Body $tara2Tanasi
    Bosqich -Raqam 5 -Tavsif "2-arava tara o'lchash (17500 kg)" -Muvaffaqiyat ($tara2.tara -eq 17500)
} catch {
    Bosqich -Raqam 5 -Tavsif "2-arava tara o'lchash (17500 kg)" -Muvaffaqiyat $false -Qoshimcha $_.Exception.Message
}

# --- 6. Navbatga qo'shish ---
try {
    $navbatQoshTanasi = @{
        hujjatId      = $hujjat.id
        mashinaId     = $mashina.id
        raqam         = $mashina.davlat_raqami
        turi          = $mashina.turi
        shofyor       = $mashina.shofyor
        firma         = "Test Firma"
        mahsulotId    = 1
        mahsulotNomi  = "Chigit"
        vaqt          = (Get-Date -Format "HH:mm")
        tiketRaqam    = "1234567"
        namlik        = 7.8
        ifloslik      = 0.1
        seleksiyaNavi = "Xorazm-150"
        aravalar      = @{}
    } | ConvertTo-Json
    $navbatQoshJavob = Invoke-RestMethod -Uri "$BaseUrl/navbat/qosh" -Method Post -ContentType "application/json" -Headers $headers -Body $navbatQoshTanasi
    Bosqich -Raqam 6 -Tavsif "Navbatga qo'shish" -Muvaffaqiyat ($navbatQoshJavob.status -eq "ok")
} catch {
    Bosqich -Raqam 6 -Tavsif "Navbatga qo'shish" -Muvaffaqiyat $false -Qoshimcha $_.Exception.Message
}

# --- 7. GET /navbat - aravalarSoni=2 tekshiruvi ---
try {
    $navbatRoyxati = Invoke-RestMethod -Uri "$BaseUrl/navbat" -Method Get -Headers $headers
    $navbatQatori = $navbatRoyxati | Where-Object { $_.hujjatId -eq $hujjat.id } | Select-Object -First 1
    Bosqich -Raqam 7 -Tavsif "GET /navbat - aravalarSoni=2" -Muvaffaqiyat (
        ($null -ne $navbatQatori) -and ($navbatQatori.aravalarSoni -eq 2)
    ) -Qoshimcha "aravalarSoni=$($navbatQatori.aravalarSoni)"
} catch {
    Bosqich -Raqam 7 -Tavsif "GET /navbat - aravalarSoni=2" -Muvaffaqiyat $false -Qoshimcha $_.Exception.Message
}

# --- 8. 1-arava BRUTTO ---
try {
    $brutto1Tanasi = @{ hujjat_id = $hujjat.id; arava_raqam = 1; brutto = 25000 } | ConvertTo-Json
    $brutto1 = Invoke-RestMethod -Uri "$BaseUrl/olchovlar" -Method Post -ContentType "application/json" -Headers $headers -Body $brutto1Tanasi
    Bosqich -Raqam 8 -Tavsif "1-arava brutto o'lchash (25000 kg)" -Muvaffaqiyat ($brutto1.brutto -eq 25000) -Qoshimcha "netto=$($brutto1.netto)"
} catch {
    Bosqich -Raqam 8 -Tavsif "1-arava brutto o'lchash (25000 kg)" -Muvaffaqiyat $false -Qoshimcha $_.Exception.Message
}

# --- 9. Hujjat hali "jarayon"da (1-arava bruttosidan keyin ERTA tugallanmasligi) ---
try {
    $hujjatHolat1 = Invoke-RestMethod -Uri "$BaseUrl/hujjatlar/$($hujjat.id)" -Method Get -Headers $headers
    Bosqich -Raqam 9 -Tavsif "1-arava bruttosidan keyin hujjat hali 'jarayon'da" -Muvaffaqiyat (
        $hujjatHolat1.holat -eq "jarayon"
    ) -Qoshimcha "holat=$($hujjatHolat1.holat)"
} catch {
    Bosqich -Raqam 9 -Tavsif "1-arava bruttosidan keyin hujjat hali 'jarayon'da" -Muvaffaqiyat $false -Qoshimcha $_.Exception.Message
}

# --- 10. 2-arava BRUTTO ---
try {
    $brutto2Tanasi = @{ hujjat_id = $hujjat.id; arava_raqam = 2; brutto = 24000 } | ConvertTo-Json
    $brutto2 = Invoke-RestMethod -Uri "$BaseUrl/olchovlar" -Method Post -ContentType "application/json" -Headers $headers -Body $brutto2Tanasi
    Bosqich -Raqam 10 -Tavsif "2-arava brutto o'lchash (24000 kg)" -Muvaffaqiyat ($brutto2.brutto -eq 24000) -Qoshimcha "netto=$($brutto2.netto)"
} catch {
    Bosqich -Raqam 10 -Tavsif "2-arava brutto o'lchash (24000 kg)" -Muvaffaqiyat $false -Qoshimcha $_.Exception.Message
}

# --- 11. Navbatni tugallash ---
# Haqiqiy operator ekrani BARCHA aravalar bruttosi olingandan keyingina
# shu endpointni chaqiradi (backendning o'zi buni tekshirmaydi - qarang:
# backend\tests\test_kop_arava_toliq_integratsiya.py izohi) - shu sabab bu
# yerda ham faqat 10-qadamdan KEYIN chaqirilmoqda.
try {
    $tugallandiTanasi = @{ hujjatId = $hujjat.id; aravalar = @{} } | ConvertTo-Json
    $tugallandiJavob = Invoke-RestMethod -Uri "$BaseUrl/navbat/tugallandi" -Method Post -ContentType "application/json" -Headers $headers -Body $tugallandiTanasi
    Bosqich -Raqam 11 -Tavsif "Navbatni tugallash (POST /navbat/tugallandi)" -Muvaffaqiyat ($tugallandiJavob.status -eq "ok")
} catch {
    Bosqich -Raqam 11 -Tavsif "Navbatni tugallash (POST /navbat/tugallandi)" -Muvaffaqiyat $false -Qoshimcha $_.Exception.Message
}

# --- 11b. Nakladnoy PDF generatsiyasi ---
# Haqiqiy operator ekranida bu chaqiruv /navbat/tugallandi MUVAFFAQIYATLI
# bo'lgach AVTOMATIK yuboriladi (operator_panel_screen.dart, saqlash()) -
# bu skript frontend ishlatmagani uchun, xuddi shu real oqimni qo'lda
# takrorlaydi (14/16-qadamlar tekshiradigan PDF/papka aynan shu
# chaqiruvdan paydo bo'ladi).
$sanaBugun = Get-Date -Format "yyyy-MM-dd"
try {
    $nakladnoyTanasi = @{
        hujjat_id       = $hujjat.id
        mashina_raqami  = $mashina.davlat_raqami
        mahsulot_nomi   = "Chigit"
        sana            = $sanaBugun
        nakladnoy_raqam = $hujjat.raqam
    } | ConvertTo-Json
    $nakladnoyJavob = Invoke-WebRequest -Uri "$BaseUrl/nakladnoy/saqlash" -Method Post -ContentType "application/json" -Headers $headers -Body $nakladnoyTanasi -UseBasicParsing
    Bosqich -Raqam "11b" -Tavsif "Nakladnoy PDF generatsiyasi" -Muvaffaqiyat ($nakladnoyJavob.StatusCode -eq 200)
} catch {
    Bosqich -Raqam "11b" -Tavsif "Nakladnoy PDF generatsiyasi" -Muvaffaqiyat $false -Qoshimcha $_.Exception.Message
}

# --- 12. Hujjat endi "tugallandi" ---
try {
    $hujjatHolat2 = Invoke-RestMethod -Uri "$BaseUrl/hujjatlar/$($hujjat.id)" -Method Get -Headers $headers
    Bosqich -Raqam 12 -Tavsif "Hujjat holati endi 'tugallandi'" -Muvaffaqiyat (
        $hujjatHolat2.holat -eq "tugallandi"
    ) -Qoshimcha "holat=$($hujjatHolat2.holat)"
} catch {
    Bosqich -Raqam 12 -Tavsif "Hujjat holati endi 'tugallandi'" -Muvaffaqiyat $false -Qoshimcha $_.Exception.Message
}

# --- 13. GET /navbat/tugallanganlar da ko'rinishi ---
try {
    $tugallanganlar = Invoke-RestMethod -Uri "$BaseUrl/navbat/tugallanganlar" -Method Get -Headers $headers
    $tugallanganQator = $tugallanganlar | Where-Object { $_.hujjatId -eq $hujjat.id } | Select-Object -First 1
    Bosqich -Raqam 13 -Tavsif "GET /navbat/tugallanganlar ro'yxatida ko'rinadi" -Muvaffaqiyat (
        ($null -ne $tugallanganQator) -and ($tugallanganQator.aravalarSoni -eq 2)
    )
} catch {
    Bosqich -Raqam 13 -Tavsif "GET /navbat/tugallanganlar ro'yxatida ko'rinadi" -Muvaffaqiyat $false -Qoshimcha $_.Exception.Message
}

# --- 14. C:\RASMLAR\Chigit\... papkasi yaratilganligi ---
# backend\main.py (nakladnoy_saqlash): papka =
#   RASMLAR_DIR / "Chigit" / "yyyy-MM" / "yyyy-MM-dd" / <raqam bo'shliqsiz>
$raqamPapka = XavfsizPapkaNomi ($mashina.davlat_raqami -replace " ", "_")
$mashinaPapka = "C:\RASMLAR\Chigit\$($sanaBugun.Substring(0,7))\$sanaBugun\$raqamPapka"
Bosqich -Raqam 14 -Tavsif "C:\RASMLAR\Chigit\...\$raqamPapka papkasi yaratilgan" -Muvaffaqiyat (Test-Path $mashinaPapka) -Qoshimcha $mashinaPapka

# --- 15. hisobot_Chigit_<yil>.xlsx yaratilganligi ---
# DIQQAT: bu fayl POST /navbat/tugallandi javobi QAYTGANDAN KEYIN, FON
# vazifasi (BackgroundTasks -> excel_qatorga_yoz_fon) sifatida yoziladi -
# haqiqiy serverda (bu skriptdagidek, pytest TestClient'dan farqli
# o'laroq) bu darhol tugamasligi mumkin, shu sabab bir necha marta
# qayta tekshiriladi.
$yil = (Get-Date).Year
$excelFayl = "C:\RASMLAR\Chigit\hisobot_Chigit_$yil.xlsx"
$excelTopildi = $false
for ($urinish = 1; $urinish -le 10; $urinish++) {
    if (Test-Path $excelFayl) { $excelTopildi = $true; break }
    Start-Sleep -Seconds 1
}
Bosqich -Raqam 15 -Tavsif "$excelFayl yaratilgan" -Muvaffaqiyat $excelTopildi -Qoshimcha $excelFayl

# --- 16. Nakladnoy PDF fayli yaratilganligi ---
$pdfFayl = Join-Path $mashinaPapka "nakladnoy.pdf"
Bosqich -Raqam 16 -Tavsif "Nakladnoy PDF fayli yaratilgan" -Muvaffaqiyat (Test-Path $pdfFayl) -Qoshimcha $pdfFayl

Write-Host ""
if (-not $umumiyXatoBormi) {
    Write-Host "=== BARCHA 16 QADAM MUVAFFAQIYATLI O'TDI ===" -ForegroundColor Green
    Write-Host "DIQQAT: 'hujjat_id=$($hujjat.id)', 'raqam=$($hujjat.raqam)' - test ma'lumotlari HAQIQIY bazada/jurnalda qoldi, avtomatik tozalanmadi." -ForegroundColor Yellow
}
