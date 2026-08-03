"""
POST /hujjatlar - hujjat yaratish: muvaffaqiyatli yaratish, mijoz_kaliti
orqali idempotentlik (offline-qayta-yuborish xavfsizligi), hujjat raqami
ketma-ket o'sishi, va noto'g'ri mahsulot/mashina ID rad etilishi.
"""


def test_hujjat_muvaffaqiyatli_yaratiladi(client, admin_headers, mahsulot_chigit, mashina):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id,
        "mashina_id": mashina.id,
    }, headers=admin_headers)
    assert javob.status_code == 200
    natija = javob.json()
    assert natija["mahsulot_id"] == mahsulot_chigit.id
    assert natija["mashina_id"] == mashina.id
    # Mashina ma'lumotlari (firma/shofyor/mashina_raqami) avtomatik ko'chirilishi kerak.
    assert natija["firma"] == mashina.firma
    assert natija["shofyor"] == mashina.shofyor
    assert natija["mashina_raqami"] == mashina.davlat_raqami
    assert natija["holat"] == "jarayon"
    assert natija["raqam"]


def test_hujjat_raqami_ketma_ket_osadi(client, admin_headers, mahsulot_chigit, mashina):
    javob1 = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
    }, headers=admin_headers)
    javob2 = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
    }, headers=admin_headers)
    raqam1 = javob1.json()["raqam"]
    raqam2 = javob2.json()["raqam"]
    assert raqam1 != raqam2
    # Format: PREFIKS-YIL/NNN - ikkinchisi birinchisidan bittaga katta bo'lishi kerak.
    tartib1 = int(raqam1.split("/")[-1])
    tartib2 = int(raqam2.split("/")[-1])
    assert tartib2 == tartib1 + 1


def test_mijoz_kaliti_orqali_idempotentlik(client, admin_headers, mahsulot_chigit, mashina):
    payload = {
        "mahsulot_id": mahsulot_chigit.id,
        "mashina_id": mashina.id,
        "mijoz_kaliti": "test-noyob-kalit-12345",
    }
    javob1 = client.post("/hujjatlar", json=payload, headers=admin_headers)
    javob2 = client.post("/hujjatlar", json=payload, headers=admin_headers)
    assert javob1.status_code == 200
    assert javob2.status_code == 200
    # Ikkinchi so'rov YANGI hujjat yaratmasligi, xuddi birinchisini
    # qaytarishi kerak (bir xil ID, bir xil raqam).
    assert javob1.json()["id"] == javob2.json()["id"]
    assert javob1.json()["raqam"] == javob2.json()["raqam"]


def test_notogri_mahsulot_id_rad_etiladi(client, admin_headers, mashina):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": 999999, "mashina_id": mashina.id,
    }, headers=admin_headers)
    assert javob.status_code == 404


def test_notogri_mashina_id_rad_etiladi(client, admin_headers, mahsulot_chigit):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": 999999,
    }, headers=admin_headers)
    assert javob.status_code == 404


def test_tokensiz_sorov_rad_etiladi(client, mahsulot_chigit, mashina):
    javob = client.post("/hujjatlar", json={
        "mahsulot_id": mahsulot_chigit.id, "mashina_id": mashina.id,
    })
    assert javob.status_code == 401
