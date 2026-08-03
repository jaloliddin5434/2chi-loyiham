"""
POST /mashinalar - davlat_raqami bo'yicha "topilsa qaytar, topilmasa
yarat" (idempotentlik), va shu bilan birga yangi firma nomining Firma
ro'yxatiga (katta-kichik harf/probelga sezgir bo'lmagan holda,
dublikatsiz) avtomatik qo'shilishi.
"""


def test_mashina_davlat_raqami_boyicha_idempotent(client, admin_headers):
    payload = {
        "davlat_raqami": "TEST01AA", "turi": "FAW", "shofyor": "Shofyor A",
        "firma": "Noyob Firma Nomi", "viloyat": "Xorazm",
    }
    javob1 = client.post("/mashinalar", json=payload, headers=admin_headers)
    javob2 = client.post("/mashinalar", json=payload, headers=admin_headers)
    assert javob1.status_code == 200
    assert javob2.status_code == 200
    # Ikkinchi so'rov YANGI mashina yaratmasligi, mavjudini qaytarishi kerak.
    assert javob1.json()["id"] == javob2.json()["id"]


def test_yangi_firma_avtomatik_royxatga_qoshiladi(client, admin_headers):
    client.post("/mashinalar", json={
        "davlat_raqami": "TEST02BB", "turi": "FAW", "shofyor": "Shofyor B",
        "firma": "Avtomatik Qoshilgan Firma", "viloyat": "Xorazm",
    }, headers=admin_headers)
    javob = client.get("/firmalar", headers=admin_headers)
    nomlar = [f["nom"] for f in javob.json()]
    assert "Avtomatik Qoshilgan Firma" in nomlar


def test_firma_katta_kichik_harf_bilan_dublikat_bolmaydi(client, admin_headers):
    client.post("/mashinalar", json={
        "davlat_raqami": "TEST03CC", "turi": "FAW", "shofyor": "Shofyor C",
        "firma": "Registr Sinovi", "viloyat": "Xorazm",
    }, headers=admin_headers)
    client.post("/mashinalar", json={
        "davlat_raqami": "TEST04DD", "turi": "FAW", "shofyor": "Shofyor D",
        "firma": " registr sinovi ", "viloyat": "Xorazm",
    }, headers=admin_headers)
    javob = client.get("/firmalar", headers=admin_headers)
    nomlar = [f["nom"].lower() for f in javob.json()]
    assert nomlar.count("registr sinovi") == 1


def test_firma_qoshish_admin_talab_qiladi(client, operator_headers):
    javob = client.post("/firmalar", json={"nom": "Operator Ura Olmaydi"},
                         headers=operator_headers)
    assert javob.status_code == 403


def test_firma_mavjud_nom_409_qaytaradi(client, admin_headers):
    client.post("/firmalar", json={"nom": "Dublikat Test Firma"}, headers=admin_headers)
    javob = client.post("/firmalar", json={"nom": "Dublikat Test Firma"}, headers=admin_headers)
    assert javob.status_code == 409
