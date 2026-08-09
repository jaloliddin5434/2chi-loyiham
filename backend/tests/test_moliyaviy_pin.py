"""
Moliyaviy PIN - o'rnatish (birinchi marta va eski PIN bilan), tekshirish,
tezlik cheklovi, va PIN xeshi hech qanday umumiy endpoint orqali
sizib chiqmasligi.

DIQQAT: /moliyaviy/pin va /moliyaviy/pin-tekshir 5/daqiqa tezlik
cheklovi bilan himoyalangan (qarang: main.py). Shu sabab HAR BIR test
o'ziga xos CF-Connecting-IP qiymati bilan so'rov yuboradi - aks holda
testlar bir-biriga aralashib (umumiy IP-hisoblagichni bo'lishib),
ijro tartibiga qarab beqaror natija berardi (xuddi test_login.py'dagi
kabi sabab).
"""
import uuid


def _headers(admin_headers):
    ip = f"10.77.{uuid.uuid4().fields[0] % 255}.{uuid.uuid4().fields[1] % 255}"
    return {**admin_headers, "CF-Connecting-IP": ip}


def test_birinchi_marta_pin_ornatish_eski_pinsiz_ishlaydi(client, admin_headers):
    javob = client.put("/moliyaviy/pin", json={"yangi_pin": "1234"},
                        headers=_headers(admin_headers))
    assert javob.status_code == 200


def test_toliq_oqim_pin_ornatish_va_tekshirish(client, admin_headers):
    h = _headers(admin_headers)
    client.put("/moliyaviy/pin", json={"yangi_pin": "1111"}, headers=h)
    javob = client.post("/moliyaviy/pin-tekshir", json={"pin": "1111"}, headers=h)
    assert javob.status_code == 200
    assert "moliyaviy_token" in javob.json()


def test_xato_pin_rad_etiladi(client, admin_headers):
    h = _headers(admin_headers)
    client.put("/moliyaviy/pin", json={"yangi_pin": "2222"}, headers=h)
    javob = client.post("/moliyaviy/pin-tekshir", json={"pin": "9999"}, headers=h)
    assert javob.status_code == 401


def test_pin_ornatilmagan_bolsa_tekshirish_rad_etiladi(client, admin_headers):
    javob = client.post("/moliyaviy/pin-tekshir", json={"pin": "1234"},
                         headers=_headers(admin_headers))
    assert javob.status_code == 400


def test_eski_pinsiz_ozgartirish_rad_etiladi(client, admin_headers):
    h = _headers(admin_headers)
    client.put("/moliyaviy/pin", json={"yangi_pin": "3333"}, headers=h)
    # Endi PIN mavjud - eski_pin ko'rsatmasdan qayta o'rnatishga urinish
    # RAD ETILISHI kerak (aks holda himoya butunlay chetlab o'tiladi).
    javob = client.put("/moliyaviy/pin", json={"yangi_pin": "4444"}, headers=h)
    assert javob.status_code == 401


def test_xato_eski_pin_bilan_ozgartirish_rad_etiladi(client, admin_headers):
    h = _headers(admin_headers)
    client.put("/moliyaviy/pin", json={"yangi_pin": "5555"}, headers=h)
    javob = client.put("/moliyaviy/pin", json={
        "eski_pin": "0000", "yangi_pin": "6666",
    }, headers=h)
    assert javob.status_code == 401


def test_togri_eski_pin_bilan_ozgartirish_ishlaydi(client, admin_headers):
    h = _headers(admin_headers)
    client.put("/moliyaviy/pin", json={"yangi_pin": "7777"}, headers=h)
    javob = client.put("/moliyaviy/pin", json={
        "eski_pin": "7777", "yangi_pin": "8888",
    }, headers=h)
    assert javob.status_code == 200
    # Yangi PIN endi ishlashi, eskisi ishlamasligi kerak.
    assert client.post("/moliyaviy/pin-tekshir", json={"pin": "8888"},
                        headers=h).status_code == 200
    assert client.post("/moliyaviy/pin-tekshir", json={"pin": "7777"},
                        headers=h).status_code == 401


def test_4_xonadan_boshqa_pin_rad_etiladi(client, admin_headers):
    h = _headers(admin_headers)
    javob = client.put("/moliyaviy/pin", json={"yangi_pin": "123"}, headers=h)
    assert javob.status_code == 422
    javob2 = client.put("/moliyaviy/pin", json={"yangi_pin": "abcd"}, headers=h)
    assert javob2.status_code == 422


def test_operator_pin_ornata_olmaydi(client, operator_headers):
    ip = f"10.77.{uuid.uuid4().fields[0] % 255}.{uuid.uuid4().fields[1] % 255}"
    javob = client.put("/moliyaviy/pin", json={"yangi_pin": "1234"},
                        headers={**operator_headers, "CF-Connecting-IP": ip})
    assert javob.status_code == 403


def test_pin_xeshi_sozlamalar_orqali_sizib_chiqmaydi(client, admin_headers):
    h = _headers(admin_headers)
    client.put("/moliyaviy/pin", json={"yangi_pin": "1234"}, headers=h)
    javob = client.get("/sozlamalar", headers=h)
    assert "moliyaviy_pin_hash" not in javob.json()


def test_pin_umumiy_sozlamalar_orqali_ozgartirib_bolmaydi(client, admin_headers):
    # Bu MUHIM xavfsizlik testi: umumiy POST /sozlamalar orqali PIN
    # xeshini to'g'ridan-to'g'ri (xesh tekshiruvisiz) yozib bo'lmasligi
    # kerak - aks holda /moliyaviy/pin'dagi "eski PIN talab qilinadi"
    # himoyasi butunlay chetlab o'tiladi.
    h = _headers(admin_headers)
    client.put("/moliyaviy/pin", json={"yangi_pin": "1234"}, headers=h)
    javob = client.post("/sozlamalar", json={"moliyaviy_pin_hash": "xakerlik"}, headers=h)
    assert javob.status_code == 400
    # Asl PIN hali ham ishlashi kerak (o'zgarmagan).
    assert client.post("/moliyaviy/pin-tekshir", json={"pin": "1234"},
                        headers=h).status_code == 200


def test_pin_tekshir_tezlik_cheklovi(client, admin_headers):
    h = _headers(admin_headers)
    client.put("/moliyaviy/pin", json={"yangi_pin": "1234"}, headers=h)
    for _ in range(5):
        javob = client.post("/moliyaviy/pin-tekshir", json={"pin": "0000"}, headers=h)
        assert javob.status_code == 401
    javob = client.post("/moliyaviy/pin-tekshir", json={"pin": "0000"}, headers=h)
    assert javob.status_code == 429
