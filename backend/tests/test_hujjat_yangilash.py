"""
PUT /hujjatlar/{id} - hujjat yangilash: operator ruxsatsiz maydonga
tegsa 403, taqiqlangan holat o'tishi rad etilishi, bekor qilishda sabab
majburiyligi, va audit (TahrirTarixi) yozuvi to'g'ri yaratilishi.

DIQQAT: holat "tugallandi"ga o'tganda main.py HAQIQIY diskka (C:/RASMLAR/
hisobot_*.xlsx) Excel yozadi (excel_qatorga_yoz()). Test ma'lumotlari
alohida test bazasida bo'lsa ham, bu funksiya HAQIQIY fayl tizimiga
yozadi - shuning uchun uni monkeypatch bilan zararsizlantiramiz (main.py
kodining o'ziga tegilmaydi, faqat shu test jarayonida vaqtincha
almashtiriladi).
"""
import pytest


@pytest.fixture()
def hujjat(client, admin_headers, mahsulot_chigit, mashina):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
    }, headers=admin_headers)
    return javob.json()


def test_operator_ruxsatsiz_maydonga_tegsa_403(client, operator_headers, hujjat):
    javob = client.put(f"/hujjatlar/{hujjat['id']}", json={
        "shofyor": "Boshqa Shofyor",  # operator ruxsat etilgan ro'yxatda yo'q
    }, headers=operator_headers)
    assert javob.status_code == 403


def test_operator_ruxsat_etilgan_maydonni_ozgartira_oladi(client, operator_headers, hujjat):
    # qabul_qildi AUDIT_MAYDONLAR ro'yxatida - o'zgartirilganda sabab
    # ham yuborilishi shart (aks holda 400 - bu kutilgan xatti-harakat).
    javob = client.put(f"/hujjatlar/{hujjat['id']}", json={
        "qabul_qildi": "Test Qabul Qiluvchi", "sabab": "Yuk qabul qilindi",
    }, headers=operator_headers)
    assert javob.status_code == 200
    assert javob.json()["qabul_qildi"] == "Test Qabul Qiluvchi"


def test_bekor_qilishda_sabab_majburiy(client, admin_headers, hujjat):
    javob = client.put(f"/hujjatlar/{hujjat['id']}", json={
        "holat": "bekor",
    }, headers=admin_headers)
    assert javob.status_code == 400


def test_bekor_qilish_sabab_bilan_ishlaydi(client, admin_headers, hujjat):
    javob = client.put(f"/hujjatlar/{hujjat['id']}", json={
        "holat": "bekor", "bekor_sabab": "Test uchun bekor qilindi",
    }, headers=admin_headers)
    assert javob.status_code == 200
    assert javob.json()["holat"] == "bekor"


def test_bekor_qilingandan_keyin_tugallash_rad_etiladi(client, admin_headers, hujjat):
    # Avval bekor qilinadi (yakuniy holat).
    client.put(f"/hujjatlar/{hujjat['id']}", json={
        "holat": "bekor", "bekor_sabab": "Test",
    }, headers=admin_headers)
    # Endi "tugallandi"ga o'tkazishga urinish - RAD ETILISHI kerak
    # (yakuniy holatdan boshqa holatga o'tib bo'lmaydi).
    javob = client.put(f"/hujjatlar/{hujjat['id']}", json={
        "holat": "tugallandi",
    }, headers=admin_headers)
    assert javob.status_code == 400


def test_tugallandi_otishi_audit_yozadi_va_excel_chaqiradi(
        client, admin_headers, hujjat, monkeypatch):
    chaqirildi = {"soni": 0}

    def _soxta_excel_yozish(hujjat_id, db):
        chaqirildi["soni"] += 1

    monkeypatch.setattr("main.excel_qatorga_yoz", _soxta_excel_yozish)

    javob = client.put(f"/hujjatlar/{hujjat['id']}", json={
        "holat": "tugallandi", "sabab": "Test tugallash",
    }, headers=admin_headers)
    assert javob.status_code == 200
    assert javob.json()["holat"] == "tugallandi"
    # excel_qatorga_yoz() aynan shu o'tishda BIR MARTA chaqirilishi kerak
    # (haqiqiy fayl yozilmadi - soxtasi chaqirildi).
    assert chaqirildi["soni"] == 1


def test_audit_tarixi_yoziladi(client, admin_headers, hujjat):
    client.put(f"/hujjatlar/{hujjat['id']}", json={
        "shofyor": "Yangi Shofyor Ismi", "sabab": "Xato yozilgan edi",
    }, headers=admin_headers)
    javob = client.get(f"/tahrirlar-tarixi/{hujjat['id']}", headers=admin_headers)
    assert javob.status_code == 200
    tarix = javob.json()
    assert any(t["maydon"] == "shofyor" and t["yangi_qiymat"] == "Yangi Shofyor Ismi"
               for t in tarix)


def test_sababsiz_ozgartirish_rad_etiladi(client, admin_headers, hujjat):
    javob = client.put(f"/hujjatlar/{hujjat['id']}", json={
        "shofyor": "Sababsiz Ozgartirish",
    }, headers=admin_headers)
    assert javob.status_code == 400


def test_namlik_ifloslik_0_ga_ozgartirilsa_konditsion_hisoblanadi(
        client, admin_headers, hujjat):
    """Real xato: namlik=0 yoki ifloslik=0 (masalan mutlaqo toza paxta)
    haqiqiy, yaroqli qiymat - lekin avvalgi kod `if namlik and ifloslik:`
    (truthy tekshiruv) ishlatgani uchun admin buni 0'ga o'zgartirganda
    ham konditsion HECH QACHON qayta hisoblanmasdi."""
    from utils import konditsion_hisobla

    client.post("/olchovlar", json={
        "hujjat_id": hujjat["id"], "arava_raqam": 1, "tara": 1000, "brutto": 3000,
    }, headers=admin_headers)

    javob = client.put(f"/hujjatlar/{hujjat['id']}", json={
        "namlik": 0, "ifloslik": 0, "sabab": "Sinov natijasi qayta kiritildi",
    }, headers=admin_headers)
    assert javob.status_code == 200

    olchovlar = client.get(f"/olchovlar/{hujjat['id']}", headers=admin_headers).json()
    assert olchovlar[0]["konditsion"] == pytest.approx(konditsion_hisobla(2000, 0, 0))
    assert olchovlar[0]["konditsion"] is not None
