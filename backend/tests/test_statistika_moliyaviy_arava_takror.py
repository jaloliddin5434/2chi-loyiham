"""
Tuzatish: GET /statistika/firmalar, GET /statistika/haydovchilar va
GET /moliyaviy/hisobot avval TO'G'RIDAN-TO'G'RI func.sum(Olchov.netto)/
func.sum(Olchov.konditsion) ishlatar edi. Bitta arava uchun bir nechta
Olchov qatori bo'lishi ODATIY holat (operator avval faqat TARA saqlaydi,
keyin xuddi shu arava_raqam bilan TARA+BRUTTO+NETTO qatorini qo'shadi,
yoki tozalanmagan tarixiy takrorlanish bo'lishi mumkin) - eski kod
bunday holatda netto/konditsion'ni IKKI MARTA hisoblardi.

To'g'ri mantiq (_olchovlar_jamlangan() bilan bir xil, Excel jurnali,
Nakladnoy va _mahsulot_bosim_statistikasi'da ham shu ishlatiladi): har
(hujjat, arava_raqam) juftligi uchun FAQAT eng oxirgi (id bo'yicha) NULL
bo'lmagan netto/konditsion qiymati olinadi, SO'NGRA aravalar/hujjatlar
bo'yicha yig'iladi.

Bu fayl main.py'dagi _firma_haydovchi_statistikasi() (firmalar/
haydovchilar) va moliyaviy_hisobot() endpointining tuzatilgan
hisoblashini sinaydi.
"""
from datetime import datetime

from models import Hujjat, Olchov, HujjatHolati
from utils import konditsion_hisobla


def _hujjat_yarat(db_session, mahsulot_id, raqam, firma="Real Firma",
                   shofyor="Real Shofyor", holat=HujjatHolati.TUGALLANDI):
    h = Hujjat(mahsulot_id=mahsulot_id, raqam=raqam, holat=holat,
               firma=firma, shofyor=shofyor, created_at=datetime.now())
    db_session.add(h)
    db_session.flush()
    return h


def _olchov_qosh(db_session, hujjat_id, arava_raqam, tara=None, brutto=None,
                  netto=None, namlik=None, ifloslik=None, konditsion=None):
    o = Olchov(hujjat_id=hujjat_id, arava_raqam=arava_raqam, tara=tara,
               brutto=brutto, netto=netto, namlik=namlik, ifloslik=ifloslik,
               konditsion=konditsion)
    db_session.add(o)
    db_session.commit()
    return o


# ---------- /statistika/firmalar ----------

def test_firmalar_arava_takror_hisoblanmaydi(client, admin_headers, db_session, mahsulot_chigit):
    """Bitta arava_raqam=1 uchun IKKITA qator, ikkalasida ham netto>0
    (masalan qayta o'lchash/tuzatish natijasida) - ikkalasi ham
    Olchov.netto>0 filtridan o'tadi, shu sabab xom SQL SUM ularni
    QO'SHIB YUBORARDI (4000+5000=9000). To'g'ri natija faqat ENG
    OXIRGI (id bo'yicha) qiymat - 5000 kg = 5.0 t bo'lishi kerak."""
    h = _hujjat_yarat(db_session, mahsulot_chigit.id, "FRM-TAKROR-1", firma="Takror Firma")
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000, brutto=22000, netto=4000)
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000, brutto=23000, netto=5000)

    natija = client.get("/statistika/firmalar", headers=admin_headers).json()["firmalar"]
    firma = next(f for f in natija if f["nom"] == "Takror Firma")
    assert firma["jami_tonnaj"] == 5.0
    assert firma["soni"] == 1


def test_firmalar_konditsion_arava_takror_hisoblanmaydi(client, admin_headers, db_session, mahsulot_chigit):
    """ortacha_konditsion/jami_konditsion ham xuddi shu takroriy-qator
    xatosidan aziyat chekmasligi kerak."""
    h = _hujjat_yarat(db_session, mahsulot_chigit.id, "FRM-TAKROR-2", firma="Konditsion Firma")
    netto, namlik, ifloslik = 5000, 8.0, 2.0
    k = konditsion_hisobla(netto, namlik, ifloslik)
    k_eski = konditsion_hisobla(4000, namlik, ifloslik)
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000, brutto=22000, netto=4000,
                 namlik=namlik, ifloslik=ifloslik, konditsion=k_eski)
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000, brutto=23000, netto=netto,
                 namlik=namlik, ifloslik=ifloslik, konditsion=k)

    natija = client.get("/statistika/firmalar", headers=admin_headers).json()["firmalar"]
    firma = next(f for f in natija if f["nom"] == "Konditsion Firma")
    assert firma["jami_konditsion"] == round(k / 1000, 2)


def test_firmalar_ikkita_haqiqiy_arava_togri_qoshiladi(client, admin_headers, db_session, mahsulot_chigit):
    """Ikki xil arava_raqam (haqiqiy ikki arava) - bular takrorlanish
    EMAS, ikkalasi ham yig'indiga qo'shilishi kerak (tuzatish
    UNDER-count qilib qo'ymasligi kerak)."""
    h = _hujjat_yarat(db_session, mahsulot_chigit.id, "FRM-2ARAVA", firma="Ikki Arava Firma")
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000, brutto=23000, netto=5000)
    _olchov_qosh(db_session, h.id, arava_raqam=2, tara=17000, brutto=21000, netto=4000)

    natija = client.get("/statistika/firmalar", headers=admin_headers).json()["firmalar"]
    firma = next(f for f in natija if f["nom"] == "Ikki Arava Firma")
    assert firma["jami_tonnaj"] == 9.0
    assert firma["soni"] == 1


# ---------- /statistika/haydovchilar ----------

def test_haydovchilar_arava_takror_hisoblanmaydi(client, admin_headers, db_session, mahsulot_chigit):
    """Xuddi test_firmalar_arava_takror_hisoblanmaydi kabi - ikkita
    netto>0 qator, faqat OXIRGISI hisoblanishi kerak."""
    h = _hujjat_yarat(db_session, mahsulot_chigit.id, "HYD-TAKROR-1", shofyor="Takror Haydovchi")
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000, brutto=22000, netto=4000)
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000, brutto=23000, netto=5000)

    natija = client.get("/statistika/haydovchilar", headers=admin_headers).json()["haydovchilar"]
    haydovchi = next(x for x in natija if x["nom"] == "Takror Haydovchi")
    assert haydovchi["jami_tonnaj"] == 5.0
    assert haydovchi["soni"] == 1


# ---------- /moliyaviy/hisobot ----------

def test_moliyaviy_hisobot_netto_arava_takror_hisoblanmaydi(
        client, admin_headers, moliyaviy_headers, db_session, mahsulot_chiganoq):
    """Chiganoq - konditsiya_bor=False, hisobot netto asosida. Ikkita
    netto>0 qator (masalan qayta o'lchash) - faqat ENG OXIRGISI
    hisoblanishi kerak, ikkalasi qo'shilib ketmasligi kerak."""
    client.post(f"/mahsulotlar/{mahsulot_chiganoq.id}/narx", json={"narx": 2000},
                headers=moliyaviy_headers)
    h = _hujjat_yarat(db_session, mahsulot_chiganoq.id, "MOL-TAKROR-1")
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=1000, brutto=3000, netto=2000)
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=1000, brutto=4000, netto=3000)

    natija = client.get("/moliyaviy/hisobot?davr=kunlik", headers=moliyaviy_headers).json()
    chiganoq = next(m for m in natija["mahsulotlar"] if m["mahsulot_id"] == mahsulot_chiganoq.id)
    assert chiganoq["jami_kg"] == 3000
    assert chiganoq["daromad"] == 3000 * 2000


def test_moliyaviy_hisobot_konditsion_arava_takror_hisoblanmaydi(
        client, admin_headers, moliyaviy_headers, db_session, mahsulot_chigit):
    """Chigit - konditsiya_bor=True, hisobot konditsion asosida. Ikkita
    konditsion>0 qator - faqat ENG OXIRGISI hisoblanishi kerak."""
    client.post(f"/mahsulotlar/{mahsulot_chigit.id}/narx", json={"narx": 5000},
                headers=moliyaviy_headers)
    namlik, ifloslik = 5.0, 3.0
    k_eski = konditsion_hisobla(1000, namlik, ifloslik)
    netto = 2000
    k = konditsion_hisobla(netto, namlik, ifloslik)
    h = _hujjat_yarat(db_session, mahsulot_chigit.id, "MOL-TAKROR-2")
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=1000, brutto=2000, netto=1000,
                 namlik=namlik, ifloslik=ifloslik, konditsion=k_eski)
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=1000, brutto=3000, netto=netto,
                 namlik=namlik, ifloslik=ifloslik, konditsion=k)

    natija = client.get("/moliyaviy/hisobot?davr=kunlik", headers=moliyaviy_headers).json()
    chigit = next(m for m in natija["mahsulotlar"] if m["mahsulot_id"] == mahsulot_chigit.id)
    assert chigit["jami_kg"] == round(k, 2)
    assert chigit["daromad"] == round(k * 5000, 2)


def test_moliyaviy_hisobot_ikkita_haqiqiy_arava_togri_qoshiladi(
        client, admin_headers, moliyaviy_headers, db_session, mahsulot_chiganoq):
    """Ikki xil arava_raqam - haqiqiy ikki arava, tuzatish bularni
    UNDER-count qilib qo'ymasligi kerak."""
    client.post(f"/mahsulotlar/{mahsulot_chiganoq.id}/narx", json={"narx": 1000},
                headers=moliyaviy_headers)
    h = _hujjat_yarat(db_session, mahsulot_chiganoq.id, "MOL-2ARAVA")
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=1000, brutto=3000, netto=2000)
    _olchov_qosh(db_session, h.id, arava_raqam=2, tara=900, brutto=2900, netto=2000)

    natija = client.get("/moliyaviy/hisobot?davr=kunlik", headers=moliyaviy_headers).json()
    chiganoq = next(m for m in natija["mahsulotlar"] if m["mahsulot_id"] == mahsulot_chiganoq.id)
    assert chiganoq["jami_kg"] == 4000
    assert chiganoq["daromad"] == 4000 * 1000
