# ============================================================
# HikCentral kompyuterida CHUQUR, TO'LIQ XAVFSIZ (faqat o'qish -
# hech narsani o'zgartirmaydi, o'rnatmaydi, o'chirmaydi, hech qanday
# xizmatni to'xtatmaydi/qayta ishga tushirmaydi) tekshiruv.
#
# Ushbu skriptdagi HAR BIR buyruq faqat o'qish (Get-*/Test-*) turida -
# hech qanday Set-/New-/Remove-/Stop-/Start-/Install- buyrug'i YO'Q.
# HikCentral kompyuteriga 100% xavfsiz, orqasidan hech qanday iz
# qoldirmaydi.
#
# Ishga tushirish: PowerShell'ni "Run as Administrator" bilan oching
# (ba'zi buyruqlar - masalan xizmat yo'llari - administrator huquqisiz
# to'liq ma'lumot bermasligi mumkin), so'ng shu faylni bajaring.
#
# Natijani TO'LIQ nusxalab (yoki fayl sifatida saqlab: quyidagi
# transkript qismiga qarang), javob sifatida qaytaring.
# ============================================================

$transcriptYoli = "$env:TEMP\hikcentral_tekshiruv_natija_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
Start-Transcript -Path $transcriptYoli -Force | Out-Null

Write-Host "`n############################################################"
Write-Host "# 1. TIZIM ASOSIY MA'LUMOTLARI"
Write-Host "############################################################" -ForegroundColor Cyan
Get-CimInstance Win32_OperatingSystem |
    Select-Object Caption, Version, OSArchitecture, LastBootUpTime,
        @{N='UptimeKun';E={[math]::Round(((Get-Date) - $_.LastBootUpTime).TotalDays,1)}} |
    Format-List

Write-Host "`n############################################################"
Write-Host "# 2. TINGLAYOTGAN TCP PORTLAR (BARCHASI, to'liq exe yo'li bilan)"
Write-Host "############################################################" -ForegroundColor Cyan
Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Select-Object LocalAddress, LocalPort, OwningProcess -Unique |
    Sort-Object LocalPort |
    ForEach-Object {
        $proc = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
        $exeYoli = $null
        $kompaniya = $null
        if ($proc -and $proc.Path) {
            $exeYoli = $proc.Path
            try { $kompaniya = (Get-Item $proc.Path -ErrorAction Stop).VersionInfo.CompanyName } catch {}
        }
        [PSCustomObject]@{
            Port      = $_.LocalPort
            Manzil    = $_.LocalAddress
            Jarayon   = if ($proc) { $proc.ProcessName } else { "?" }
            PID       = $_.OwningProcess
            Kompaniya = $kompaniya
            ExeYoli   = $exeYoli
        }
    } | Format-Table -AutoSize -Wrap

Write-Host "`n############################################################"
Write-Host "# 3. TINGLAYOTGAN UDP PORTLAR (video striming/RTSP ko'pincha UDP ishlatadi)"
Write-Host "############################################################" -ForegroundColor Cyan
Get-NetUDPEndpoint -ErrorAction SilentlyContinue |
    Select-Object LocalAddress, LocalPort, OwningProcess -Unique |
    Sort-Object LocalPort |
    ForEach-Object {
        $proc = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            Port    = $_.LocalPort
            Manzil  = $_.LocalAddress
            Jarayon = if ($proc) { $proc.ProcessName } else { "?" }
            PID     = $_.OwningProcess
        }
    } | Format-Table -AutoSize

Write-Host "`n############################################################"
Write-Host "# 4. BIZGA KERAK BO'LISHI MUMKIN BO'LGAN PORTLAR BAND-BAND EMASLIGI"
Write-Host "############################################################" -ForegroundColor Cyan
# 47001/47080 - bizning backend/frontend; 5432 - HikCentral'ning Postgres porti;
# 47432 - bizning Postgres uchun tanlangan port (5432'dan aniq uzoq);
# 5000/8000/3000/8888 - Python/veb ilovalarda tez-tez uchraydigan qo'shimcha portlar
foreach ($p in 47001, 47080, 5432, 47432, 5000, 8000, 3000, 8888) {
    $c = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue
    if ($c) {
        $proc = Get-Process -Id $c[0].OwningProcess -ErrorAction SilentlyContinue
        Write-Host ("  Port {0,-6}: BAND -> {1} (PID {2}, {3})" -f $p, $proc.ProcessName, $c[0].OwningProcess, $proc.Path) -ForegroundColor Yellow
    } else {
        Write-Host "  Port $p : BO'SH" -ForegroundColor Green
    }
}

Write-Host "`n############################################################"
Write-Host "# 5. BARCHA NOSTANDART (Microsoft'dan boshqa) XIZMATLAR"
Write-Host "#    (Hik nomi bo'lmasa ham - Redis/Mongo/RabbitMQ/Nginx/Tomcat/"
Write-Host "#     Postgres/SQL Server kabi HikCentral bilan birga o'rnatiladigan"
Write-Host "#     yordamchi komponentlarni ham shu yerdan qidiring)"
Write-Host "############################################################" -ForegroundColor Cyan
Get-CimInstance Win32_Service |
    Where-Object { $_.PathName -and $_.PathName -notlike "*\Windows\System32\*" -and $_.PathName -notlike "*\Windows\servicing\*" } |
    Select-Object Name, DisplayName, State, StartMode, PathName |
    Sort-Object DisplayName | Format-Table -AutoSize -Wrap

Write-Host "`n############################################################"
Write-Host "# 6. 'HIK', 'ISECURE', 'HCP' NOMLI XIZMATLAR (tezkor filtr)"
Write-Host "############################################################" -ForegroundColor Cyan
Get-Service | Where-Object { $_.DisplayName -match 'Hik|iSecure|HCP' -or $_.Name -match 'Hik|iSecure|HCP' } |
    Select-Object Name, DisplayName, Status, StartType | Format-Table -AutoSize

Write-Host "`n############################################################"
Write-Host "# 7. POSTGRESQL / SQL SERVER / BOSHQA BAZA XIZMATLARI"
Write-Host "#    (HikCentral o'zi PostgreSQL yoki SQL Server ishlatishi mumkin -"
Write-Host "#     topilsa, bizning Postgres o'rnatishimiz albatta BOSHQA portda"
Write-Host "#     yoki BOSHQA instance nomi bilan bo'lishi kerak)"
Write-Host "############################################################" -ForegroundColor Cyan
Get-Service | Where-Object {
    $_.DisplayName -match 'postgres|SQL Server|MySQL|MariaDB|Mongo|Redis' -or
    $_.Name -match 'postgres|MSSQL|MySQL|MariaDB|Mongo|Redis'
} | Select-Object Name, DisplayName, Status, StartType | Format-Table -AutoSize

Write-Host "`n############################################################"
Write-Host "# 8. DISK BO'SH JOYI (har bir disk)"
Write-Host "############################################################" -ForegroundColor Cyan
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID, VolumeName,
        @{N='JamiGB';E={[math]::Round($_.Size/1GB,1)}},
        @{N='BoshGB';E={[math]::Round($_.FreeSpace/1GB,1)}},
        @{N='Bosh_Foiz';E={[math]::Round(($_.FreeSpace/$_.Size)*100,1)}} |
    Format-Table -AutoSize

Write-Host "`n############################################################"
Write-Host "# 9. VIDEO ARXIV/HIKCENTRAL O'RNATISH JOYINI TOPISHGA URINISH"
Write-Host "#    (faqat MAVJUDLIGI va qaysi diskda ekanligi ko'rsatiladi -"
Write-Host "#     katta papkalar chuqur skanerlanmaydi, uzoq vaqt olishi mumkin)"
Write-Host "############################################################" -ForegroundColor Cyan
$nomzodYollar = @(
    "C:\Program Files\HikCentral*",
    "C:\Program Files (x86)\HikCentral*",
    "C:\iSecure Center*",
    "D:\iSecure Center*",
    "E:\iSecure Center*",
    "C:\HCP*",
    "D:\HCP*",
    "D:\Storage*",
    "E:\Storage*",
    "D:\Record*",
    "E:\Record*"
)
foreach ($yol in $nomzodYollar) {
    $topilgan = Get-Item $yol -ErrorAction SilentlyContinue
    if ($topilgan) {
        foreach ($t in $topilgan) {
            Write-Host "  TOPILDI: $($t.FullName)  (disk: $($t.PSDrive.Name):)" -ForegroundColor Yellow
        }
    }
}
Write-Host "  (Agar yuqorida hech narsa ko'rinmasa - HikCentral operatoridan"
Write-Host "   video arxiv qaysi diskda saqlanishini so'rab, shu diskning"
Write-Host "   yuqoridagi 8-bo'limdagi bo'sh joyiga qarang.)"

Write-Host "`n############################################################"
Write-Host "# 10. RAM - UMUMIY VA NOSTANDART XIZMATLAR TOMONIDAN BAND QILINGANI"
Write-Host "############################################################" -ForegroundColor Cyan
$os = Get-CimInstance Win32_OperatingSystem
[PSCustomObject]@{
    JamiRAM_GB = [math]::Round($os.TotalVisibleMemorySize/1MB,1)
    BandRAM_GB = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory)/1MB,1)
    BoshRAM_GB = [math]::Round($os.FreePhysicalMemory/1MB,1)
} | Format-List

Write-Host "  Eng ko'p RAM ishlatayotgan 15 ta jarayon:" -ForegroundColor Cyan
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 15 |
    Select-Object ProcessName, Id, @{N='RAM_MB';E={[math]::Round($_.WorkingSet/1MB,1)}}, Path |
    Format-Table -AutoSize -Wrap

Write-Host "`n############################################################"
Write-Host "# 11. CPU - 5 SONIYALIK NAMUNA (umumiy protsessor yuklamasi)"
Write-Host "############################################################" -ForegroundColor Cyan
try {
    $namunalar = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 5 -ErrorAction Stop
    $ortacha = ($namunalar.CounterSamples | Measure-Object -Property CookedValue -Average).Average
    Write-Host ("  O'rtacha CPU yuklamasi (5 soniya): {0}%" -f [math]::Round($ortacha,1))
} catch {
    Write-Host "  CPU hisoblagichi o'qib bo'lmadi: $_" -ForegroundColor Yellow
}
Write-Host "  Eng ko'p CPU vaqtini ishlatgan (kumulyativ) 10 ta jarayon:" -ForegroundColor Cyan
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 |
    Select-Object ProcessName, Id, CPU, @{N='RAM_MB';E={[math]::Round($_.WorkingSet/1MB,1)}} |
    Format-Table -AutoSize

Write-Host "`n############################################################"
Write-Host "# 12. BARCHA O'RNATILGAN DASTURLAR (versiyalari bilan)"
Write-Host "############################################################" -ForegroundColor Cyan
$uninstallYollari = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
Get-ItemProperty $uninstallYollari -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName } |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
    Sort-Object DisplayName | Format-Table -AutoSize -Wrap

Write-Host "`n############################################################"
Write-Host "# 13. PYTHON / GIT / POSTGRESQL ALLAQACHON O'RNATILGANMI"
Write-Host "############################################################" -ForegroundColor Cyan
try { Write-Host "Python:     $(python --version 2>&1)" } catch { Write-Host "Python:     topilmadi" }
try { Write-Host "Git:        $(git --version 2>&1)" } catch { Write-Host "Git:        topilmadi" }
try { Write-Host "psql:       $(psql --version 2>&1)" } catch { Write-Host "psql:       topilmadi (PATH'da emas - baribir o'rnatilgan bo'lishi mumkin, 12-bo'limga qarang)" }

Write-Host "`n############################################################"
Write-Host "# 14. FIREWALL HOLATI VA MAVJUD QOIDALAR SONI"
Write-Host "############################################################" -ForegroundColor Cyan
Get-NetFirewallProfile | Select-Object Name, Enabled | Format-Table -AutoSize
Write-Host "  Jami firewall qoidalari soni: $((Get-NetFirewallRule).Count)"
Write-Host "  'Barcha dastur/portga' ruxsat beruvchi keng qoidalar (agar bo'lsa):" -ForegroundColor Cyan
Get-NetFirewallRule -Direction Inbound -Action Allow -Enabled True -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match 'Any|All|HikCentral|iSecure' } |
    Select-Object DisplayName, Direction, Action | Format-Table -AutoSize

Write-Host "`n############################################################"
Write-Host "# 15. WINDOWS SYSTEM RESTORE HOLATI"
Write-Host "#    (biz o'rnatishdan OLDIN yangi restore point yaratish"
Write-Host "#     tavsiya etiladi - bu yerda hozirgi holat ko'rsatiladi)"
Write-Host "############################################################" -ForegroundColor Cyan
try {
    $restoreNuqtalari = Get-ComputerRestorePoint -ErrorAction Stop
    if ($restoreNuqtalari) {
        $restoreNuqtalari | Select-Object -Last 5 SequenceNumber, CreationTime, Description |
            Format-Table -AutoSize
    } else {
        Write-Host "  Hech qanday restore point topilmadi." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  System Restore ma'lumotini o'qib bo'lmadi (o'chirilgan bo'lishi mumkin): $_" -ForegroundColor Yellow
}

Write-Host "`nTEKSHIRUV TUGADI." -ForegroundColor Green
Write-Host "Natija shu faylga ham saqlandi: $transcriptYoli" -ForegroundColor Green
Write-Host "Iltimos yuqoridagi BARCHA natijani (yoki shu faylni) to'liq nusxalab yuboring." -ForegroundColor Green

Stop-Transcript | Out-Null
