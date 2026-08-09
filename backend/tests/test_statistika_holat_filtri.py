"""4-band (2-qism): kunlik/haftalik/oylik/mavsum statistikasi FAQAT
"tugallandi" holatidagi hujjatlarni hisoblashi kerak - "jarayon"
(hali tugallanmagan) va "bekor" hujjatlarning netto/konditsion
qiymati jami tonnajga qo'shilib ketmasligi kerak. Avval bu 4
endpointning tonnaj/konditsion agregatsiyasida umuman holat filtri
yo'q edi - shu sabab jarayondagi (ba'zan sinov/noaniq) qiymatlar ham
statistikaga aralashib ketardi."""
from datetime import datetime

from models import Hujjat, Olchov, HujjatHolati
from utils import konditsion_hisobla


def _hujjat_qosh(db_session, mahsulot_id, netto, holat, raqam):
    h = Hujjat(mahsulot_id=mahsulot_id, raqam=raqam, holat=holat,
                created_at=datetime.now())
    db_session.add(h)
    db_session.flush()
    tara, brutto = 18000, 18000 + netto
    konditsion = konditsion_hisobla(netto, 8.0, 2.0)
    db_session.add(Olchov(hujjat_id=h.id, arava_raqam=1, tara=tara, brutto=brutto,
                           netto=netto, namlik=8.0, ifloslik=2.0, konditsion=konditsion))
    db_session.commit()
    return h.id


def _davr_endpointlari():
    return ["/statistika/kunlik", "/statistika/haftalik", "/statistika/oylik", "/statistika/mavsum"]


def test_jarayondagi_hujjat_davriy_statistikaga_kirmaydi(client, admin_headers, db_session, mahsulot_chigit):
    _hujjat_qosh(db_session, mahsulot_chigit.id, 7000, HujjatHolati.TUGALLANDI, "HLT-TUG-1")
    _hujjat_qosh(db_session, mahsulot_chigit.id, 5000, HujjatHolati.JARAYON, "HLT-JAR-1")

    for yol in _davr_endpointlari():
        javob = client.get(yol, headers=admin_headers)
        assert javob.status_code == 200
        assert javob.json()["jami_tonnaj"] == 7.0, (
            f"{yol}: jarayondagi hujjatning netto'si jami tonnajga qo'shilib ketmasligi kerak edi"
        )


def test_bekor_qilingan_hujjat_davriy_statistikaga_kirmaydi(client, admin_headers, db_session, mahsulot_chigit):
    _hujjat_qosh(db_session, mahsulot_chigit.id, 6000, HujjatHolati.TUGALLANDI, "HLT-TUG-2")
    _hujjat_qosh(db_session, mahsulot_chigit.id, 9000, HujjatHolati.BEKOR_QILINDI, "HLT-BEK-1")

    for yol in _davr_endpointlari():
        javob = client.get(yol, headers=admin_headers)
        assert javob.status_code == 200
        assert javob.json()["jami_tonnaj"] == 6.0, (
            f"{yol}: bekor qilingan hujjatning netto'si jami tonnajga qo'shilib ketmasligi kerak edi"
        )


def test_mashinalar_soni_holatidan_qatiy_nazar_hammasini_sanaydi(client, admin_headers, db_session, mahsulot_chigit):
    """mashinalar_soni/tugallanganlar_soni/bekor_soni - holat boyicha
    TAQSIMOTNI korsatish uchun ataylab BARCHA hujjatlarni sanaydi (faqat
    tonnaj/konditsion agregatsiyasi TUGALLANDI bilan cheklanadi)."""
    _hujjat_qosh(db_session, mahsulot_chigit.id, 6000, HujjatHolati.TUGALLANDI, "HLT-SAN-1")
    _hujjat_qosh(db_session, mahsulot_chigit.id, 5000, HujjatHolati.JARAYON, "HLT-SAN-2")
    _hujjat_qosh(db_session, mahsulot_chigit.id, 9000, HujjatHolati.BEKOR_QILINDI, "HLT-SAN-3")

    javob = client.get("/statistika/kunlik", headers=admin_headers)
    natija = javob.json()
    assert natija["mashinalar_soni"] == 3
    assert natija["tugallanganlar_soni"] == 1
    assert natija["bekor_soni"] == 1
