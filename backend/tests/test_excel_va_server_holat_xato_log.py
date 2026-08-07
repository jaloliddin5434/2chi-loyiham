"""Ikkita kamchilikni tekshiradi:
1. excel_qatorga_yoz() ichida xato chiqsa, endi tizim_xatosini_saqla()ga
   yoziladi (avval faqat print() qilinardi, admin panelidagi "Tizim
   xatolari" bo'limida ko'rinmasdi).
2. GET /server/holat xato bo'lsa, endi log qilinadi (avval jim-jit
   nol qiymat qaytarardi).
"""
from unittest.mock import patch


def test_excel_xatosi_tizim_xatolariga_yoziladi(db_session, mahsulot_chigit, mashina):
    import main
    from models import Hujjat

    hujjat = Hujjat(mahsulot_id=mahsulot_chigit.id, mashina_id=mashina.id,
                     raqam="TEST-001", holat="jarayon")
    db_session.add(hujjat)
    db_session.commit()
    db_session.refresh(hujjat)

    with patch("main._oy_jurnal_malumotlarini_ol", side_effect=RuntimeError("sun'iy xato")), \
         patch("main.tizim_xatosini_saqla") as mock_saqla:
        # Funksiya xatoni ICHKI ushlaydi - tashqariga otilmasligi kerak.
        main.excel_qatorga_yoz(hujjat.id, db_session)

    mock_saqla.assert_called_once()
    args = mock_saqla.call_args[0]
    assert args[0] == "excel"
    assert "sun'iy xato" in args[1]


def test_server_holat_xatosi_log_qilinadi(client, admin_headers):
    import main
    with patch("main.psutil.cpu_percent", side_effect=RuntimeError("psutil sun'iy xato")), \
         patch("main.tizim_xatosini_saqla") as mock_saqla:
        javob = client.get("/server/holat", headers=admin_headers)

    assert javob.status_code == 200
    natija = javob.json()
    assert natija == {"cpu": 0, "ram": 0, "disk": 0, "uptime": "—"}
    mock_saqla.assert_called_once()
    assert mock_saqla.call_args[0][0] == "server_holat"
