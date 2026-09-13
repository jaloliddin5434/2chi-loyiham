"""
Tuzatish: /statistika/kunlik, /haftalik, /oylik, /mavsum avval TO'G'RIDAN-
TO'G'RI func.sum(Olchov.netto) ishlatar edi. Bitta arava uchun bir nechta
Olchov qatori bo'lishi ODATIY holat (operator avval faqat TARA saqlaydi,
keyin xuddi shu arava_raqam bilan TARA+BRUTTO+NETTO qatorini qo'shadi) -
eski kod bunday holatda netto'ni IKKI MARTA hisoblardi.

To'g'ri mantiq (_olchovlar_jamlangan() bilan bir xil, Excel jurnali va
Nakladnoy'da ham shu ishlatiladi): har (hujjat, arava_raqam) juftligi
uchun FAQAT eng oxirgi (id bo'yicha) NULL bo'lmagan netto/konditsion
qiymati olinadi, SO'NGRA aravalar bo'yicha yig'iladi.

Bu fayl _mahsulot_bosim_statistikasi() ni (main.py) shu 4 endpoint orqali
sinaydi.
"""
from datetime import datetime

import pytest

from models import Hujjat, Olchov, HujjatHolati, Mahsulot
from utils import konditsion_hisobla


@pytest.fixture()
def chigit1(db_session):
    """statistika/kunlik javobidagi mahsulot_id=1 -> "chigit" kaliti bilan
    qattiq bog'langan - shu sabab id ATAYLAB 1 qilib yaratiladi."""
    m = Mahsulot(id=1, nom="Chigit", konditsiya_bor=True, is_active=True)
    db_session.add(m)
    db_session.commit()
    return m


def _hujjat_yarat(db_session, mahsulot_id, raqam, holat=HujjatHolati.TUGALLANDI):
    h = Hujjat(mahsulot_id=mahsulot_id, raqam=raqam, holat=holat,
               firma="Real Firma", shofyor="Real Shofyor", created_at=datetime.now())
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


_ENDPOINTLAR = ["/statistika/kunlik", "/statistika/haftalik", "/statistika/oylik", "/statistika/mavsum"]


def _hammasini_tekshir(client, admin_headers, kutilgan_tonnaj, kutilgan_soni=1, kutilgan_konditsion=None):
    for yol in _ENDPOINTLAR:
        j = client.get(yol, headers=admin_headers).json()
        assert j["jami_tonnaj"] == pytest.approx(kutilgan_tonnaj), f"{yol}: jami_tonnaj noto'g'ri"
        assert j["chigit"]["tonnaj"] == pytest.approx(kutilgan_tonnaj), f"{yol}: chigit.tonnaj noto'g'ri"
        assert j["chigit"]["soni"] == kutilgan_soni, f"{yol}: chigit.soni noto'g'ri"
        if kutilgan_konditsion is not None:
            assert j["chigit"]["konditsion"] == pytest.approx(kutilgan_konditsion), f"{yol}: konditsion noto'g'ri"


# ---------- Asosiy xato: bitta arava, ikkita qator ----------

def test_bitta_arava_ikkita_qator_netto_ikki_marta_hisoblanmaydi(
        client, admin_headers, db_session, chigit1):
    """Operator avval TARA saqlaydi (netto=None), keyin xuddi shu
    arava_raqam=1 bilan TARA+BRUTTO+NETTO qatorini qo'shadi. jami_tonnaj
    faqat OXIRGI qatordagi netto (5000 kg = 5.0 t) bo'lishi kerak, 5000
    ikki marta qo'shilib 10.0 bo'lmasligi kerak."""
    h = _hujjat_yarat(db_session, chigit1.id, "AR-1")
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000)
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000, brutto=23000, netto=5000)

    _hammasini_tekshir(client, admin_headers, kutilgan_tonnaj=5.0, kutilgan_soni=1)


def test_bitta_arava_uchta_tuzatish_qatori_faqat_oxirgisi_hisoblanadi(
        client, admin_headers, db_session, chigit1):
    """Netto ketma-ket 2 marta tuzatilsa (masalan qayta o'lchash) - faqat
    ENG OXIRGI (id bo'yicha) qiymat hisobga olinishi kerak."""
    h = _hujjat_yarat(db_session, chigit1.id, "AR-2")
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000)
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000, brutto=22000, netto=4000)
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000, brutto=23500, netto=5500)

    _hammasini_tekshir(client, admin_headers, kutilgan_tonnaj=5.5, kutilgan_soni=1)


def test_oxirgi_qator_netto_null_bolsa_avvalgi_qiymat_saqlanadi(
        client, admin_headers, db_session, chigit1):
    """Agar arava uchun keyingi qator faqat boshqa maydonni (masalan
    namlik) yangilasa va netto'ni NULL qoldirsa - avvalgi NULL bo'lmagan
    netto yo'qolib ketmasligi kerak (_olchovlar_jamlangan mantiqi:
    NULL qiymat oldingi qiymatni ustidan yozmaydi)."""
    h = _hujjat_yarat(db_session, chigit1.id, "AR-3")
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000, brutto=24000, netto=6000)
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000, brutto=24000, netto=None, namlik=9.0)

    _hammasini_tekshir(client, admin_headers, kutilgan_tonnaj=6.0, kutilgan_soni=1)


# ---------- Bir nechta HAQIQIY arava - to'g'ri yig'ilishi kerak ----------

def test_ikkita_haqiqiy_arava_togri_qoshiladi(client, admin_headers, db_session, chigit1):
    """Ikki xil arava_raqam (haqiqiy ikki arava) - bular takrorlanish
    EMAS, ikkalasi ham yig'indiga qo'shilishi kerak."""
    h = _hujjat_yarat(db_session, chigit1.id, "AR-4")
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000, brutto=23000, netto=5000)
    _olchov_qosh(db_session, h.id, arava_raqam=2, tara=17000, brutto=21000, netto=4000)

    _hammasini_tekshir(client, admin_headers, kutilgan_tonnaj=9.0, kutilgan_soni=1)


def test_ikkita_hujjat_har_biri_takroriy_qator_bilan(client, admin_headers, db_session, chigit1):
    """Ikkita ALOHIDA hujjat, ikkalasida ham o'z arava_raqam=1 uchun
    takroriy qator bor - har hujjat mustaqil deduplikatsiya qilinishi
    va ikkalasi ham yig'indiga (dedup qilingan holda) qo'shilishi kerak."""
    h1 = _hujjat_yarat(db_session, chigit1.id, "AR-5A")
    _olchov_qosh(db_session, h1.id, arava_raqam=1, tara=18000)
    _olchov_qosh(db_session, h1.id, arava_raqam=1, tara=18000, brutto=23000, netto=5000)

    h2 = _hujjat_yarat(db_session, chigit1.id, "AR-5B")
    _olchov_qosh(db_session, h2.id, arava_raqam=1, tara=17000)
    _olchov_qosh(db_session, h2.id, arava_raqam=1, tara=17000, brutto=20000, netto=3000)

    _hammasini_tekshir(client, admin_headers, kutilgan_tonnaj=8.0, kutilgan_soni=2)


# ---------- Konditsion ham xuddi shu mantiq bilan hisoblanishi kerak ----------

def test_konditsion_ham_ikki_marta_hisoblanmaydi(client, admin_headers, db_session, chigit1):
    h = _hujjat_yarat(db_session, chigit1.id, "AR-6")
    netto = 5000
    k = konditsion_hisobla(netto, 8.0, 2.0)
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000)
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000, brutto=23000, netto=netto,
                 namlik=8.0, ifloslik=2.0, konditsion=k)

    _hammasini_tekshir(client, admin_headers, kutilgan_tonnaj=5.0, kutilgan_soni=1,
                        kutilgan_konditsion=round(k / 1000, 2))


# ---------- Chegara holatlar ----------

def test_arava_faqat_tara_bolsa_statistikaga_kirmaydi(client, admin_headers, db_session, chigit1):
    """Butun hujjatda faqat TARA (netto hech qachon kiritilmagan) -
    hujjat statistikaga umuman kirmasligi kerak (na soni, na tonnaj)."""
    h = _hujjat_yarat(db_session, chigit1.id, "AR-7")
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000)

    for yol in _ENDPOINTLAR:
        j = client.get(yol, headers=admin_headers).json()
        assert j["jami_tonnaj"] == 0.0, f"{yol}"
        assert j["chigit"]["soni"] == 0, f"{yol}"


def test_bitta_arava_takroriy_qator_netto_manfiy_yoki_nol_bolsa_statistikaga_kirmaydi(
        client, admin_headers, db_session, chigit1):
    """Oxirgi (eng dolzarb) netto qiymati <= 0 bo'lsa - avvalgi qatorda
    musbat netto bo'lgan taqdirda ham hujjat statistikaga KIRMASLIGI
    kerak, chunki faqat ENG OXIRGI qiymat haqiqiy hisoblanadi."""
    h = _hujjat_yarat(db_session, chigit1.id, "AR-8")
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000, brutto=23000, netto=5000)
    _olchov_qosh(db_session, h.id, arava_raqam=1, tara=18000, brutto=18000, netto=0)

    for yol in _ENDPOINTLAR:
        j = client.get(yol, headers=admin_headers).json()
        assert j["jami_tonnaj"] == 0.0, f"{yol}"
        assert j["chigit"]["soni"] == 0, f"{yol}"
