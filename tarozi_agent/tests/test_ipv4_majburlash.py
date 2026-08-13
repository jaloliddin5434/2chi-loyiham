"""tarozi_agent.py'da IPv4'ni majburlash mexanizmini (_IPv4HTTPAdapter,
_ipv4_sessiyasi) sinaydi. Real productionda (2026-08-13, tarozixona
kompyuteri) SERVER_URL domen orqali (Cloudflare Tunnel) ishlaydi va IPv6
orqali ulanish urinishlari doimiy "Read timed out" xatosiga sabab bo'lgan -
Windows tarmoq sozlamalarida IPv6'ni o'chirish YETARLI BO'LMAGAN (ilova
baribir IPv6 manzilini sinab ko'raverardi). Shu sabab tuzatish kodning
o'zida, Windows sozlamalaridan mustaqil bo'lishi shart.

Bu yerda HAQIQIY (mock qilinmagan) mahalliy HTTP server ko'tarilib, unga
_ipv4_sessiyasi orqali haqiqiy so'rov yuboriladi - faqat DNS oila
tanlovining o'zi (`socket.getaddrinfo`ga qaysi `family` argumenti
uzatilgani) kuzatiladi, chunki mahalliy dev mashinada IPv6 DNS yozuvlari
(AAAA) umuman yo'q (tekshirildi) - ya'ni bu yerda "IPv6 tanlanmadi"ni
faqat shu tarzda ishonchli tasdiqlash mumkin."""
import http.server
import socket
import sys
import threading
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import tarozi_agent as ta


class _OddiyHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, format, *args):
        pass  # test chiqishini chalkashtirmaslik uchun


def test_ipv4_sessiyasi_faqat_af_inet_bilan_dns_soraydi():
    """_ipv4_sessiyasi orqali yuborilgan HAQIQIY so'rov, DNS so'rovining
    o'zida (`socket.getaddrinfo`) FAQAT AF_INET oilasini so'rashini
    tasdiqlaydi (AF_UNSPEC emas) - bu aynan IPv6 sinab ko'rilishining
    oldini oluvchi mexanizm."""
    server = http.server.HTTPServer(("127.0.0.1", 0), _OddiyHandler)
    port = server.server_address[1]
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()

    haqiqiy_getaddrinfo = socket.getaddrinfo
    chaqirilgan_oilalar = []

    def kuzatuvchi_getaddrinfo(host, port_, family=0, *args, **kwargs):
        if host == "127.0.0.1":
            chaqirilgan_oilalar.append(family)
        return haqiqiy_getaddrinfo(host, port_, family, *args, **kwargs)

    try:
        socket.getaddrinfo = kuzatuvchi_getaddrinfo
        javob = ta._ipv4_sessiyasi.get(f"http://127.0.0.1:{port}/", timeout=5)
        assert javob.status_code == 200
        assert javob.content == b"ok"
    finally:
        socket.getaddrinfo = haqiqiy_getaddrinfo
        server.shutdown()
        thread.join(timeout=2)

    assert chaqirilgan_oilalar, "getaddrinfo hech qachon chaqirilmadi"
    assert all(oila == socket.AF_INET for oila in chaqirilgan_oilalar), (
        f"Kutilmagan DNS oilasi so'raldi: {chaqirilgan_oilalar} "
        f"(AF_INET={socket.AF_INET} bo'lishi kerak edi)"
    )


def test_ipv4_adapter_montaj_qilinganda_global_qulf_qoyiladi():
    """Modul import qilinishi bilanoq (`_ipv4_sessiyasi.mount(...)` orqali)
    urllib3'ning `allowed_gai_family` funksiyasi AF_INET'ni qaytaradigan
    holatga almashtirilganini tasdiqlaydi - bu butun jarayon uchun
    (Telegramga ham, serverga ham) amal qiladi."""
    assert ta._urllib3_ulanish.allowed_gai_family() == socket.AF_INET


def test_telegram_va_server_sorovlari_bir_xil_ipv4_sessiyasidan_foydalanadi():
    """Kelajakda kimdir _telegram_xabar_yuborish yoki _serverga_yuboruvchi
    ichida qaytadan bevosita `requests.post`/`requests.Session()` ishlatib
    qo'ymasligini (va shu bilan IPv4-majburlashni chetlab o'tib
    qo'ymasligini) nazorat qilish uchun manba kodini tekshiradi."""
    manba = Path(ta.__file__).read_text(encoding="utf-8")
    assert "_ipv4_sessiyasi.post(" in manba
    assert "sessiya = _ipv4_sessiyasi" in manba
