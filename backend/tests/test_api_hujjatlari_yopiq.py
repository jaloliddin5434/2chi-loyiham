"""Avval /docs, /redoc, /openapi.json production'da ham hech qanday
to'sqichsiz ochiq edi - butun API sxemasi har kimga ko'rinardi.
API_HUJJATLARI_OCHIQ standart qiymati False, shu sabab bu sahifalar
standart holatda yopiq bo'lishi kerak.
"""


def test_docs_standart_holatda_yopiq(client):
    javob = client.get("/docs")
    assert javob.status_code == 404


def test_redoc_standart_holatda_yopiq(client):
    javob = client.get("/redoc")
    assert javob.status_code == 404


def test_openapi_json_standart_holatda_yopiq(client):
    javob = client.get("/openapi.json")
    assert javob.status_code == 404
